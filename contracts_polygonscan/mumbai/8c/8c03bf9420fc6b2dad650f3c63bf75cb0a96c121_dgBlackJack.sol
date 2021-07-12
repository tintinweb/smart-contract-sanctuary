/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

// SPDX-License-Identifier: -- 🎲 --

pragma solidity ^0.7.0;

interface TreasuryInstance {

    function getTokenAddress(
        uint8 _tokenIndex
    ) external view returns (address);

    function tokenInboundTransfer(
        uint8 _tokenIndex,
        address _from,
        uint256 _amount
    )  external returns (bool);

    function tokenOutboundTransfer(
        uint8 _tokenIndex,
        address _to,
        uint256 _amount
    ) external returns (bool);

    function checkAllocatedTokens(
        uint8 _tokenIndex
    ) external view returns (uint256);

    function checkApproval(
        address _userAddress,
        uint8 _tokenIndex
    ) external view returns (uint256 approved);

    function getMaximumBet(
        uint8 _tokenIndex
    ) external view returns (uint128);

    function consumeHash(
        bytes32 _localhash
    ) external returns (bool);
}

contract AccessController {

    address public ceoAddress;
    address public workerAddress;

    bool public paused = false;

    // mapping (address => enumRoles) accessRoles; // multiple operators idea

    event CEOSet(address newCEO);
    event WorkerSet(address newWorker);

    event Paused();
    event Unpaused();

    constructor() {
        ceoAddress = msg.sender;
        workerAddress = msg.sender;
        emit CEOSet(ceoAddress);
        emit WorkerSet(workerAddress);
    }

    modifier onlyCEO() {
        require(
            msg.sender == ceoAddress,
            'AccessControl: CEO access denied'
        );
        _;
    }

    modifier onlyWorker() {
        require(
            msg.sender == workerAddress,
            'AccessControl: worker access denied'
        );
        _;
    }

    modifier whenNotPaused() {
        require(
            !paused,
            'AccessControl: currently paused'
        );
        _;
    }

    modifier whenPaused {
        require(
            paused,
            'AccessControl: currenlty not paused'
        );
        _;
    }

    function setCEO(address _newCEO) public onlyCEO {
        require(
            _newCEO != address(0x0),
            'AccessControl: invalid CEO address'
        );
        ceoAddress = _newCEO;
        emit CEOSet(ceoAddress);
    }

    function setWorker(address _newWorker) external {
        require(
            _newWorker != address(0x0),
            'AccessControl: invalid worker address'
        );
        require(
            msg.sender == ceoAddress || msg.sender == workerAddress,
            'AccessControl: invalid worker address'
        );
        workerAddress = _newWorker;
        emit WorkerSet(workerAddress);
    }

    function pause() external onlyWorker whenNotPaused {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyCEO whenPaused {
        paused = false;
        emit Unpaused();
    }
}

contract MultiHashChain {

    mapping(
        uint256 => mapping(
            uint256 => mapping(
                uint256 => bytes32
            )
        )
    ) public tail;

    function _setMultiTail(
        uint256 _serverId,
        uint256 _landId,
        uint256 _tableId,
        bytes32 _tail
    ) internal {
        tail[_serverId][_landId][_tableId] = _tail;
    }

    function _consumeMulti(
        uint256 _serverId,
        uint256 _landId,
        uint256 _tableId,
        bytes32 _parent
    ) internal {
        require(
            keccak256(
                abi.encodePacked(_parent)
            ) == tail[_serverId][_landId][_tableId],
            'hash-chain: wrong parent'
        );
        tail[_serverId][_landId][_tableId] = _parent;
    }
}

interface PointerInstance {

    function addPoints(
        address _player,
        uint256 _points,
        address _token,
        uint256 _numPlayers,
        uint256 _wearableBonus
    ) external returns (
        uint256 newPoints,
        uint256 multiplierA,
        uint256 multiplierB
    );

    function addPoints(
        address _player,
        uint256 _points,
        address _token,
        uint256 _numPlayers
    ) external returns (
        uint256 newPoints,
        uint256 multiplierA,
        uint256 multiplierB
    );

    function addPoints(
        address _player,
        uint256 _points,
        address _token
    ) external returns (
        uint256 newPoints,
        uint256 multiplierA,
        uint256 multiplierB
    );
}

contract BlackJackHelper {

    function getCardsRawData(uint8 _card) public pure returns (uint8, uint8) {
        return (_card / 13, _card % 13);
    }

    function getCardsDetails(uint8 _card) public pure returns (string memory, string memory) {

        string[4] memory Suits = ["C", "D", "H", "S"];
        string[13] memory Vals = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K"];

        (uint8 _suit, uint8 _val) = getCardsRawData(_card);
        return (Suits[_suit], Vals[_val]);
    }

    function getRandomCardIndex(bytes32 _localhash, uint256 _length) internal pure returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    _localhash, _length
                )
            )
        ) % _length;
    }

    function getCardsPower(uint8 _card) public pure returns (uint8 power) {
        bytes13 cardsPower = "\x0B\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0A\x0A\x0A";
        return uint8(cardsPower[_card % 13]);
    }

    function getHandsPower(uint8[] memory _cards) public pure returns (uint8 powerMax) {

        uint8 aces;
        uint8 power;

        for (uint8 i = 0; i < _cards.length; i++) {
            power = getCardsPower(_cards[i]);
            powerMax += power;
            if (power == 11) {
                aces += 1;
            }
        }
        if (powerMax > 21) {
            for (uint8 i = 0; i < aces; i++) {
                powerMax -= 10;
                if (powerMax <= 21) {
                    break;
                }
            }
        }
        return powerMax;
    }

    function isBlackJack(uint8[] memory _cards) public pure returns (bool) {
        return getHandsPower(_cards) == 21 && _cards.length == 2;
    }

    function canSplitCards(uint8[] memory _cards) public pure returns (bool) {
        return getCardsPower(_cards[0]) == getCardsPower(_cards[1]) && _cards.length == 2;
    }

    function verifyHiddenCard(bytes32 _hashChild, bytes32 _hashParent) public pure returns (bool) {
        return keccak256(
            abi.encodePacked(_hashParent)
        ) == _hashChild ? true : false;
    }
}

contract dgBlackJack is AccessController, BlackJackHelper, MultiHashChain {

    enum inGameState { notJoined, Playing, EndedPlay }
    enum GameState { NewGame, OnGoingGame, EndedGame }
    enum PlayerState { notBusted, hasSplit, isSplit, isSettled, isBusted, hasBlackJack }

    struct Game {
        address[] players;
        uint128[] bets;
        uint8[] tokens;
        uint8[] deck;
        uint8 playersCount;
        PlayerState[] pState;
        GameState state;
    }

    struct HiddenCard {
        bytes32 hashChild;
        bytes32 hashParent;
    }

    mapping(bytes16 => Game) public Games;
    mapping(bytes16 => HiddenCard) public DealersHidden;
    mapping(bytes16 => uint8[]) public DealersVisible;
    mapping(bytes16 => uint8[]) public NonBustedPlayers;
    mapping(address => mapping(bytes16 => uint8[])) PlayersHand;
    mapping(address => mapping(bytes16 => uint8[])) public PlayerSplit;
    mapping(address => mapping(bytes16 => bool)) public PlayersInsurance;
    mapping(address => mapping(bytes16 => inGameState)) public inGame;

    modifier onlyOnGoingGame(bytes16 _gameId) {
        require(
            Games[_gameId].state == GameState.OnGoingGame
        );
        _;
    }

    modifier ifPlayerInGame(bytes16 _gameId, address _player, uint8 _pIndex) {
        require(
            Games[_gameId].players[_pIndex] == _player &&
            inGame[_player][_gameId] == inGameState.Playing
        );
        _;
    }

    modifier onlyNonBustedOrSplit(bytes16 _gameId, uint8 _pIndex) {
        require(
            Games[_gameId].pState[_pIndex] == PlayerState.notBusted ||
            Games[_gameId].pState[_pIndex] == PlayerState.hasSplit ||
            Games[_gameId].pState[_pIndex] == PlayerState.isSplit
        );
        _;
    }

    modifier onlyNonBusted(bytes16 _gameId, uint8 _pIndex) {
        require(
            Games[_gameId].pState[_pIndex] == PlayerState.notBusted
        );
        _;
    }

    modifier whenTableSettled(bytes16 _gameId) {
        address[] memory _players = Games[_gameId].players;
        for (uint256 i = 0; i < _players.length; i++) {
            require(
                uint8(Games[_gameId].pState[i]) >= uint8(PlayerState.isSettled)
            );
        }
        _;
    }

    TreasuryInstance public treasury;

    uint8 maxPlayers;
    uint256 nonce;

    event BetPlaced(
        uint8 tokenIndex,
        address player,
        uint256 betAmount
    );

    event GameInitializing(
        bytes16 gameId
    );

    event GameInitialized(
        bytes16 gameId,
        uint128[] bets,
        uint8[] tokens,
        uint256 landId,
        uint256 tableId
    );

    event PlayerCardDrawn(
        bytes16 gameId,
        address player,
        uint8 playerIndex,
        uint8 cardsIndex,
        string cardSuit,
        string cardVal
    );

    event DealersCardDrawn(
        bytes16 gameId,
        uint8 cardsIndex,
        string cardSuit,
        string cardVal
    );

    event DealersCardRevealed(
        bytes16 gameId,
        uint8 cardsIndex,
        string cardSuit,
        string cardVal
    );

    event splitHand(
        bytes16 gameId,
        address player,
        uint256 newIndex,
        uint8[] hand,
        uint8[] split
    );

    event InsurancePurchased(
        bytes16 gameId,
        address player,
        uint8 playerIndex
    );

    event InsurancePayout(
        address player,
        uint256 amount
    );

    event PlayersPayout(
        address player,
        uint256 amount
    );

    event FinishedGame(
        bytes16 gameId
    );

    event DoubleDown(
        uint256 powerAfter
    );

    event Busted(
        bool
    );

    PointerInstance immutable public pointerContract;

    constructor(
        address _treasuryAddress,
        uint8 _maxPlayers,
        address _pointerAddress

    ) {
        require(_maxPlayers < 10);
        treasury = TreasuryInstance(_treasuryAddress);
        maxPlayers = _maxPlayers;
        pointerContract = PointerInstance(_pointerAddress);
    }

    function setMultiTail(
        uint256 _serverId,
        uint256 _landId,
        uint256 _tableId,
        bytes32 _localhashB
    ) external onlyCEO {
        _setMultiTail(
            _serverId,
            _landId,
            _tableId,
            _localhashB
        );
    }

    function _addPoints(
        address _player,
        uint256 _points,
        address _token,
        uint256 _numPlayers,
        uint256 _wearableBonus
    )
        private
    {
        pointerContract.addPoints(
            _player,
            _points,
            _token,
            _numPlayers,
            _wearableBonus
        );
    }

    function checkPlayer(bytes16 _gameId, address _player) private {
        require(
            inGame[_player][_gameId] == inGameState.notJoined ||
            inGame[_player][_gameId] == inGameState.EndedPlay
        );
        inGame[_player][_gameId] = inGameState.Playing;
    }

    function takePlayersBet(bytes16 _gameId, uint8 _playerIndex) private {

        uint8 tokenIndex = Games[_gameId].tokens[_playerIndex];
        address player = Games[_gameId].players[_playerIndex];
        uint256 betAmount = Games[_gameId].bets[_playerIndex];

        require(
            treasury.getMaximumBet(tokenIndex) >= betAmount
        );

        treasury.tokenInboundTransfer(
            tokenIndex, player, betAmount
        );

        emit BetPlaced(
            tokenIndex, player, betAmount
        );
    }

    function initializePlayer(bytes16 _gameId, uint8 _pIndex) private {

        address[] memory _players = Games[_gameId].players;

        checkPlayer(
            _gameId, _players[_pIndex]
        );

        Games[_gameId].pState[_pIndex] = PlayerState.notBusted;
    }

    function checkForBlackJack(bytes16 _gameId, uint8 _playerIndex) private {

        address[] memory _players = Games[_gameId].players;

        if (
            isBlackJack(
                    getHand(_gameId, _players[_playerIndex], _playerIndex)
            )) {
            NonBustedPlayers[_gameId].push(_playerIndex);
            Games[_gameId].pState[_playerIndex] = PlayerState.hasBlackJack;
        }
    }

    function drawDealersCard(
        bytes16 _gameId,
        bytes32 _localhashA
    )
        private
    {
        uint8 _card = drawCard(_gameId, _localhashA);

        (
            string memory _cardsSuit,
            string memory _cardsVal
        ) = getCardsDetails(_card);

        DealersVisible[_gameId].push(_card);

        emit DealersCardDrawn(
            _gameId,
            _card,
            _cardsSuit,
            _cardsVal
        );
    }

    function drawPlayersCard(
        bytes16 _gameId,
        uint8 _pIndex,
        bytes32 _localhashA
    )
        private
    {
        address _player = Games[_gameId].players[_pIndex];

        uint8 _card = drawCard(_gameId, _localhashA);

        (
            string memory _cardsSuit,
            string memory _cardsVal
        ) = getCardsDetails(_card);

        uint8[] storage playersHand = hasSplit(_gameId, _pIndex)
            ? PlayerSplit[_player][_gameId]
            : PlayersHand[_player][_gameId];

        playersHand.push(_card);

        emit PlayerCardDrawn(
            _gameId,
            _player,
            _pIndex,
            _card,
            _cardsSuit,
            _cardsVal
        );
    }

    function initializeGame(
        address[] calldata _players,
        uint128[] calldata _bets,
        uint8[] calldata _tokens,
        uint256 _serverId,
        uint256 _landId,
        uint256 _tableId,
        bytes32 _localhashA,
        bytes32 _localhashB
    )
        external
        whenNotPaused
        onlyWorker
        returns (bytes16 gameId)
    {
        require(
            _players.length <= maxPlayers &&
            _bets.length == _tokens.length &&
            _tokens.length == _players.length
        );

        /* _consumeMulti(
            _serverId,
            _landId,
            _tableId,
            _localhashB
        ); */

        // treasury.consumeHash(_localhashA);

        gameId = getGameId(_serverId, _landId, _tableId, _players, nonce);
        nonce = nonce + 1;

        require(
            Games[gameId].state == GameState.NewGame ||
            Games[gameId].state == GameState.EndedGame
        );

        // starting to initialize game
        emit GameInitializing(gameId);

        uint8[] storage _deck = prepareDeck(gameId);

        Game memory _game = Game(
            _players,
            _bets,
            _tokens,
            _deck,
            uint8(_players.length),
            new PlayerState[](_players.length),
            GameState.OnGoingGame
        );

        Games[gameId] = _game;

        uint8 pIndex; // playersIndex

        // first card drawn to each player + take bets
        for (pIndex = 0; pIndex < _players.length; pIndex++) {

            initializePlayer(
                gameId, pIndex
            );

            takePlayersBet(
                gameId, pIndex
            );

            drawPlayersCard(
                gameId, pIndex, _localhashA
            );
        }

        // dealers first card (visible)
        drawDealersCard(
            gameId, _localhashA
        );

        delete NonBustedPlayers[gameId];

        // players second cards (visible)
        for (pIndex = 0; pIndex < _players.length; pIndex++) {

            drawPlayersCard(
                gameId, pIndex, _localhashA
            );

            checkForBlackJack(
                gameId, pIndex
            );
        }

        delete pIndex;

        DealersHidden[gameId] =
            HiddenCard({
                hashChild: _localhashB,
                hashParent: 0x0
            });

        emit GameInitialized(
            gameId,
            _bets,
            _tokens,
            _landId,
            _tableId
        );
    }

    function manualPayout(
        bytes16 _gameId,
        uint256 _serverId,
        uint256 _landId,
        uint256 _tableId,
        uint128[] calldata _payoutAmounts,
        uint128[] calldata _refundAmounts,
        bytes32[] calldata _localHashes,
        uint128[] calldata _wearableBonus
    )
        external
        onlyOnGoingGame(_gameId)
        whenNotPaused
        onlyWorker
    {

        _consumeHashes(
            _serverId,
            _landId,
            _tableId,
            _localHashes
        );

        _payout(
            _gameId,
            _payoutAmounts,
            _refundAmounts,
            _wearableBonus
        );

        emit FinishedGame(
            _gameId
            // _localhashB
        );
    }

    function _payout(
        bytes16 _gameId,
        uint128[] calldata _payoutAmounts,
        uint128[] calldata _refundAmounts,
        uint128[] calldata _wearableBonus
    ) internal {
        Games[_gameId].state = GameState.EndedGame;
        for (uint8 i = 0; i < _payoutAmounts.length; i++) {
            payoutAmount(
                Games[_gameId].tokens[i],
                Games[_gameId].players[i],
                _payoutAmounts[i] + _refundAmounts[i]
            );

            _smartPoints(_gameId, i, _refundAmounts[i], _wearableBonus[i]);
        }
    }

    function _consumeHashes(
        uint256 _serverId,
        uint256 _landId,
        uint256 _tableId,
        bytes32[] calldata _localHashes
    ) internal {
        for (uint256 i = 0; i < _localHashes.length; i++) {
            _consumeMulti(
                _serverId,
                _landId,
                _tableId,
                _localHashes[i]
            );
        }
    }

    function _smartPoints(
        bytes16 _gameId,
        uint8 _pIndex,
        uint128 _refundAmount,
        uint128 _wearableBonus
    ) internal {

        require(Games[_gameId].bets[_pIndex] >= _refundAmount);

        _addPoints(
            Games[_gameId].players[_pIndex],
            Games[_gameId].bets[_pIndex] - _refundAmount,
            treasury.getTokenAddress(Games[_gameId].tokens[_pIndex]),
            Games[_gameId].players.length,
            _wearableBonus
        );
    }

    function prepareDeck(
        bytes16 _gameId
    )
        internal
        returns (uint8[] storage _deck)
    {
        _deck = Games[_gameId].deck;
        for (uint8 i = 0; i < 52; i++) {
            _deck.push(i);
        }
    }

    function drawCard(
        bytes16 _gameId,
        bytes32 _localhashA
    ) internal returns (uint8) {
        uint8[] storage _deck = Games[_gameId].deck;
        uint256 _card = getRandomCardIndex(
            _localhashA, _deck.length
        );
        uint8 card = _deck[_card];
        _deck[_card] = _deck[_deck.length - 1];
        _deck.pop();
        return card;
    }

    function hitMove(
        bytes16 _gameId,
        address _player,
        uint8 _pIndex,
        bytes32 _localhashA
    )
        external
        onlyWorker
        onlyOnGoingGame(_gameId)
        onlyNonBustedOrSplit(_gameId, _pIndex)
        ifPlayerInGame(_gameId, _player, _pIndex)
    {
        treasury.consumeHash(_localhashA);

        drawPlayersCard(
           _gameId, _pIndex, _localhashA
        );

        uint256 playersPower = getHandsPower(
            getHand(_gameId, _player, _pIndex)
        );

        if (playersPower > 21) {
            Games[_gameId].pState[_pIndex] = PlayerState.isBusted;
        }

        if (playersPower == 21) {
            NonBustedPlayers[_gameId].push(_pIndex);
            Games[_gameId].pState[_pIndex] = PlayerState.isSettled;
        }
    }

    function stayMove(
        bytes16 _gameId,
        address _player,
        uint8 _pIndex
    )
        external
        onlyWorker
        onlyOnGoingGame(_gameId)
        onlyNonBustedOrSplit(_gameId, _pIndex)
        ifPlayerInGame(_gameId, _player, _pIndex)
    {
        NonBustedPlayers[_gameId].push(_pIndex);
        Games[_gameId].pState[_pIndex] = PlayerState.isSettled;
    }

    function revealDealersCard(
        bytes16 _gameId,
        uint256 _serverId,
        uint256 _landId,
        uint256 _tableId,
        bytes32 _localhashB
    )
        internal
    {
        uint8 revealed = drawCard(_gameId, _localhashB);

        _consumeMulti(
            _serverId,
            _landId,
            _tableId,
            _localhashB
        );

        (
            string memory _cardsSuit,
            string memory _cardsVal
        ) = getCardsDetails(revealed);

        DealersVisible[_gameId].push(revealed);

        emit DealersCardRevealed(
            _gameId,
            revealed,
            _cardsSuit,
            _cardsVal
        );
    }

    function dealersMove(
        bytes16 _gameId,
        uint256 _serverId,
        uint256 _landId,
        uint256 _tableId,
        bytes32 _localhashA,
        bytes32 _localhashB
    )
        external
        onlyWorker
        onlyOnGoingGame(_gameId)
        whenTableSettled(_gameId)
    {
        require(
            DealersHidden[_gameId].hashParent == 0x0
        );

        DealersHidden[_gameId].hashParent = _localhashB;

        require(
            verifyHiddenCard(
                DealersHidden[_gameId].hashChild,
                DealersHidden[_gameId].hashParent
            ) == true
        );

        treasury.consumeHash(_localhashA);

        revealDealersCard(
            _gameId,
            _serverId,
            _landId,
            _tableId,
            _localhashB
        );

        uint8[] memory _leftPlayers = getNotBustedPlayers(_gameId);

        // check if any player left in the game
        if (_leftPlayers.length > 0) {

            // check if dealer has a blackjack - proceed to payout
            if (isBlackJack(DealersVisible[_gameId])) {

                $payoutAgainstBlackJack(_gameId, _leftPlayers);

            // check if dealer needs more cards
            } else {

                uint256 dealersPower = getHandsPower(
                    DealersVisible[_gameId]
                );

                uint8 _card;

                // draw cards for dealer with _localhashA
                while (dealersPower <= 16) {

                    _card = drawCard(_gameId, _localhashA);

                    (
                        string memory _cardsSuit,
                        string memory _cardsVal
                    ) = getCardsDetails(_card);

                    dealersPower = _dealerAddVisible(
                        _gameId,
                        _card,
                        _cardsSuit,
                        _cardsVal
                    );

                }

                delete _card;

                // calculate any winnings and payout
                $payoutAgainstDealersHand(_gameId, _leftPlayers, dealersPower);
            }
        }

        // mark all players finishing the game
        address[] memory _players = Games[_gameId].players;
        for (uint256 i = 0; i < _players.length; i++) {
            inGame[_players[i]][_gameId] = inGameState.EndedPlay;
        }

        // set game status to ended
        Games[_gameId].state = GameState.EndedGame;

        emit FinishedGame(
            _gameId
            // _localhashB
        );
    }

    function _dealerAddVisible(
        bytes16 _gameId,
        uint8 _card,
        string memory _cardsSuit,
        string memory _cardsVal
    ) internal returns (uint256) {

        DealersVisible[_gameId].push(_card);

        emit DealersCardDrawn(
            _gameId,
            _card,
            _cardsSuit,
            _cardsVal
        );

        return getHandsPower(
            DealersVisible[_gameId]
        );
    }

    function $payoutAgainstBlackJack(bytes16 _gameId, uint8[] memory _leftPlayers) private {
        for (uint256 i = 0; i < _leftPlayers.length; i++) {

            address player = Games[_gameId].players[_leftPlayers[i]];

            // payout if player also has a blackjack
            if (Games[_gameId].pState[i] == PlayerState.hasBlackJack) {

                uint128 amount = Games[_gameId].bets[_leftPlayers[i]];

                payoutAmount(
                    Games[_gameId].tokens[_leftPlayers[i]],
                    player,
                    amount
                );

                emit PlayersPayout(
                    player,
                    amount
                );
            }

            // payout if player purchased insurance
            if (PlayersInsurance[player][_gameId] == true) {

                uint128 amount = Games[_gameId].bets[_leftPlayers[i]];

                payoutAmount(
                    Games[_gameId].tokens[_leftPlayers[i]],
                    player,
                    amount
                );

                emit InsurancePayout(
                    player,
                    amount
                );
            }
        }
    }

    function $payoutAgainstDealersHand(bytes16 _gameId, uint8[] memory _leftPlayers, uint256 _dealersPower) private {
        for (uint256 i = 0; i < _leftPlayers.length; i++) {

            uint8 pi = _leftPlayers[i]; // players index
            address player = Games[_gameId].players[pi];
            uint256 playersPower = getHandsPower(getHand(_gameId, player, pi));
            uint128 payout;

            if (Games[_gameId].pState[pi] == PlayerState.hasBlackJack) {
                payout = Games[_gameId].bets[pi] * 250 / 100;
            }
            else if (playersPower > _dealersPower) {
                payout = Games[_gameId].bets[pi] * 200 / 100;
            }
            else if (playersPower == _dealersPower) {
                payout = Games[_gameId].bets[pi];
            }

            if (payout > 0) {
                payoutAmount(
                    Games[_gameId].tokens[pi],
                    player,
                    payout
                );
                emit PlayersPayout(
                    player,
                    payout
                );
            }
        }
    }

    function getNotBustedPlayers(bytes16 _gameId) public view returns (uint8[] memory) {
        return NonBustedPlayers[_gameId];
    }

    function payoutAmount(uint8 _tokenIndex, address _player, uint128 _amount) private {
        treasury.tokenOutboundTransfer(
            _tokenIndex, _player, uint256(_amount)
        );
    }

    function splitCards(
        bytes16 _gameId,
        address _player,
        uint8 _pIndex
    )
        external
        onlyWorker
        onlyOnGoingGame(_gameId)
        onlyNonBusted(_gameId, _pIndex)
        ifPlayerInGame(_gameId, _player, _pIndex)
    {
        require(
            PlayerSplit[_player][_gameId].length == 0 &&
            canSplitCards(PlayersHand[_player][_gameId])
        );

        Games[_gameId].players.push(_player);
        Games[_gameId].bets.push(Games[_gameId].bets[_pIndex]);
        Games[_gameId].tokens.push(Games[_gameId].tokens[_pIndex]);
        Games[_gameId].pState.push(PlayerState.isSplit);
        Games[_gameId].pState[_pIndex] = PlayerState.hasSplit;

        takePlayersBet(
            _gameId, _pIndex
        );

        PlayersHand[_player][_gameId].pop();
        PlayerSplit[_player][_gameId] = PlayersHand[_player][_gameId];

        emit splitHand(
            _gameId,
            _player,
            Games[_gameId].players.length - 1,
            PlayersHand[_player][_gameId],
            PlayerSplit[_player][_gameId]
        );
    }

    function purchaseInsurance(
        bytes16 _gameId,
        address _player,
        uint8 _pIndex
    )
        external
        onlyWorker
        onlyOnGoingGame(_gameId)
        onlyNonBusted(_gameId, _pIndex)
    {
        require (
            PlayersHand[_player][_gameId].length == 2 &&
            PlayersInsurance[_player][_gameId] == false
        );

        require (
            DealersVisible[_gameId].length == 1 &&
            getHandsPower(DealersVisible[_gameId]) == 11
        );

        PlayersInsurance[_player][_gameId] = true;

        uint8 playersCount = Games[_gameId].playersCount;
        uint8 tokenIndex = Games[_gameId].tokens[_pIndex];
        address player = Games[_gameId].players[_pIndex];
        uint256 betAmount = Games[_gameId].bets[_pIndex];

        _addPoints(
            player,
            betAmount / 2,
            treasury.getTokenAddress(tokenIndex),
            playersCount,
            0
        );

        treasury.tokenInboundTransfer(
            tokenIndex, player, betAmount / 2
        );

        emit InsurancePurchased(
            _gameId, player, _pIndex
        );
    }

    function doubleDown(
        bytes16 _gameId,
        address _player,
        bytes32 _localhashA,
        uint8 _pIndex
    )
        external
        onlyWorker
        onlyOnGoingGame(_gameId)
        onlyNonBusted(_gameId, _pIndex)
        ifPlayerInGame(_gameId, _player, _pIndex)
    {
        require (
            PlayersHand[_player][_gameId].length == 2
        );

        treasury.consumeHash(_localhashA);

        uint8 tokenIndex = Games[_gameId].tokens[_pIndex];
        address player = Games[_gameId].players[_pIndex];
        uint256 betAmount = Games[_gameId].bets[_pIndex];
        uint8 playersCount = Games[_gameId].playersCount;

        _addPoints(
            player,
            betAmount,
            treasury.getTokenAddress(tokenIndex),
            playersCount,
            0
        );

        treasury.tokenInboundTransfer(
            tokenIndex,
            player,
            betAmount
        );

        setBetAmount(
            _gameId,
            _pIndex,
            uint128(betAmount * 2)
        );

        postDoubleDownActions(
            _gameId,
            _player,
            _localhashA,
            _pIndex
        );
    }

    function setBetAmount(
        bytes16 _gameId,
        uint8 _pIndex,
        uint128 newBetAmount
    )
        public
    {
        Games[_gameId].bets[_pIndex] = newBetAmount;
    }

    function postDoubleDownActions(
        bytes16 _gameId,
        address _player,
        bytes32 _localhashA,
        uint8 _pIndex
    )
        public
    {
        drawPlayersCard(
           _gameId, _pIndex, _localhashA
        );

        uint256 playersPower = getHandsPower(
            getHand(_gameId, _player, _pIndex)
        );

        emit DoubleDown(
            playersPower
        );

        if (playersPower > 21) {
            Games[_gameId].pState[_pIndex] = PlayerState.isBusted;
            emit Busted(true);
        } else {
            NonBustedPlayers[_gameId].push(_pIndex);
            Games[_gameId].pState[_pIndex] = PlayerState.isSettled;
            emit Busted(false);
        }
    }

    function checkDeck(
        bytes16 _gameId
    )
        public
        view
        returns (uint8[] memory _deck)
    {
        return Games[_gameId].deck;
    }

    function getGameId(
        uint256 _serverID,
        uint256 _landID,
        uint256 _tableID,
        address[] memory _players,
        uint256 _nonce
    )
        public
        pure
        returns (bytes16 gameId)
    {
        gameId = bytes16(
            keccak256(
                abi.encodePacked(_serverID, _landID, _tableID, _players, _nonce)
            )
        );
    }

    /*
    function checkPlayerInGame(
        bytes16 _gameId,
        address _player
    )
        external
        view
        returns (bool)
    {
        return inGame[_player][_gameId] == inGameState.notJoined ? false : true;
    }

    function checkMyHand(
        bytes16 _gameId
    )
        external
        view
        returns (uint8[] memory)
    {
        return checkPlayersHand(_gameId, msg.sender);
    }

    function checkMySplit(
        bytes16 _gameId
    )
        external
        view
        returns (uint8[] memory)
    {
        return checkPlayerSplit(_gameId, msg.sender);
    }

    function checkDealersHand(
        bytes16 _gameId
    )
        public
        view
        returns (uint8[] memory)
    {
        return DealersVisible[_gameId];
    }

    function checkPlayersHand(
        bytes16 _gameId,
        address _player
    )
        public
        view
        returns (uint8[] memory)
    {
        return PlayersHand[_player][_gameId];
    }

    function checkPlayerSplit(
        bytes16 _gameId,
        address _player
    )
        public
        view
        returns (uint8[] memory)
    {
        return PlayerSplit[_player][_gameId];
    }*/

    function getHand(
        bytes16 _gameId,
        address _player,
        uint8 _playerIndex
    )
        public
        view
        returns (uint8[] memory playersHand)
    {
        playersHand = hasSplit(_gameId, _playerIndex)
            ? PlayerSplit[_player][_gameId]
            : PlayersHand[_player][_gameId];
    }

    function hasSplit(
        bytes16 _gameId,
        uint8 _pIndex
    )
        public
        view
        returns (bool)
    {
        return Games[_gameId].pState[_pIndex] == PlayerState.isSplit;
    }
}