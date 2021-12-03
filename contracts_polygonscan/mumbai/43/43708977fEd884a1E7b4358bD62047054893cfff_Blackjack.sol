// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./utils/VRFConsumerBaseUpgradeable.sol";
import "./utils/IVault.sol";
import "./utils/IGame.sol";
import "./utils/IBlackjackHelper.sol";

contract Blackjack is
    Initializable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    VRFConsumerBaseUpgradeable,
    IGame
{
    enum PlayerState {
        NoPlayer,
        WaitingPlayer,
        NotBusted,
        IsSettled,
        IsBusted,
        HasBlackjack
    }

    enum GameState {
        EndedGame,
        NewGame,
        OnGoingGame
    }

    enum HandState {
        Stand,
        Busted,
        Blackjack
    }

    struct Game {
        uint256 gId;
        address[] players;
        uint128[] bets;
        uint8[] deck;
        GameState state;
        uint8 playerCount;
        uint8 waitingPlayerCount;
        uint8 maxPlayer;
        PlayerState[] playerState;
        bytes32 childHash;
        uint128 minBet;
        uint128 maxBet;
        uint256 startTime;
    }

    mapping(uint8 => Game) public games;
    mapping(uint8 => uint128) reserves;
    mapping(uint256 => uint8[]) nonBustedPlayers;
    mapping(uint256 => uint8[]) dealerHand;
    mapping(address => mapping(uint256 => uint8[])) playerHand;
    mapping(address => mapping(uint256 => uint8[])) playerSplit;
    mapping(address => mapping(uint256 => bool)) isPlayerInGame;
    // mapping(address => mapping(uint256 => bool)) playerInsurance;
    mapping(bytes32 => uint8) requests;
    mapping(uint8 => uint256) results;

    uint8 public constant maxHand = 2;
    uint8 public maxRoom;
    uint128 public blackjackReward;
    uint256 public gId;
    uint256 public waitingTimeBeforeStarted;
    uint256 public extraWaitingTime;

    uint256 internal fee;
    bytes32 internal keyHash;

    bytes32 public constant WORKER_ROLE = keccak256("WORKER_ROLE");
    bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");

    IVault vault;
    IBlackjackHelper helper;

    modifier onlyOnGoingGame(uint8 _rId) {
        require(games[_rId].state == GameState.OnGoingGame, "BJ21");
        _;
    }

    modifier onlyNotBusted(uint8 _rId, uint8 _position) {
        require(
            games[_rId].playerState[_position] == PlayerState.NotBusted,
            "BJ31"
        );
        _;
    }

    modifier onlyRoomInRange(uint8 _rId) {
        require(_rId < maxRoom, "BJ24");
        _;
    }

    modifier checkHash(uint8 _rId, bytes32 _hash) {
        require(keccak256(abi.encode(_hash)) == games[_rId].childHash, "BJ28");
        _;
    }

    event CreateRoom(
        uint256 indexed gId,
        uint8 indexed rId,
        uint8 maxPlayer,
        uint128 minBet,
        uint128 maxBet,
        bytes32 childHash
    );

    event JoinGame(
        uint256 indexed gId,
        uint8 indexed rId,
        address indexed player,
        uint8 position,
        uint128 betAmount,
        uint256 startTime
    );

    event WaitingGame(
        uint8 indexed rId,
        address indexed player,
        uint8 position,
        uint128 betAmount
    );

    event StartGame(
        uint256 indexed gId,
        uint8 indexed rId,
        GameState state,
        bytes32 requestId
    );

    event Randomness(
        uint256 indexed gId,
        uint8 indexed rId,
        bytes32 requestId,
        uint256 randomness
    );

    event Hand(
        uint256 indexed gId,
        uint8 indexed rId,
        address indexed player,
        uint8 position,
        uint8[] cards,
        HandState state
    );

    event PlayerHit(
        uint256 indexed gId,
        uint8 indexed rId,
        address indexed player,
        uint8 position,
        uint8 card,
        bytes32 drawHash
    );

    event DealerHit(
        uint256 indexed gId,
        uint8 indexed rId,
        uint8 card,
        bytes32 drawHash
    );

    event Split(
        uint256 indexed gId,
        uint8 indexed rId,
        address indexed player,
        uint8 position,
        uint8 splitIndex,
        uint8[] hand,
        uint8[] split,
        bytes32 drawHash
    );

    event DoubleDown(
        uint256 indexed gId,
        uint8 indexed rId,
        address indexed player,
        uint8 position,
        uint128 newAmount,
        bytes32 drawHash
    );

    // event Insurance(
    //     uint256 indexed gId,
    //     uint8 indexed rId,
    //     address indexed player,
    //     uint8 position,
    //     uint128 amount
    // );

    function initialize(
        address _vaultAddress,
        address _blackjackHelperAddress,
        uint8 _maxRoom,
        uint256 _waitingTime,
        uint256 _extraWaitingTime,
        bytes32 _keyHash,
        address _vrfCoordinator,
        address _linkToken,
        uint256 _fee
    ) public initializer {
        VRFConsumerBaseUpgradeable.__VRFConsumerBase_init(
            _vrfCoordinator, // VRF Coordinator
            _linkToken //LINK Token
        );
        OwnableUpgradeable.__Ownable_init();
        AccessControlUpgradeable.__AccessControl_init();
        PausableUpgradeable.__Pausable_init();

        _setupRole(VAULT_ROLE, _vaultAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        vault = IVault(_vaultAddress);
        helper = IBlackjackHelper(_blackjackHelperAddress);

        maxRoom = _maxRoom;
        waitingTimeBeforeStarted = _waitingTime;
        extraWaitingTime = _extraWaitingTime;

        keyHash = _keyHash;
        fee = _fee;

        blackjackReward = 250; // default
    }

    function createRoom(
        uint128 _minBet,
        uint128 _maxBet,
        uint8 _maxPlayer,
        uint8 _rId,
        bytes32 _childHash
    ) external onlyRole(WORKER_ROLE) onlyRoomInRange(_rId) {
        Game storage game = games[_rId];

        require(game.state == GameState.EndedGame, "BJ22");

        game.gId = ++gId;

        if (game.waitingPlayerCount > 0) {
            require(game.maxPlayer == _maxPlayer, "BJ32");

            game.startTime = block.timestamp + waitingTimeBeforeStarted;

            for (uint8 pIndex; pIndex < game.maxPlayer * maxHand; pIndex++) {
                if (game.playerState[pIndex] == PlayerState.WaitingPlayer) {
                    game.playerState[pIndex] = PlayerState.NotBusted;
                    isPlayerInGame[game.players[pIndex]][game.gId] = true;

                    uint128 reserve = game.bets[pIndex] * 4;
                    vault.addReserveOperating(reserve);
                    reserves[_rId] += (reserve + game.bets[pIndex]);

                    emit JoinGame(
                        game.gId,
                        _rId,
                        game.players[pIndex],
                        pIndex,
                        game.bets[pIndex],
                        game.startTime
                    );
                } else {
                    game.playerState[pIndex] = PlayerState.NoPlayer;
                    game.players[pIndex] = address(0);
                    game.bets[pIndex] = 0;
                }
            }
            game.playerCount = game.waitingPlayerCount;
            game.waitingPlayerCount = 0;
        } else {
            game.players = new address[](_maxPlayer * maxHand);
            game.bets = new uint128[](_maxPlayer * maxHand);
            game.playerState = new PlayerState[](_maxPlayer * maxHand);
            game.playerCount = 0;
            game.startTime = 0;
        }

        game.state = GameState.NewGame;
        game.maxPlayer = _maxPlayer;
        game.childHash = _childHash;
        game.minBet = _minBet;
        game.maxBet = _maxBet;

        delete game.deck;
        prepareDeck(_rId);

        emit CreateRoom(
            game.gId,
            _rId,
            game.maxPlayer,
            game.minBet,
            game.maxBet,
            game.childHash
        );
    }

    function joinGame(
        uint8 _rId,
        uint8 _position,
        uint128 _betAmount
    ) external whenNotPaused onlyRoomInRange(_rId) {
        Game storage game = games[_rId];

        require(!isPlayerInGame[msg.sender][game.gId], "BJ30");

        require(_betAmount >= game.minBet && _betAmount <= game.maxBet, "BJ27");

        require(_position < game.maxPlayer, "BJ23");

        require(game.playerState[_position] == PlayerState.NoPlayer, "BJ26");

        vault.addGameBalance(msg.sender, _betAmount);

        game.players[_position] = msg.sender;
        game.bets[_position] = _betAmount;

        isPlayerInGame[msg.sender][game.gId] = true;

        if (game.startTime > block.timestamp || game.startTime == 0) {
            uint128 reserve = _betAmount * 4;
            vault.addReserveOperating(reserve);
            reserves[_rId] += (reserve + _betAmount);

            game.playerCount++;
            game.playerState[_position] = PlayerState.NotBusted;

            if (game.playerCount == 1) {
                game.startTime = block.timestamp + waitingTimeBeforeStarted;
            } else if (game.playerCount == game.maxPlayer) {
                game.startTime = block.timestamp;
            } else {
                game.startTime += extraWaitingTime;
            }

            emit JoinGame(
                game.gId,
                _rId,
                msg.sender,
                _position,
                _betAmount,
                game.startTime
            );
        } else {
            game.playerState[_position] = PlayerState.WaitingPlayer;
            game.waitingPlayerCount++;

            emit WaitingGame(_rId, msg.sender, _position, _betAmount);
        }
    }

    function startGame(uint8 _rId) external {
        Game storage game = games[_rId];

        require(game.state == GameState.NewGame, "BJ20");

        require(
            game.startTime <= block.timestamp && game.startTime != 0,
            "BJ25"
        );

        bytes32 requestId = getRandomNumber();
        requests[requestId] = _rId;

        game.state = GameState.OnGoingGame;

        emit StartGame(game.gId, _rId, game.state, requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        uint8 rId = requests[_requestId];
        results[rId] = _randomness;

        Game storage game = games[rId];

        emit Randomness(game.gId, rId, _requestId, _randomness);

        bytes32 randomness = bytes32(_randomness);
        for (uint8 pIndex; pIndex < game.maxPlayer; pIndex++) {
            if (game.playerState[pIndex] == PlayerState.NotBusted) {
                drawPlayerCard(rId, pIndex, randomness);
                drawPlayerCard(rId, pIndex, randomness);
            }
        }
        drawDealerCard(rId, randomness);
    }

    function stand(uint8 _rId, uint8 _position)
        external
        onlyRole(WORKER_ROLE)
        onlyOnGoingGame(_rId)
        onlyNotBusted(_rId, _position)
    {
        Game storage game = games[_rId];

        nonBustedPlayers[game.gId].push(_position);
        game.playerState[_position] = PlayerState.IsSettled;

        address player = game.players[_position];

        emit Hand(
            game.gId,
            _rId,
            player,
            _position,
            getHand(_rId, _position, player),
            HandState.Stand
        );
    }

    // function insurance(uint8 _rId, uint8 _position)
    //     external
    //     onlyRole(WORKER_ROLE)
    //     onlyOnGoingGame(_rId)
    //     onlyNotBusted(_rId, _position)
    // {
    //     Game storage game = games[_rId];

    //     require(
    //         getDealerHand(game.gId).length == 1 &&
    //             helper.getHandPower(getDealerHand(game.gId)) == 11,
    //         "BJ38"
    //     );

    //     address player = game.players[_position];

    //     require(!playerInsurance[player][game.gId], "BJ33");

    //     uint128 insuranceAmount = game.bets[_position] / 2;
    //     vault.addGameBalance(player, insuranceAmount);
    //     reserves[_rId] += insuranceAmount;
    //     playerInsurance[player][game.gId] = true;

    //     emit Insurance(game.gId, _rId, player, _position, insuranceAmount);
    // }

    function doubleDown(
        uint8 _rId,
        uint8 _position,
        bytes32 _parentHash
    )
        external
        onlyRole(WORKER_ROLE)
        onlyOnGoingGame(_rId)
        onlyNotBusted(_rId, _position)
        checkHash(_rId, _parentHash)
    {
        address player = games[_rId].players[_position];

        require(
            helper.getHandPower(getHand(_rId, _position, player)) <= 11,
            "BJ36"
        );

        _doubleDown(_rId, _position, _parentHash);
    }

    function _doubleDown(
        uint8 _rId,
        uint8 _position,
        bytes32 _parentHash
    ) private {
        Game storage game = games[_rId];
        address player = game.players[_position];

        uint128 bet = game.bets[_position];

        vault.addGameBalance(player, bet);
        reserves[_rId] += bet;

        uint128 newBetAmount = 2 * bet;
        game.bets[_position] = newBetAmount;

        emit DoubleDown(
            game.gId,
            _rId,
            player,
            _position,
            newBetAmount,
            _parentHash
        );

        playerHit(_rId, _position, _parentHash);

        if (game.playerState[_position] == PlayerState.NotBusted) {
            game.playerState[_position] = PlayerState.IsSettled;
            nonBustedPlayers[game.gId].push(_position);

            emit Hand(
                game.gId,
                _rId,
                player,
                _position,
                playerHand[player][game.gId],
                HandState.Stand
            );
        }
    }

    function split(
        uint8 _rId,
        uint8 _position,
        bytes32 _parentHash
    )
        external
        onlyRole(WORKER_ROLE)
        onlyOnGoingGame(_rId)
        onlyNotBusted(_rId, _position)
        checkHash(_rId, _parentHash)
    {
        address player = games[_rId].players[_position];
        uint256 gameId = games[_rId].gId;
        uint8[] storage mainHand = playerHand[player][gameId];

        require(playerSplit[player][gameId].length == 0, "BJ34");

        require(
            helper.getCardPower(mainHand[0]) ==
                helper.getCardPower(mainHand[1]) &&
                mainHand.length == 2,
            "BJ37"
        );

        _split(_rId, _position, _parentHash);
    }

    function _split(
        uint8 _rId,
        uint8 _position,
        bytes32 _parentHash
    ) private {
        Game storage game = games[_rId];
        address player = game.players[_position];

        uint8[] storage mainHand = playerHand[player][game.gId];
        uint8[] storage splitHand = playerSplit[player][game.gId];

        uint128 bet = game.bets[_position];

        vault.addGameBalance(player, bet);
        reserves[_rId] += bet;

        uint8 split_position = _position + game.maxPlayer;
        game.players[split_position] = player;
        game.bets[split_position] = bet;
        game.playerState[split_position] = PlayerState.NotBusted;

        splitHand.push(mainHand[1]);
        mainHand.pop();

        emit Split(
            game.gId,
            _rId,
            player,
            _position,
            split_position,
            mainHand,
            splitHand,
            _parentHash
        );

        drawPlayerCard(
            _rId,
            _position,
            keccak256(abi.encode(_parentHash, results[_rId]))
        );

        drawPlayerCard(
            _rId,
            split_position,
            keccak256(abi.encode(_parentHash, results[_rId]))
        );

        games[_rId].childHash = _parentHash;
    }

    function dealerResolve(uint8 _rId, bytes32 _parentHash)
        external
        onlyRole(WORKER_ROLE)
        onlyOnGoingGame(_rId)
        checkHash(_rId, _parentHash)
    {
        Game storage game = games[_rId];
        for (uint8 pIndex; pIndex < game.maxPlayer; pIndex++) {
            require(game.playerState[pIndex] != PlayerState.NotBusted, "BJ35");
        }

        uint8[] storage hand = dealerHand[game.gId];

        game.childHash = _parentHash;

        bytes32 newHash = keccak256(abi.encode(_parentHash, results[_rId]));

        drawDealerCard(_rId, newHash);

        uint8[] memory leftPlayers = nonBustedPlayers[game.gId];
        if (leftPlayers.length > 0) {
            uint256 dealersPower = helper.getHandPower(hand);
            if (dealersPower == 21 && hand.length == 2) {
                payoutAgainstBlackjack(_rId, leftPlayers);
            } else {
                while (dealersPower <= 16) {
                    drawDealerCard(_rId, newHash);
                    dealersPower = helper.getHandPower(hand);
                }
                payoutAgainstDealersHand(_rId, leftPlayers, dealersPower);
            }
        }
        game.state = GameState.EndedGame;
        vault.subReserveOperating(reserves[_rId]);
        reserves[_rId] = 0;
    }

    function playerHit(
        uint8 _rId,
        uint8 _position,
        bytes32 _parentHash
    )
        public
        onlyRole(WORKER_ROLE)
        onlyOnGoingGame(_rId)
        onlyNotBusted(_rId, _position)
        checkHash(_rId, _parentHash)
    {
        drawPlayerCard(
            _rId,
            _position,
            keccak256(abi.encode(_parentHash, results[_rId]))
        );

        games[_rId].childHash = _parentHash;
    }

    function drawPlayerCard(
        uint8 _rId,
        uint8 _position,
        bytes32 _hash
    ) internal {
        Game storage game = games[_rId];
        address player = game.players[_position];
        uint8 card = drawCard(_rId, _hash);
        uint8[] storage cards = hasSplit(_rId, _position)
            ? playerSplit[player][game.gId]
            : playerHand[player][game.gId];

        cards.push(card);

        emit PlayerHit(game.gId, _rId, player, _position, card, _hash);

        uint256 playerPower = helper.getHandPower(cards);
        if (playerPower > 21) {
            game.playerState[_position] = PlayerState.IsBusted;

            emit Hand(
                game.gId,
                _rId,
                player,
                _position,
                cards,
                HandState.Busted
            );
        } else if (playerPower == 21) {
            if (cards.length == 2) {
                game.playerState[_position] = PlayerState.HasBlackjack;

                emit Hand(
                    game.gId,
                    _rId,
                    player,
                    _position,
                    cards,
                    HandState.Blackjack
                );
            } else {
                game.playerState[_position] = PlayerState.IsSettled;

                emit Hand(
                    game.gId,
                    _rId,
                    player,
                    _position,
                    cards,
                    HandState.Stand
                );
            }
            nonBustedPlayers[game.gId].push(_position);
        }
    }

    function drawDealerCard(uint8 _rId, bytes32 _hash) internal {
        uint8 card = drawCard(_rId, _hash);
        dealerHand[games[_rId].gId].push(card);

        emit DealerHit(games[_rId].gId, _rId, card, _hash);
    }

    function drawCard(uint8 _rId, bytes32 _hash) internal returns (uint8 card) {
        uint8[] storage deck = games[_rId].deck;
        uint256 _card = uint256(keccak256(abi.encode(_hash, deck.length))) %
            deck.length;
        card = deck[_card];
        deck[_card] = deck[deck.length - 1];
        deck.pop();
    }

    function getHand(
        uint8 _rId,
        uint8 _position,
        address _player
    ) public view returns (uint8[] memory cards) {
        uint256 gameId = games[_rId].gId;
        cards = hasSplit(_rId, _position)
            ? playerSplit[_player][gameId]
            : playerHand[_player][gameId];
    }

    function hasSplit(uint8 _rId, uint8 _position)
        internal
        view
        returns (bool)
    {
        return _position >= games[_rId].maxPlayer;
    }

    function getDealerHand(uint256 _gId)
        public
        view
        returns (uint8[] memory cards)
    {
        return dealerHand[_gId];
    }

    function payoutAgainstBlackjack(uint8 _rId, uint8[] memory _leftPlayers)
        private
    {
        Game storage game = games[_rId];
        for (uint8 i; i < _leftPlayers.length; i++) {
            uint8 position = _leftPlayers[i];
            address player = game.players[position];
            uint128 bet = game.bets[position];

            // payout if player also has a blackjack
            if (game.playerState[i] == PlayerState.HasBlackjack) {
                _payout(_rId, player, bet);
            }
            // payout if player purchased insurance
            // if (playerInsurance[player][game.gId] == true) {
            //     _payout(_rId, player, bet);
            // }
        }
    }

    function payoutAgainstDealersHand(
        uint8 _rId,
        uint8[] memory _leftPlayers,
        uint256 _dealersPower
    ) private {
        Game storage game = games[_rId];
        for (uint8 i; i < _leftPlayers.length; i++) {
            uint8 position = _leftPlayers[i];
            address player = game.players[position];
            uint128 bet = game.bets[position];
            uint256 playerPower = helper.getHandPower(
                getHand(_rId, position, player)
            );

            uint128 payout;
            if (game.playerState[position] == PlayerState.HasBlackjack) {
                payout = (bet * blackjackReward) / 100;
            } else if (playerPower > _dealersPower || _dealersPower > 21) {
                payout = (bet * 200) / 100;
            } else if (playerPower == _dealersPower) {
                payout = bet;
            }

            if (payout > 0) {
                _payout(_rId, player, payout);
            }
        }
    }

    function _payout(
        uint8 _rId,
        address _player,
        uint128 _amount
    ) private {
        vault.subGameBalance(_player, _amount, 0);
        reserves[_rId] -= _amount;
    }

    function getRandomNumber() internal returns (bytes32) {
        require(LINK.balanceOf(address(this)) > fee, "BJ00");
        return requestRandomness(keyHash, fee);
    }

    function prepareDeck(uint8 _rId) internal {
        uint8[] storage deck = games[_rId].deck;
        for (uint8 i; i < 52; i++) {
            deck.push(i);
        }
    }

    function setBlackjackReward(uint128 _multiplier)
        external
        whenPaused
        onlyOwner
    {
        require(_multiplier > 0, "");
        blackjackReward = _multiplier;
    }

    function getPlayer(uint8 _rId)
        external
        view
        returns (address[] memory, PlayerState[] memory)
    {
        return (games[_rId].players, games[_rId].playerState);
    }

    function setMaxRoom(uint8 _maxRoom) external whenPaused onlyOwner {
        require(_maxRoom != 0, "");
        maxRoom = _maxRoom;
    }

    function resetRoom(uint8 _rId) external onlyOwner {
        // for testing
        games[_rId].state = GameState.EndedGame;
    }

    function pause() external override onlyRole(VAULT_ROLE) {
        _pause();
    }

    function unpause() external override onlyRole(VAULT_ROLE) {
        _unpause();
    }

    function isPlayerStillPlaying() external pure override returns (bool) {
        return false; // no need to check before pause game
    }

    function withdrawLink() external onlyOwner {
        uint256 amount = LINK.balanceOf(address(this));
        require(amount > 0, "BJ05");
        LINK.transfer(owner(), amount);
    }

    receive() external payable {
        revert();
    }

    fallback() external payable {
        revert();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/VRFRequestIDBase.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract VRFConsumerBaseUpgradeable is
    Initializable,
    VRFRequestIDBase
{
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        virtual;

    uint256 private constant USER_SEED_PLACEHOLDER = 0;

    function requestRandomness(bytes32 _keyHash, uint256 _fee)
        internal
        returns (bytes32 requestId)
    {
        LINK.transferAndCall(
            vrfCoordinator,
            _fee,
            abi.encode(_keyHash, USER_SEED_PLACEHOLDER)
        );
        uint256 vRFSeed = makeVRFInputSeed(
            _keyHash,
            USER_SEED_PLACEHOLDER,
            address(this),
            nonces[_keyHash]
        );
        nonces[_keyHash] = nonces[_keyHash] + 1;
        return makeRequestId(_keyHash, vRFSeed);
    }

    LinkTokenInterface internal LINK;
    address private vrfCoordinator;

    mapping(bytes32 => uint256) /* keyHash */ /* nonce */
        private nonces;

    function __VRFConsumerBase_init(address _vrfCoordinator, address _link)
        internal
        initializer
    {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }

    function rawFulfillRandomness(bytes32 requestId, uint256 randomness)
        external
    {
        require(
            msg.sender == vrfCoordinator,
            "Only VRFCoordinator can fulfill"
        );
        fulfillRandomness(requestId, randomness);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IVault {
    function addGameBalance(address _player, uint128 _amount) external;

    function subGameBalance(
        address _player,
        uint128 _balance,
        uint128 _fee
    ) external;

    function addReserveOperating(uint128 _amount) external;

    function subReserveOperating(uint128 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IGame {
    function isPlayerStillPlaying() external returns (bool);

    function pause() external;

    function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IBlackjackHelper {
    function getCardPower(uint8 _card) external pure returns (uint8 cardPower);

    function getHandPower(uint8[] memory _cards)
        external
        pure
        returns (uint8 powerMax);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}