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

contract CoinFlip is
    Initializable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    VRFConsumerBaseUpgradeable,
    IGame
{
    enum GameState {
        Ended,
        Waiting,
        OnGoing
    }

    enum CoinFace {
        Head,
        Tail
    }

    struct RoomInfo {
        GameState state;
        uint128 betAmount;
        uint256 gameId;
        uint256 expiredTime;
        address playerHead;
        address playerTail;
        address winner;
    }

    mapping(uint8 => RoomInfo) public rooms;
    mapping(bytes32 => uint8) public requests; // requestId => rId
    mapping(uint256 => uint256) public results; // rId => randomResult

    uint8 public maxRoom;
    uint8 public feeRate;
    uint128 public minBet; //= 1 ether;
    uint128 public maxBet;
    uint128 public constant minWaitingTime = 10 seconds;
    uint128 public constant maxWaitingTime = 2 hours;
    uint128 public waitingTime;
    uint256 internal fee;
    uint256 public gId; //unique roomId

    bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");
    bytes32 internal keyHash;

    IVault public vault;

    modifier onlyWaitingRoom(uint8 _rId) {
        require(
            rooms[_rId].state == GameState.Waiting,
            "CoinFlip.sol: Room is ongoing."
        );
        _;
    }

    event CreateNewRoom(
        uint8 indexed rId,
        address player,
        uint128 betAmount,
        CoinFace coinFace,
        GameState state,
        uint256 expiredTime,
        uint256 indexed gameId
    );

    event ExpiredRoom(
        uint8 indexed rId,
        address playerRefund,
        uint128 betAmount,
        uint256 indexed gameId
    );

    event JoinRoom(
        uint8 indexed rId,
        address player,
        GameState state,
        uint256 indexed gameId,
        uint256 gameStartTime
    );

    event ResolveRoom(
        uint8 indexed rId,
        address winner,
        uint128 winnerBet,
        uint128 fee,
        GameState state,
        uint256 indexed gameId,
        bytes32 requestId,
        uint256 randomness
    );

    event RequestedRandomness(
        bytes32 indexed requestId,
        uint8 indexed rId,
        uint256 indexed gameId
    );

    event SetVaultAddress(address vault);

    event SetFeeRate(uint8 rate);

    event SetMaxRoom(uint8 room);

    event SetMaxMinBet(uint128 maxBet, uint128 minBet);

    event SetWaitingTime(uint128 time);

    /**
     * Constructor inherits VRFConsumerBase
     *
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     * fee = 0.1 * 10**18; // 0.1 LINK
     *
     * Network: Polygon (Matic) Mumbai Testnet
     * Chainlink VRF Coordinator address: 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255
     * LINK token address:                0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     * Key Hash: 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4
     * fee = 1 * 10 ** 15 ; // 0.0001 LINK
     *
     */
    function initialize(
        address _vaultAddress,
        uint8 _maxRoom,
        uint128 _minBet,
        uint128 _maxBet,
        bytes32 _keyhash,
        address _vrfCoordinator,
        address _linkToken,
        uint256 _fee
    ) public initializer {
        require(
            _vaultAddress != address(0),
            "CoinFlip.sol:initialize, vault address can not be address(0)"
        );
        require(
            _vrfCoordinator != address(0),
            "CoinFlip.sol:initialize, _vrfCoordinator address can not be address(0)"
        );
        require(
            _linkToken != address(0),
            "CoinFlip.sol:initialize, _linkToken address can not be address(0)"
        );
        require(
            _maxRoom >= 1,
            "CoinFlip.sol:Initialize, _maxRoom has to be equal or more than 1"
        );
        require(
            _minBet < _maxBet,
            "CoinFlip.sol:Initialize, _maxBet has to be more than _minBet"
        );
        VRFConsumerBaseUpgradeable.__VRFConsumerBase_init(
            _vrfCoordinator, // VRF Coordinator
            _linkToken // LINK Token
        );

        // @dev deployer address will have default admin role which able to manage other role
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // OwnableUpgradeable
        OwnableUpgradeable.__Ownable_init();

        // AccessControlUpgradeable
        AccessControlUpgradeable.__AccessControl_init();
        _setupRole(VAULT_ROLE, _vaultAddress);

        // ReentrancyGuardUpgradeable
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        // PausableUpgradeable
        PausableUpgradeable.__Pausable_init();

        vault = IVault(_vaultAddress);
        emit SetVaultAddress(address(vault));

        maxRoom = _maxRoom;
        emit SetMaxRoom(maxRoom);

        //max and minimum bet amount
        minBet = _minBet;
        maxBet = _maxBet;
        emit SetMaxMinBet(maxBet, minBet);

        keyHash = _keyhash;
        fee = _fee;

        // default fee rate
        feeRate = 2;
        emit SetFeeRate(feeRate);

        // default waiting time
        waitingTime = 180;
        emit SetWaitingTime(waitingTime);

        // for the graph
        for (uint8 rid = 1; rid <= maxRoom; rid++) {
            emit CreateNewRoom(
                rid,
                address(0),
                0,
                CoinFace.Head,
                GameState.Ended,
                0,
                0
            );
        }
    }

    // setup max room
    function setMaxRoom(uint8 _maxRoom) external whenPaused onlyOwner {
        require(
            _maxRoom >= 1,
            "CoinFlip.sol: Max Rooms has to be more than or equal to 1."
        );
        // for the graph
        if (maxRoom < _maxRoom) {
            for (uint8 rid = maxRoom + 1; rid <= _maxRoom; rid++) {
                emit CreateNewRoom(
                    rid,
                    address(0),
                    0,
                    CoinFace.Head,
                    GameState.Ended,
                    0,
                    0
                );
            }
        }

        maxRoom = _maxRoom;
        emit SetMaxRoom(maxRoom);
    }

    // setup max bet
    function setMaxMinBet(uint128 _maxBet, uint128 _minBet)
        external
        whenPaused
        onlyOwner
    {
        require(
            _maxBet > _minBet,
            "CoinFlip.sol: Max Bets has to be more than min bets."
        );
        maxBet = _maxBet;
        minBet = _minBet;
        emit SetMaxMinBet(maxBet, minBet);
    }

    // setup waiting time
    function setWaitingTime(uint128 _waitingTime) external onlyOwner {
        require(
            _waitingTime >= minWaitingTime && _waitingTime <= maxWaitingTime,
            "CoinFlip.sol: Waiting Time has to be in range."
        );
        waitingTime = _waitingTime;
        emit SetWaitingTime(waitingTime);
    }

    // setup fee rate
    function setFeeRate(uint8 _feeRate) external whenPaused onlyOwner {
        require(
            _feeRate <= 50,
            "CoinFlip.sol: Fee Rate can't be more than 50."
        );
        feeRate = _feeRate;
        emit SetFeeRate(feeRate);
    }

    // setup vault address
    function setVaultAddress(address _vaultAddress)
        external
        whenPaused
        onlyOwner
    {
        require(
            _vaultAddress != address(0),
            "CoinFlip.sol:setVaultAddress, can not set the vault to address 0"
        );
        vault = IVault(_vaultAddress);
        emit SetVaultAddress(_vaultAddress);
    }

    function createNewRoom(
        uint8 _rId,
        CoinFace _coinFace,
        uint128 _betAmount
    ) external whenNotPaused nonReentrant {
        require(
            _rId > 0 && _rId <= maxRoom,
            "CoinFlip.sol: Room ID is out of range."
        );
        RoomInfo storage room = rooms[_rId];
        require(
            room.state == GameState.Ended,
            "CoinFlip.sol: Room is ongoing."
        );
        require(
            _betAmount >= minBet && _betAmount <= maxBet,
            "CoinFlip.sol: Bet amount must be more than minBet and less than maxBet."
        );

        vault.addGameBalance(msg.sender, _betAmount);

        room.betAmount = _betAmount;
        room.state = GameState.Waiting;
        room.expiredTime = block.timestamp + waitingTime;
        room.gameId = ++gId;
        if (_coinFace == CoinFace.Head) {
            room.playerHead = msg.sender;
        } else {
            room.playerTail = msg.sender;
        }

        emit CreateNewRoom(
            _rId,
            msg.sender,
            room.betAmount,
            _coinFace,
            room.state,
            room.expiredTime,
            room.gameId
        );
    }

    function cancelRoom(uint8 _rId)
        external
        nonReentrant
        onlyWaitingRoom(_rId)
    {
        RoomInfo memory room = rooms[_rId];
        address playerRefund;
        if (room.playerHead != address(0)) {
            playerRefund = room.playerHead;
        } else {
            playerRefund = room.playerTail;
        }

        require(
            playerRefund == msg.sender,
            "CoinFlip.sol: Only creator can cancel room."
        );

        _resetRoom(_rId, playerRefund);
    }

    function expiredRoom(uint8 _rId)
        external
        nonReentrant
        onlyWaitingRoom(_rId)
    {
        RoomInfo memory room = rooms[_rId];
        require(
            room.expiredTime <= block.timestamp,
            "CoinFlip.sol: Expired time doesn't reach."
        );

        address playerRefund;
        if (room.playerHead != address(0)) {
            playerRefund = room.playerHead;
        } else {
            playerRefund = room.playerTail;
        }

        _resetRoom(_rId, playerRefund);
    }

    function _resetRoom(uint8 _rId, address _player) internal {
        RoomInfo memory room = rooms[_rId];
        vault.subGameBalance(_player, room.betAmount, 0);
        delete (rooms[_rId]);

        emit ExpiredRoom(_rId, _player, room.betAmount, room.gameId);
    }

    function joinRoom(uint8 _rId)
        external
        whenNotPaused
        nonReentrant
        onlyWaitingRoom(_rId)
    {
        RoomInfo storage room = rooms[_rId];
        require(
            room.expiredTime > block.timestamp,
            "CoinFlip.sol: Expired time reached."
        );
        require(
            room.playerHead != msg.sender && room.playerTail != msg.sender,
            "CoinFlip.sol: This player has already joined this room."
        );

        vault.addGameBalance(msg.sender, room.betAmount);

        if (room.playerHead != address(0)) {
            room.playerTail = msg.sender;
        } else {
            room.playerHead = msg.sender;
        }
        room.state = GameState.OnGoing;

        resolveRoom(_rId);

        emit JoinRoom(
            _rId,
            msg.sender,
            room.state,
            room.gameId,
            block.timestamp
        );
    }

    /**
     * Requests randomness
     */
    function getRandomNumber() internal returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) > fee,
            "CoinFlip.sol: Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        uint8 _rId = requests[requestId];
        RoomInfo storage room = rooms[_rId];
        results[_rId] = randomness;

        uint256 prob = randomness % 100; // use last 2 digit to estimate prob
        // if prob >= 50 then head
        CoinFace result;
        if (prob >= 50) {
            result = CoinFace.Head;
            room.winner = room.playerHead;
        } else {
            result = CoinFace.Tail;
            room.winner = room.playerTail;
        }

        uint128 betAmount = room.betAmount * 2;
        uint128 winnerBet = (betAmount * (100 - feeRate)) / 100;
        uint128 feeGame = betAmount - winnerBet;
        vault.subGameBalance(room.winner, winnerBet, feeGame);

        emit ResolveRoom(
            _rId,
            room.winner,
            winnerBet,
            feeGame,
            room.state,
            room.gameId,
            requestId,
            randomness
        );

        // case delete after get winner
        delete (rooms[_rId]);
    }

    function resolveRoom(uint8 _rId) internal {
        RoomInfo memory room = rooms[_rId];
        require(
            room.state == GameState.OnGoing,
            "CoinFlip.sol: Waiting for 2nd player."
        );

        bytes32 requestId = getRandomNumber();
        requests[requestId] = _rId;

        emit RequestedRandomness(requestId, _rId, room.gameId);
    }

    function emergencyEndGame(uint8 _rId) external onlyOwner {
        RoomInfo memory room = rooms[_rId];

        if (room.playerHead != address(0)) {
            vault.subGameBalance(room.playerHead, room.betAmount, 0);
        }
        if (room.playerTail != address(0)) {
            vault.subGameBalance(room.playerTail, room.betAmount, 0);
        }
        delete (rooms[_rId]);
    }

    function pause() external override onlyRole(VAULT_ROLE) {
        _pause();
    }

    function unpause() external override onlyRole(VAULT_ROLE) {
        _unpause();
    }

    function isPlayerStillPlaying() external view override returns (bool) {
        bool res = true;
        for (uint8 i = 0; i < maxRoom; i++) {
            RoomInfo storage info = rooms[i];
            if (
                info.state == GameState.Waiting ||
                info.state == GameState.OnGoing
            ) {
                return res;
            }
        }
        return false;
    }

    function withdrawLink() external onlyOwner {
        uint256 amount = LINK.balanceOf(address(this));
        require(amount > 0, "CoinFlip.sol: Not have LINK");
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