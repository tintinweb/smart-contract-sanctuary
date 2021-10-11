// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./utils/VRFConsumerBaseUpgradeable.sol";
import "./utils/IVault.sol";
import "./utils/IGame.sol";

contract JackPot is
    Initializable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    VRFConsumerBaseUpgradeable,
    IGame
{
    enum GameState {
        OngoingGame,
        EndedGame
    }
    enum Action {
        Pending,
        Expired,
        Resolved
    }

    struct PlayerInfo {
        address player;
        uint128 bet; // bet for this player
        uint128 accBet; // accumulate bet for this player
    }

    mapping(address => uint8) public playerIndex;
    mapping(bytes32 => uint256) public requests;
    mapping(uint256 => uint256) public results;

    PlayerInfo[] public players;

    uint8 public minPlayers;
    uint8 public maxPlayers;
    uint8 public feeRate;
    uint8 public playerNum;

    GameState public state;
    uint128 public minBet;
    uint128 public maxBet;
    uint128 public jackPot; // variable to track current jackpot size;

    uint256 public gId;
    uint256 public gameStartTime; // Jackpot can be resolve after this time
    uint256 public gameExpireTime; // Player who join before minplayer reach could withdraw funds after game expired

    // This is the waiting time before room will be closed, triggered when new player join the room (after min player reached)
    uint256 public waitingTime;
    uint128 public constant minWaitingTime = 10;
    uint128 public constant maxWaitingTime = 2 hours;

    // This is the waiting time before player reach minimum player, gameState is ended and room expired then player can redeem back their bets
    uint256 public waitingTimeBeforeExpired;
    uint256 internal fee;

    bytes32 internal keyHash;
    bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");

    IVault public vault;

    modifier onlyOngoingGame() {
        require(state == GameState.OngoingGame, "JackPot.sol: Game is ended.");
        _;
    }

    modifier onlyPlayerInRange(uint8 _lower, uint8 _upper) {
        require(
            playerNum >= _lower && playerNum <= _upper,
            "JackPot.sol: The number of players is invalid."
        );
        _;
    }

    modifier onlyTimeReached(uint256 _time) {
        require(
            _time <= block.timestamp,
            "JackPot.sol: Time hasn't reached yet."
        );
        _;
    }

    event JoinGame(
        uint256 indexed gId,
        address indexed player,
        uint8 playerId,
        uint256 gameStartTime,
        uint256 indexed betAmount,
        uint256 jackPot
    );
    event ExpiredGame(uint256 indexed gId, GameState state);
    event ResolveJackpot(
        uint256 indexed gId,
        address indexed winnerAddress,
        GameState state,
        uint128 indexed jackPot,
        uint128 fee,
        bytes32 requestId,
        uint256 randomness
    );
    event RequestedRandomness(bytes32 indexed requestId, uint256 indexed gId);
    event SetFeeRate(uint8 prevFeeRate, uint8 indexed feeRate);
    event SetMaxMinPlayers(uint8 indexed maxPlayers, uint8 indexed minPlayers);
    event SetMaxMinBet(uint128 indexed maxBet, uint128 indexed minBet);
    event SetVaultAddress(address indexed vaultAddress);
    event SetWaitingTimeGame(
        uint256 indexed waitingTime,
        uint256 indexed waitingTimeBeforeExpired
    );
    event IncreaseBet(
        uint256 indexed gId,
        address indexed player,
        uint8 playerId,
        uint256 gameStartTime,
        uint256 betAmount,
        uint256 jackPot
    );

    function initialize(
        address _vaultAddress,
        uint8 _minPlayers,
        uint8 _maxPlayers,
        uint128 _minbet,
        uint128 _maxbet,
        uint256 _waitingTime,
        uint256 _waitingTimeBeforeExpired,
        bytes32 _keyhash,
        address _vrfCoordinator,
        address _linkToken,
        uint256 _fee
    ) public initializer {
        require(
            _vaultAddress != address(0),
            "JackPot.sol:Initialize, can not set vault address to address(0)"
        );
        require(
            _vrfCoordinator != address(0),
            "JackPot.sol:Initialize, can not set _vrfCoordinator address to address(0)"
        );
        require(
            _linkToken != address(0),
            "JackPot.sol:Initialize, can not set _linkToken address to address(0)"
        );
        require(
            _minPlayers >= 2,
            "JackPot.sol:Initialize, Minimum players have to be equal or more than 2"
        );
        require(
            _minPlayers <= _maxPlayers,
            "JackPot.sol:Initialize, Maximum players have to be more than minimum players"
        );
        require(
            _minbet < _maxbet,
            "Jackpot.sol:Initialize, minBet can not be more than maxBet."
        );
        VRFConsumerBaseUpgradeable.__VRFConsumerBase_init(
            _vrfCoordinator, // VRF Coordinator
            _linkToken //LINK Token
        );

        // OwnableUpgradeable
        OwnableUpgradeable.__Ownable_init();

        // AccessControlUpgradeable
        AccessControlUpgradeable.__AccessControl_init();

        // ReentrancyGuardUpgradeable
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        // PausableUpgradeable
        PausableUpgradeable.__Pausable_init();

        vault = IVault(_vaultAddress);
        emit SetVaultAddress(_vaultAddress);
        //set up the vault role to be used in pause and unpause
        _setupRole(VAULT_ROLE, _vaultAddress);

        // @dev deployer address will have default admin role which able to manage other role
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // max min players
        minPlayers = _minPlayers;
        maxPlayers = _maxPlayers;
        emit SetMaxMinPlayers(maxPlayers, minPlayers);

        //min and max bet (if applied)
        minBet = _minbet;
        maxBet = _maxbet;
        emit SetMaxMinBet(maxBet, minBet);

        // waitingTime game
        waitingTime = _waitingTime;
        waitingTimeBeforeExpired = _waitingTimeBeforeExpired;
        emit SetWaitingTimeGame(waitingTime, waitingTimeBeforeExpired);

        // game id
        gId = 1;

        // state
        state = GameState.OngoingGame;

        keyHash = _keyhash;
        // LinkToken fee for chainlink ramdomness
        fee = _fee;
        // default fee rate for jackpot winner
        feeRate = 2;
        emit SetFeeRate(0, feeRate);
    }

    function setWaitingTimeGame(
        uint256 _waitingTime,
        uint256 _waitingTimeBeforeExpired
    ) external onlyOwner {
        require(
            _waitingTime >= minWaitingTime && _waitingTime <= maxWaitingTime,
            "JackPot.sol: WaitingTime has to be in range"
        );
        require(
            _waitingTimeBeforeExpired >= minWaitingTime &&
                _waitingTimeBeforeExpired <= maxWaitingTime,
            "JackPot.sol: WaitingTimeBeforeExpired has to be in range"
        );
        waitingTime = _waitingTime;
        waitingTimeBeforeExpired = _waitingTimeBeforeExpired;
        emit SetWaitingTimeGame(waitingTime, waitingTimeBeforeExpired);
    }

    function setMaxMinPlayers(uint8 _max, uint8 _min)
        external
        onlyOwner
        whenPaused
    {
        require(
            _min >= 2,
            "JackPot.sol: Minimum players has to be equal or more than 2"
        );
        require(
            _min <= _max,
            "JackPot.sol: Maximum players has to be more than minimum players"
        );
        minPlayers = _min;
        maxPlayers = _max;
        emit SetMaxMinPlayers(_max, _min);
    }

    // setup vault address
    function setVaultAddress(address payable _vaultAddress)
        external
        onlyOwner
        whenPaused
    {
        require(
            _vaultAddress != address(0),
            "JackPot.sol:setVaultAddress, can not set the vault to address 0"
        );
        vault = IVault(_vaultAddress);
        emit SetVaultAddress(_vaultAddress);
    }

    // setup fee rate
    function setFeeRate(uint8 _feeRate) external onlyOwner whenPaused {
        require(
            _feeRate <= 50,
            "Jackpot.sol: Fee Rate can not be more than 50."
        );
        emit SetFeeRate(feeRate, _feeRate);
        feeRate = _feeRate;
    }

    // setup minmaxbet
    function setMinMaxBet(uint128 _minBet, uint128 _maxBet)
        external
        onlyOwner
        whenPaused
    {
        require(
            _minBet < _maxBet,
            "Jackpot.sol: minBet can not be more than maxBet."
        );
        minBet = _minBet;
        maxBet = _maxBet;
        emit SetMaxMinBet(_minBet, _maxBet);
    }

    function joinGame(uint128 _betAmount)
        external
        nonReentrant
        onlyOngoingGame
        whenNotPaused
    {
        require(
            gameExpireTime == 0 || block.timestamp < gameExpireTime,
            "JackPot.sol: Expired time reached."
        );
        require(
            gameStartTime == 0 || block.timestamp < gameStartTime,
            "JackPot.sol: Game has already started."
        );
        //normal joinGame logic
        if (playerIndex[msg.sender] == 0) {
            require(
                _betAmount >= minBet && _betAmount <= maxBet,
                "JackPot.sol: Bet amount must be more than minBet and less than maxBet in your first entering."
            );

            //logic to check if players are more than maxPlayers
            require(playerNum < maxPlayers, "JackPot.sol: Room is full.");

            vault.addGameBalance(msg.sender, _betAmount);

            jackPot += _betAmount;

            players.push(
                PlayerInfo({
                    player: msg.sender,
                    bet: _betAmount,
                    accBet: jackPot
                })
            );

            // playerIndex starts with 1 not 0.
            uint8 index = uint8(players.length);
            playerIndex[msg.sender] = index;

            playerNum++;

            // if player reach max, ready to start jackpot now
            if (playerNum == maxPlayers) {
                gameStartTime = block.timestamp + waitingTime;
            } else if (playerNum >= minPlayers) {
                //gameStartTime will assign only when playerNum >= min players
                gameStartTime = block.timestamp + waitingTime;
                // game can not be expired after player > min
                delete gameExpireTime;
            } else {
                // count down expire room
                gameExpireTime = block.timestamp + waitingTimeBeforeExpired;
            }

            emit JoinGame(
                gId,
                msg.sender,
                playerNum,
                gameStartTime,
                _betAmount,
                jackPot
            );
        }
        //increaseBet logic
        else {
            increaseBet(msg.sender, _betAmount);
        }
    }

    function increaseBet(address _player, uint128 _betAmount) internal {
        require(
            _betAmount >= minBet,
            "JackPot.sol:increaseBet, Bet amount must be more than minbet."
        );
        require(
            //the playerIndex is morethan real players index 1 step.
            players[playerIndex[_player] - 1].bet + _betAmount <= maxBet,
            "Jackpot:increaseBet, your bet can not reach maximum bet"
        );
        require(
            playerNum >= minPlayers,
            "Jackpot.increaseBet: Can not increase bet when there is not enough players."
        );

        vault.addGameBalance(_player, _betAmount);

        jackPot += _betAmount;

        gameStartTime = block.timestamp + waitingTime;

        //update user's bet in players array
        //the playerIndex is more than real players index 1 step.
        players[playerIndex[_player] - 1].bet += _betAmount;

        emit IncreaseBet(
            gId,
            _player,
            playerNum,
            gameStartTime,
            players[playerIndex[_player] - 1].bet,
            jackPot
        );
    }

    // Expired => wait back end to help trigger expired game
    // Pending => still waiting for player to join
    // Resolved => wait back end to help resolved winner
    function checkAction() external view returns (uint8) {
        if (state == GameState.EndedGame) {
            return uint8(Action.Pending);
        } else if (playerNum == 0) {
            return uint8(Action.Pending);
        } else if (playerNum >= minPlayers) {
            if (playerNum == maxPlayers) {
                return uint8(Action.Resolved);
            } else if (block.timestamp > gameStartTime && gameStartTime != 0) {
                return uint8(Action.Resolved);
            } else {
                return uint8(Action.Pending);
            }
        } else if (block.timestamp > gameExpireTime && gameExpireTime != 0) {
            return uint8(Action.Expired);
        } else {
            return uint8(Action.Pending);
        }
    }

    function expiredGame()
        external
        nonReentrant
        onlyOngoingGame
        onlyPlayerInRange(1, minPlayers - 1)
        onlyTimeReached(gameExpireTime)
    {
        for (uint256 pid = 0; pid < playerNum; pid++) {
            vault.subGameBalance(players[pid].player, players[pid].bet, 0);
            delete playerIndex[players[pid].player];
        }

        delete players;
        delete playerNum;
        delete gameExpireTime;
        delete gameStartTime;
        delete jackPot;

        emit ExpiredGame(gId, GameState.EndedGame);
        // Increase room id
        gId++;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        results[gId] = randomness;
        uint256 prob = randomness % jackPot;
        address winner;
        uint256 lowerBound;
        uint128 jackPotAfterFee;
        uint128 feeGame;
        for (uint256 pid = 0; pid < playerNum; pid++) {
            //update all players' acc bet to have a fair probability to win.
            if (pid == 0) {
                players[pid].accBet = players[pid].bet;
            } else {
                players[pid].accBet =
                    players[pid - 1].accBet +
                    players[pid].bet;
            }

            if (prob >= lowerBound && prob < players[pid].accBet) {
                // return winner player
                winner = players[pid].player;
                jackPotAfterFee = (jackPot * (100 - feeRate)) / 100;
                feeGame = jackPot - jackPotAfterFee;
                vault.subGameBalance(winner, jackPotAfterFee, feeGame);
            }
            lowerBound = players[pid].accBet; //players[pid].accBet = current jackpot of that player entering time.
            delete playerIndex[players[pid].player];
        }
        // emit resolve jackpot event before clear state
        emit ResolveJackpot(
            gId,
            winner,
            state,
            jackPotAfterFee,
            feeGame,
            requestId,
            randomness
        );

        delete players;
        delete playerNum;
        delete gameExpireTime;
        delete gameStartTime;
        delete jackPot;

        state = GameState.OngoingGame;
        gId++;
    }

    function getRandomNumber() internal returns (bytes32) {
        require(
            LINK.balanceOf(address(this)) > fee,
            "JackPot.sol: Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    function resolveWinner()
        external
        nonReentrant
        onlyOngoingGame
        onlyPlayerInRange(minPlayers, maxPlayers)
        onlyTimeReached(gameStartTime)
    {
        bytes32 requestId = getRandomNumber();
        requests[requestId] = gId;
        state = GameState.EndedGame;

        emit RequestedRandomness(requestId, gId);
    }

    function getPlayers() external view returns (PlayerInfo[] memory) {
        return players;
    }

    function pause() external override onlyRole(VAULT_ROLE) {
        _pause();
    }

    function unpause() external override onlyRole(VAULT_ROLE) {
        _unpause();
    }

    //to check so that the vault can delete the game without effecting the playing players
    function isPlayerStillPlaying() external view override returns (bool) {
        if (players.length >= 1 && state == GameState.OngoingGame) {
            return true;
        } else {
            return false;
        }
    }

    function withdrawLink() external onlyOwner {
        uint256 amount = LINK.balanceOf(address(this));
        require(amount > 0, "JackPot.sol: Not have LINK");
        LINK.transfer(owner(), amount);
    }

    receive() external payable {
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
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
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