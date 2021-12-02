// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./utils/IVault.sol";
import "./utils/IGame.sol";

interface ICashInOut {
    function joinGame(
        address _player,
        uint128 _amount,
        uint256 _gId,
        string calldata _rId
    ) external;

    function resolveGame(
        address[] memory _players,
        uint128[] memory _amounts,
        uint128 _fee,
        uint8 _gId,
        string calldata _rId
    ) external;

    function expireGame(
        uint128 _fee,
        uint8 _gId,
        string calldata _rId
    ) external;
}

contract CashInOut is
    Initializable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IGame
{

    enum GameState {
        OnGoingGame,
        ResolvedGame
    }

    struct GameInfo {
        string gameName;
        uint8 rewardMultiplier;
        uint8 fee;
        uint8 maxPlayer;
        uint128 minBet;
        uint128 maxBet;
    }

    struct Game {
        address[] players;
        uint128[] bets;
        uint8 playerCount;
        GameState gameState;
    }

    //gId in this case is game indexer not running number.
    //gameId to user address to their balances.
    // mapping(uint8 => mapping(address => uint128)) public balances;
    mapping(uint256 => bool) internal canJoinMultiRoom;
    //gameid=>roomId => Game
    mapping(uint256 => mapping(string => Game)) public games;
    //gameid => gameInfo
    mapping(uint256 => GameInfo) public gameInfo;

    //gId => rId => reserve
    mapping(uint256 => mapping(string => uint128)) internal reserves;

    mapping(address => mapping(uint256 => mapping(string => bool)))
        internal playerInGame;
    //track where player is at in each gameId starting with 1;
    // mapping(uint8 => mapping(uint8 => uint256)) public playerIndex;

    //gameId to bool.
    mapping(uint256 => bool) public isFreeGame;

    bytes32 public constant WORKER_ROLE = keccak256("WORKER_ROLE");
    bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");

    IVault public vault;
    // IGame public igame;

    modifier playerNotPlaying(uint256 _gId, string calldata _rId) {
        Game storage game = games[_gId][_rId];
        require(
            game.playerCount == 0,
            "cashInOut.sol, there is a player in the game"
        );
        _;
    }

    event JoinGame(
        address indexed player,
        uint128 amount,
        uint256 gId,
        string rId
    );

    event ResolveGame(
        address[] indexed players,
        uint128[] amount,
        uint256 _gId,
        string _rId
    );

    event ExpireGame(uint256 indexed gId, string rId);

    event SetFreeGame(uint256 indexed _gId, bool _bool);

    event SetFeeRate(uint256 indexed _gId, uint8 indexed feeRate);

    event SetMaxPlayer(uint256 indexed _gId, uint8 indexed _max);

    event SetMaxMinBet(uint256 indexed _gId, uint128 _minBet, uint128 _maxBet);

    event RegisterGame(
        string indexed _gameName,
        uint256 _gId,
        uint128 _minBet,
        uint128 _maxBet,
        uint8 _maxPlayer,
        uint8 _fee
    );

    function initialize( address _vault)
        public
        initializer
    {
        // OwnableUpgradeable
        OwnableUpgradeable.__Ownable_init();

        // AccessControlUpgradeable
        AccessControlUpgradeable.__AccessControl_init();

        // ReentrancyGuardUpgradeable
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        // PausableUpgradeable
        PausableUpgradeable.__Pausable_init();

        // @dev deployer address will have default admin role which able to manage other role
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(VAULT_ROLE, _vault);
        _setupRole(WORKER_ROLE, msg.sender);

        vault = IVault(_vault);

        //set Dino(index0) run to be free game. While Tiki(index1) is not free.
        registerGame("Dino", 0, 0, 10**22, 10, 0, true, 0);
        registerGame("Tiki", 1, 0, 10**22, 5, 20, false, 0);
    }

    function joinGame(
        uint128 _amount,
        uint256 _gId,
        string calldata _rId
    )
        external
        whenNotPaused // onlyRole(WORKER_ROLE)
    {
        GameInfo storage info = gameInfo[_gId];
        Game storage game = games[_gId][_rId];

        require(
            _amount >= info.minBet && _amount <= info.maxBet,
            "cashInOut, require minBet, maxBet"
        );

        require(
            game.playerCount + 1 <= info.maxPlayer,
            "cashInOut, maxPlayer reached"
        );

        //comment out in case if Dino can join multiple time
        require(
            playerInGame[msg.sender][_gId][_rId] == false,
            "CashInOut:joinGame, player already joined"
        );

        game.players.push(msg.sender);
        game.bets.push(_amount);
        game.playerCount++;

        if (_amount > 0) {
            require(
                !isFreeGame[_gId],
                "cashInOut.sol, free game should not add game balance"
            );
            vault.addGameBalance(msg.sender, _amount);
            uint128 maxReward = gamesRewardMultiplier(_gId, _amount);
            vault.addReserveOperating(maxReward);
            reserves[_gId][_rId] += _amount + maxReward;
        }

        playerInGame[msg.sender][_gId][_rId] = true;

        emit JoinGame(msg.sender, _amount, _gId, _rId);
    }

    function resolveGame(
        address[] memory _players,
        uint128[] memory _amounts,
        uint256 _gId,
        string calldata _rId
    ) external whenNotPaused onlyRole(WORKER_ROLE) {
        // GameInfo storage info = gameInfo[_gId];
        Game storage game = games[_gId][_rId];
        require(
            game.gameState == GameState.OnGoingGame,
            "cashInOut:resolveGame, already resolved"
        );

        //pay out the game's winners.
        //for Tiki.
        if (!isFreeGame[_gId]) {
            for (uint128 i = 0; i < _players.length; i++) {
                address player = _players[i];
                uint128 reward = _amounts[i];
                vault.subGameBalance(player, reward, 0);
                reserves[_gId][_rId] -= reward;
            }
            vault.subReserveOperating(reserves[_gId][_rId]);
            reserves[_gId][_rId] = 0;
        } else {
            //for Dino cause players join through backend.
            for (uint128 i = 0; i < _players.length; i++) {
                address player = _players[i];
                uint128 reward = _amounts[i];
                vault.addReserveOperating(reward);
                vault.subGameBalance(player, reward, 0);
            }
        }

        game.gameState = GameState.ResolvedGame;

        emit ResolveGame(_players, _amounts, _gId, _rId);
    }

    //subGameBalance only the game that's not free
    //dino will skip the loop but Tiki will run the loop.
    function expireGame(
        uint8 _gId,
        string memory _rId
    ) external whenNotPaused onlyRole(WORKER_ROLE) {
        // GameInfo storage info = gameInfo[_gId];
        Game storage game = games[_gId][_rId];

        require(
            game.gameState == GameState.OnGoingGame,
            "cashInOut:expireGame, already resolved"
        );

        require(!isFreeGame[_gId], "cashInOut: expire only non-free game");
        for (uint8 i = 0; i < game.players.length; i++) {
            address player = game.players[i];
            vault.subGameBalance(player, game.bets[i], 0);
        }
        game.gameState = GameState.ResolvedGame;

        emit ExpireGame(_gId, _rId);
    }

    function setFreeGame(uint8 _gId, bool _bool) external onlyOwner whenPaused {
        isFreeGame[_gId] = _bool;
        emit SetFreeGame(_gId, _bool);
    }

    //only for setting in testing.
    function setGameState(
        uint8 _gId,
        string memory _rId,
        uint8 _state
    ) external onlyOwner whenPaused {
        if (_state == 0) {
            games[_gId][_rId].gameState = GameState.OnGoingGame;
        } else {
            games[_gId][_rId].gameState = GameState.ResolvedGame;
        }
    }

    function isPlayerInGame(
        address _player,
        uint8 _gId,
        string memory _rId
    ) public view returns (bool) {
        return playerInGame[_player][_gId][_rId];
    }

    function gamesRewardMultiplier(uint256 _gId, uint128 _amount)
        internal
        view
        returns (uint128)
    {
        GameInfo storage info = gameInfo[_gId];
        uint8 rewardMultiplier = info.rewardMultiplier;
        return _amount * rewardMultiplier;
    }

    function setRewardMultiplier(uint8 _gId, uint8 _multiplier)
        external
        onlyOwner
    {
        GameInfo storage info = gameInfo[_gId];
        info.rewardMultiplier = _multiplier;
    }

    function setFeeRate(uint8 _gId, uint8 _feeRate)
        external
        onlyOwner
        whenPaused
    {
        require(
            _feeRate <= 50,
            "CoinFlip.sol: Fee Rate can't be more than 50."
        );
        GameInfo storage info = gameInfo[_gId];
        info.fee = _feeRate;

        emit SetFeeRate(_gId, _feeRate);
    }

    function setMaxPlayers(uint8 _gId, uint8 _max)
        external
        onlyOwner
        whenPaused
    {
        GameInfo storage info = gameInfo[_gId];
        info.maxPlayer = _max;
        emit SetMaxPlayer(_gId, _max);
    }

    function setMinMaxBet(
        uint8 _gId,
        uint128 _minBet,
        uint128 _maxBet
    ) external onlyOwner whenPaused {
        require(
            _minBet < _maxBet,
            "Jackpot.sol: minBet can not be more than maxBet."
        );
        GameInfo storage info = gameInfo[_gId];
        info.minBet = _minBet;
        info.maxBet = _maxBet;
        emit SetMaxMinBet(_gId, _minBet, _maxBet);
    }

    function registerGame(
        string memory _gameName,
        uint8 _gId,
        uint128 _minBet,
        uint128 _maxBet,
        uint8 _maxPlayer,
        uint8 _rewardMultiplier,
        bool _isFreeGame,
        uint8 _fee
    ) public onlyOwner {
        require(
            _minBet <= _maxBet,
            "Jackpot.sol: minBet can not be more than maxBet."
        );
        require(
            _maxPlayer >= 1,
            "Jackpot.sol: minBet can not be more than maxBet."
        );

        GameInfo storage info = gameInfo[_gId];

        require(
            keccak256(abi.encodePacked(info.gameName)) ==
                keccak256(abi.encodePacked("")),
            "cashinOut, game has been registered"
        );

        isFreeGame[_gId] = _isFreeGame;
        info.fee = _fee;
        info.gameName = _gameName;
        info.maxPlayer = _maxPlayer;
        info.minBet = _minBet;
        info.maxBet = _maxBet;
        info.rewardMultiplier = _rewardMultiplier;

        emit RegisterGame(_gameName, _gId, _minBet, _maxBet, _maxPlayer, _fee);
    }

    function pause() external override onlyRole(VAULT_ROLE) {
        _pause();
    }

    function unpause() external override onlyRole(VAULT_ROLE) {
        _unpause();
    }

    function isPlayerStillPlaying() external pure override returns (bool) {
        return false;
    }

    function getPlayerInfo(
        uint8 _gId,
        string memory _rId,
        uint8 _index
    ) external view returns (address, uint128) {
        if (games[_gId][_rId].playerCount > 0) {
            return (
                games[_gId][_rId].players[_index],
                games[_gId][_rId].bets[_index]
            );
        } else {
            return (address(0), 0);
        }
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

interface IVault {
    function addGameBalance(address _player, uint128 _amount) external;

    function subGameBalance(
        address _player,
        uint128 _balance,
        uint128 _fee
    ) external;

    function addReserveOperating(uint128 _amount) external;

    function subReserveOperating(uint128 _amount) external;

    // function depositFund(uint8 gameIndex, uint128 amount) external;
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