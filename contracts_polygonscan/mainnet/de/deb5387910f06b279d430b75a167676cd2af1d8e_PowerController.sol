// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./IPowerController.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title A contract for accounting of polypower
 * @notice Some contracts like staking are allowed to increase and decrease users' power
 * Some contracts like IDO pool are allowed to lock and unlock power.
 * This mechanism is created to ensure users stake tokens/LP while participating in IDOs
 */
contract PowerController is
    Initializable,
    IPowerController,
    AccessControlUpgradeable
{
    // track total power generated in system
    uint256 private _totalPower;

    // track total power of each user
    mapping(address => uint256) private _totalUserPower;

    // track generated power per user per manager
    // userAddress => managerAddress => amountGenerated
    mapping(address => mapping(address => uint256))
        private _generatedManagerPower;

    // track locked power of each user
    mapping(address => uint256) private _lockedUserPower;

    // track locked power of each user per pool
    // userAddress => poolAddress => amountLockedInPool
    mapping(address => mapping(address => uint256)) private _lockedPoolPower;

    // @notice role identifier for pools
    bytes32 public constant POOL_ROLE = keccak256("POOL_ROLE");

    // @notice role identifier for power managers
    bytes32 public constant POWER_MANAGER_ROLE =
        keccak256("POWER_MANAGER_ROLE");

    // @notice role identifier for pool role admins
    bytes32 public constant POOL_ROLE_ADMIN = keccak256("POOL_ROLE_ADMIN");

    event IncreasePower(
        address indexed user,
        uint256 power,
        bytes32 reasonHash
    );
    event DecreasePower(
        address indexed user,
        uint256 power,
        bytes32 reasonHash
    );
    event LockPower(
        address indexed idoPool,
        address indexed user,
        uint256 power
    );
    event UnlockPower(
        address indexed idoPool,
        address indexed user,
        uint256 power
    );

    // event UnlockFullPower(address indexed idoPool, address indexed user);

    /**
     * @notice Replacement of constructor for upgradeable contract.
     * Initializes roles.
     * Can be called only once.
     * @param idoControllerAddress address of IDOController contract
     */
    function initialize(address idoControllerAddress)
        public
        override
        initializer
    {
        __AccessControl_init();
        _setRoleAdmin(POOL_ROLE, POOL_ROLE_ADMIN);
        _setupRole(POOL_ROLE_ADMIN, idoControllerAddress);
        _setupRole(POOL_ROLE_ADMIN, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Increase user's power.
     * Can be called only by Power Managers i.e staking / LP / other activity trackers.
     * @param user address of user to increase power
     * @param power amount of power to increase
     */
    function increasePower(
        address user,
        uint256 power,
        bytes32 reason
    ) external override onlyRole(POWER_MANAGER_ROLE) {
        require(user != address(0), "PowerController: Zero address");
        _totalUserPower[user] += power;
        _generatedManagerPower[user][msg.sender] += power;
        _totalPower += power;

        emit IncreasePower(user, power, reason);
    }

    /**
     * @notice Decrease user's power.
     * Can be called only by Power Managers i.e staking / LP / other activity trackers.
     * @dev Should be able to decrease only unlocked power
     * @param user address of user to decrease power
     * @param power amount of power to decrease
     */
    function decreasePower(
        address user,
        uint256 power,
        bytes32 reason
    ) external override onlyRole(POWER_MANAGER_ROLE) {
        require(
            _userUnlockedPower(user) >= power,
            "PowerController: Insufficient unlocked power to burn"
        );
        _totalUserPower[user] -= power;
        _generatedManagerPower[user][msg.sender] -= power;
        _totalPower -= power;
        emit DecreasePower(user, power, reason);
    }

    /**
     * @notice Lock user's power.
     * Can be called only by Pools.
     * @dev Pool is only able to lock uptill user's unlocked power
     * @param user address of user to lock power
     * @param power amount of power to lock
     */
    function lockPower(address user, uint256 power)
        external
        override
        onlyRole(POOL_ROLE)
    {
        require(
            _userUnlockedPower(user) >= power,
            "PowerController: Insufficient unlocked power"
        );
        _lockedPoolPower[user][msg.sender] += power;
        _lockedUserPower[user] += power;

        emit LockPower(msg.sender, user, power);
    }

    /**
     * @notice Unlock user's power.
     * Can be called only by Pools.
     * @dev Pool is only able to unlock power that was locked by it.
     * @param user address of user to unlock power
     * @param power amount of power to unlock
     */
    function unlockPower(address user, uint256 power)
        external
        override
        onlyRole(POOL_ROLE)
    {
        _lockedPoolPower[user][msg.sender] -= power;
        _lockedUserPower[user] -= power;

        emit UnlockPower(msg.sender, user, power);
    }

    /**
     * @notice Unlock user's full power for particular pool.
     * Can be called only by Pools.
     * @param user address of user to unlock power
     */
    function unlockFullPower(address user)
        external
        override
        onlyRole(POOL_ROLE)
    {
        uint256 unlockablePower = _lockedPoolPower[user][msg.sender];
        _lockedUserPower[user] -= unlockablePower;
        _lockedPoolPower[user][msg.sender] = 0;

        emit UnlockPower(msg.sender, user, unlockablePower);
    }

    // ------ Public Getter Functions ------

    /**
     * @notice Get total power in system
     */
    function getTotalPower() external view override returns (uint256) {
        return _totalPower;
    }

    /**
     * @notice Get user's total power in system
     * @param user address of user
     */
    function getUserTotalPower(address user)
        external
        view
        override
        returns (uint256)
    {
        return _totalUserPower[user];
    }

    /**
     * @notice Get user's generated power from particular manager
     * @param user address of user
     * @param manager address of manager
     */
    function getGeneratedManagerPower(address user, address manager)
        external
        view
        override
        returns (uint256)
    {
        return _generatedManagerPower[user][manager];
    }

    /**
     * @notice Get user's locked power for particular pool
     * @param user address of user
     * @param pool address of pool
     */
    function getLockedPoolPower(address user, address pool)
        external
        view
        override
        returns (uint256)
    {
        return _lockedPoolPower[user][pool];
    }

    /**
     * @notice Get user's total locked power
     * @param user address of user
     */
    function getLockedPower(address user)
        external
        view
        override
        returns (uint256)
    {
        return _lockedUserPower[user];
    }

    /**
     * @notice Get user's total unlocked power
     * @param user address of user
     */
    function getUnlockedPower(address user)
        external
        view
        override
        returns (uint256)
    {
        return _userUnlockedPower(user);
    }

    /**
     * @dev override AccessControl function to include in interface
     */
    function grantRole(bytes32 role, address user)
        public
        override(IPowerController, AccessControlUpgradeable)
    {
        AccessControlUpgradeable.grantRole(role, user);
    }

    function _userUnlockedPower(address user) private view returns (uint256) {
        return _totalUserPower[user] - _lockedUserPower[user];
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
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
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
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                StringsUpgradeable.toHexString(uint160(account), 20),
                " is missing role ",
                StringsUpgradeable.toHexString(uint256(role), 32)
            )));
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

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract IPowerController {
    function increasePower(
        address user,
        uint256 power,
        bytes32 reason
    ) external virtual;

    function decreasePower(
        address user,
        uint256 power,
        bytes32 reason
    ) external virtual;

    function lockPower(address user, uint256 power) external virtual;

    function unlockPower(address user, uint256 power) external virtual;

    function unlockFullPower(address user) external virtual;

    function grantRole(bytes32 role, address account) external virtual;

    function initialize(address idoControllerAddress) public virtual;

    // ------ external Getter Functions ------

    function getTotalPower() external view virtual returns (uint256);

    function getUserTotalPower(address user)
        external
        view
        virtual
        returns (uint256);

    function getGeneratedManagerPower(address user, address manager)
        external
        view
        virtual
        returns (uint256);

    function getLockedPoolPower(address user, address pool)
        external
        view
        virtual
        returns (uint256);

    function getLockedPower(address user)
        external
        view
        virtual
        returns (uint256);

    function getUnlockedPower(address user)
        external
        view
        virtual
        returns (uint256);
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}