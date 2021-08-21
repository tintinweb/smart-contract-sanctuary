/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

// SPDX-License-Identifier: GPL-3.0 AND MIT
// File: contracts/interfaces/IEVMScriptExecutor.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity ^0.8.4;

/// @notice Interface of EVMScript executor used by EasyTrack
interface IEVMScriptExecutor {
    function executeEVMScript(bytes memory _evmScript) external returns (bytes memory);
}

// File: OpenZeppelin/[email protected]/contracts/proxy/utils/Initializable.sol


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

// File: OpenZeppelin/[email protected]/contracts/utils/ContextUpgradeable.sol


pragma solidity ^0.8.0;


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

// File: OpenZeppelin/[email protected]/contracts/utils/StringsUpgradeable.sol


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

// File: OpenZeppelin/[email protected]/contracts/utils/introspection/IERC165Upgradeable.sol


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

// File: OpenZeppelin/[email protected]/contracts/utils/introspection/ERC165Upgradeable.sol


pragma solidity ^0.8.0;



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

// File: OpenZeppelin/[email protected]/contracts/access/AccessControlUpgradeable.sol


pragma solidity ^0.8.0;





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

// File: OpenZeppelin/[email protected]/contracts/security/PausableUpgradeable.sol


pragma solidity ^0.8.0;



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

// File: contracts/EasyTrackStorage.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity ^0.8.4;




interface IMiniMeToken {
    function balanceOfAt(address _owner, uint256 _blockNumber) external pure returns (uint256);

    function totalSupplyAt(uint256 _blockNumber) external view returns (uint256);
}

struct Motion {
    uint256 id;
    address evmScriptFactory;
    address creator;
    uint256 duration;
    uint256 startDate;
    uint256 snapshotBlock;
    uint256 objectionsThreshold;
    uint256 objectionsAmount;
    uint256 objectionsAmountPct;
    bytes32 evmScriptHash;
}

/// @author psirex
/// @notice Keeps all variables of the EasyTrack
/// @dev All variables stored in this contract to simplify
/// future upgrades of Easy Track and and minimize the risk of storage collisions.
/// New variables can be added ONLY after already declared variables.
/// Existed variables CAN'T be deleted or reordered
contract EasyTrackStorage is Initializable, PausableUpgradeable, AccessControlUpgradeable {
    // -------------
    // EVENTS
    // -------------
    event MotionDurationChanged(uint256 _motionDuration);
    event MotionsCountLimitChanged(uint256 _newMotionsCountLimit);
    event ObjectionsThresholdChanged(uint256 _newThreshold);

    // -------------
    // ROLES
    // -------------
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 public constant UNPAUSE_ROLE = keccak256("UNPAUSE_ROLE");
    bytes32 public constant CANCEL_ROLE = keccak256("CANCEL_ROLE");

    // ------------
    // CONSTANTS
    // ------------

    /// @notice Upper bound for motionsCountLimit variable.
    uint256 public constant MAX_MOTIONS_LIMIT = 24;

    /// @notice Upper bound for objectionsThreshold variable.
    /// @dev Stored in basis points (1% = 100)
    uint256 public constant MAX_OBJECTIONS_THRESHOLD = 500;

    /// @notice Lower bound for motionDuration variable
    uint256 public constant MIN_MOTION_DURATION = 4 hours;

    // ------------
    // MOTION SETTING VARIABLES
    // ------------

    /// @notice Percent from total supply of governance tokens required to reject motion.
    /// @dev Value stored in basis points: 1% == 100.
    uint256 public objectionsThreshold;

    /// @notice Max count of active motions
    uint256 public motionsCountLimit;

    /// @notice Minimal time required to pass before enacting of motion
    uint256 public motionDuration;

    // ------------
    // EVM SCRIPT FACTORIES VARIABLES
    // ------------

    /// @notice List of allowed EVMScript factories
    address[] public evmScriptFactories;

    // Position of the EVMScript factory in the `evmScriptFactories` array,
    // plus 1 because index 0 means a value is not in the set.
    mapping(address => uint256) internal evmScriptFactoryIndices;

    /// @notice Permissions of current list of allowed EVMScript factories.
    mapping(address => bytes) public evmScriptFactoryPermissions;

    // ------------
    // EASY TRACK VARIABLES
    // ------------

    /// @notice List of active motions
    Motion[] public motions;

    // Id of the lastly created motion
    uint256 internal lastMotionId;

    /// @notice Address of governanceToken which implements IMiniMeToken interface
    IMiniMeToken public governanceToken;

    /// @notice Address of current EVMScriptExecutor
    IEVMScriptExecutor public evmScriptExecutor;

    // Position of the motion in the `motions` array, plus 1
    // because index 0 means a value is not in the set.
    mapping(uint256 => uint256) internal motionIndicesByMotionId;

    /// @notice Stores if motion with given id has been objected from given address.
    mapping(uint256 => mapping(address => bool)) public objections;

    /// @notice Initializes EasyTrackStorage variables with default values and calls initialize methods on base contracts.
    /// @dev This method can be called only once
    function __EasyTrackStorage_init(address _governanceToken, address _admin) public initializer {
        __Pausable_init();
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(PAUSE_ROLE, _admin);
        _setupRole(UNPAUSE_ROLE, _admin);
        _setupRole(CANCEL_ROLE, _admin);

        objectionsThreshold = 50;
        motionsCountLimit = 12;
        motionDuration = MIN_MOTION_DURATION;
        governanceToken = IMiniMeToken(_governanceToken);

        emit ObjectionsThresholdChanged(50);
        emit MotionsCountLimitChanged(12);
        emit MotionDurationChanged(MIN_MOTION_DURATION);
    }
}

// File: contracts/MotionSettings.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity ^0.8.4;


/// @author psirex
/// @notice Provides methods to update motion duration, objections threshold, and limit of active motions of Easy Track
contract MotionSettings is EasyTrackStorage {
    // -------------
    // ERRORS
    // -------------

    string private constant ERROR_VALUE_TOO_SMALL = "VALUE_TOO_SMALL";
    string private constant ERROR_VALUE_TOO_LARGE = "VALUE_TOO_LARGE";

    // ------------------
    // EXTERNAL METHODS
    // ------------------

    /// @notice Sets the minimal time required to pass before enacting of motion
    function setMotionDuration(uint256 _motionDuration) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_motionDuration >= MIN_MOTION_DURATION, ERROR_VALUE_TOO_SMALL);
        motionDuration = _motionDuration;
        emit MotionDurationChanged(_motionDuration);
    }

    /// @notice Sets percent from total supply of governance tokens required to reject motion
    function setObjectionsThreshold(uint256 _objectionsThreshold)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_objectionsThreshold <= MAX_OBJECTIONS_THRESHOLD, ERROR_VALUE_TOO_LARGE);
        objectionsThreshold = _objectionsThreshold;
        emit ObjectionsThresholdChanged(_objectionsThreshold);
    }

    /// @notice Sets max count of active motions.
    function setMotionsCountLimit(uint256 _motionsCountLimit)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_motionsCountLimit < MAX_MOTIONS_LIMIT, ERROR_VALUE_TOO_LARGE);
        motionsCountLimit = _motionsCountLimit;
        emit MotionsCountLimitChanged(_motionsCountLimit);
    }
}

// File: contracts/interfaces/IEVMScriptFactory.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity ^0.8.4;

/// @author psirex
/// @notice Interface which every EVMScript factory used in EasyTrack contract has to implement
interface IEVMScriptFactory {
    function createEVMScript(address _creator, bytes memory _evmScriptCallData)
        external
        returns (bytes memory);
}

// File: contracts/libraries/BytesUtils.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity ^0.8.4;

/// @author psirex
/// @notice Contains methods to extract primitive types from bytes
library BytesUtils {
    function bytes24At(bytes memory data, uint256 location) internal pure returns (bytes24 result) {
        uint256 word = uint256At(data, location);
        assembly {
            result := word
        }
    }

    function addressAt(bytes memory data, uint256 location) internal pure returns (address result) {
        uint256 word = uint256At(data, location);
        assembly {
            result := div(
                and(word, 0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000),
                0x1000000000000000000000000
            )
        }
    }

    function uint32At(bytes memory _data, uint256 _location) internal pure returns (uint32 result) {
        uint256 word = uint256At(_data, _location);

        assembly {
            result := div(
                and(word, 0xffffffff00000000000000000000000000000000000000000000000000000000),
                0x100000000000000000000000000000000000000000000000000000000
            )
        }
    }

    function uint256At(bytes memory data, uint256 location) internal pure returns (uint256 result) {
        assembly {
            result := mload(add(data, add(0x20, location)))
        }
    }
}

// File: contracts/libraries/EVMScriptPermissions.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity ^0.8.4;


/// @author psirex
/// @notice Provides methods to convinient work with permissions bytes
/// @dev Permissions - is a list of tuples (address, bytes4) encoded into a bytes representation.
/// Each tuple (address, bytes4) describes a method allowed to be called by EVMScript
library EVMScriptPermissions {
    using BytesUtils for bytes;

    /// Stores length of one item in permissions.
    uint256 private constant PERMISSION_LENGTH = 24;

    /// @notice Validates that passed EVMScript calls only methods allowed in permissions.
    /// @dev Returns false if provided permissions are invalid (has a wrong length or empty)
    function canExecuteEVMScript(bytes memory _permissions, bytes memory _evmScript)
        internal
        pure
        returns (bool)
    {
        uint256 location = 4; // first 4 bytes reserved for SPEC_ID
        if (!isValidPermissions(_permissions) || _evmScript.length <= location) {
            return false;
        }

        while (location < _evmScript.length) {
            (bytes24 methodToCall, uint32 callDataLength) = _getNextMethodId(_evmScript, location);
            if (!_hasPermission(_permissions, methodToCall)) {
                return false;
            }
            location += PERMISSION_LENGTH + callDataLength;
        }
        return true;
    }

    /// @notice Validates that bytes with permissions not empty and has correct length
    function isValidPermissions(bytes memory _permissions) internal pure returns (bool) {
        return _permissions.length > 0 && _permissions.length % PERMISSION_LENGTH == 0;
    }

    // Retrieves bytes24 which describes tuple (address, bytes4)
    // from EVMScript starting from _location position
    function _getNextMethodId(bytes memory _evmScript, uint256 _location)
        private
        pure
        returns (bytes24, uint32)
    {
        address recipient = _evmScript.addressAt(_location);
        uint32 methodId = _evmScript.uint32At(_location + 24);
        uint32 callDataLength = _evmScript.uint32At(_location + 20);
        return (bytes24(uint192(methodId)) | bytes20(recipient), callDataLength);
    }

    // Validates that passed _methodToCall contained in permissions
    function _hasPermission(bytes memory _permissions, bytes24 _methodToCall)
        private
        pure
        returns (bool)
    {
        uint256 location = 0;
        while (location < _permissions.length) {
            bytes24 permission = _permissions.bytes24At(location);
            if (permission == _methodToCall) {
                return true;
            }
            location += PERMISSION_LENGTH;
        }
        return false;
    }
}

// File: contracts/EVMScriptFactoriesRegistry.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity ^0.8.4;




/// @author psirex
/// @notice Provides methods to add/remove EVMScript factories
/// and contains an internal method for the convenient creation of EVMScripts
contract EVMScriptFactoriesRegistry is EasyTrackStorage {
    using EVMScriptPermissions for bytes;

    // -------------
    // EVENTS
    // -------------

    event EVMScriptFactoryAdded(address indexed _evmScriptFactory, bytes _permissions);
    event EVMScriptFactoryRemoved(address indexed _evmScriptFactory);

    // ------------------
    // EXTERNAL METHODS
    // ------------------

    /// @notice Adds new EVMScript Factory to the list of allowed EVMScript factories with given permissions
    function addEVMScriptFactory(address _evmScriptFactory, bytes memory _permissions)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_permissions.isValidPermissions(), "INVALID_PERMISSIONS");
        require(!_isEVMScriptFactory(_evmScriptFactory), "EVM_SCRIPT_FACTORY_ALREADY_ADDED");
        evmScriptFactories.push(_evmScriptFactory);
        evmScriptFactoryIndices[_evmScriptFactory] = evmScriptFactories.length;
        evmScriptFactoryPermissions[_evmScriptFactory] = _permissions;
        emit EVMScriptFactoryAdded(_evmScriptFactory, _permissions);
    }

    /// @notice Removes EVMScript factory from the list of allowed EVMScript factories
    /// @dev To delete a EVMScript factory from the rewardPrograms array in O(1),
    /// we swap the element to delete with the last one in the array, and then remove
    /// the last element (sometimes called as 'swap and pop').
    function removeEVMScriptFactory(address _evmScriptFactory)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 index = _getEVMScriptFactoryIndex(_evmScriptFactory);
        uint256 lastIndex = evmScriptFactories.length - 1;

        if (index != lastIndex) {
            address lastEVMScriptFactory = evmScriptFactories[lastIndex];
            evmScriptFactories[index] = lastEVMScriptFactory;
            evmScriptFactoryIndices[lastEVMScriptFactory] = index + 1;
        }

        evmScriptFactories.pop();
        delete evmScriptFactoryIndices[_evmScriptFactory];
        delete evmScriptFactoryPermissions[_evmScriptFactory];
        emit EVMScriptFactoryRemoved(_evmScriptFactory);
    }

    /// @notice Returns current list of EVMScript factories
    function getEVMScriptFactories() external view returns (address[] memory) {
        return evmScriptFactories;
    }

    /// @notice Returns if passed address are listed as EVMScript factory in the registry
    function isEVMScriptFactory(address _maybeEVMScriptFactory) external view returns (bool) {
        return _isEVMScriptFactory(_maybeEVMScriptFactory);
    }

    // ------------------
    // INTERNAL METHODS
    // ------------------

    /// @notice Creates EVMScript using given EVMScript factory
    /// @dev Checks permissions of resulting EVMScript and reverts with error
    /// if script tries to call methods not listed in permissions
    function _createEVMScript(
        address _evmScriptFactory,
        address _creator,
        bytes memory _evmScriptCallData
    ) internal returns (bytes memory _evmScript) {
        require(_isEVMScriptFactory(_evmScriptFactory), "EVM_SCRIPT_FACTORY_NOT_FOUND");
        _evmScript = IEVMScriptFactory(_evmScriptFactory).createEVMScript(
            _creator,
            _evmScriptCallData
        );
        bytes memory permissions = evmScriptFactoryPermissions[_evmScriptFactory];
        require(permissions.canExecuteEVMScript(_evmScript), "HAS_NO_PERMISSIONS");
    }

    // ------------------
    // PRIVATE METHODS
    // ------------------

    function _getEVMScriptFactoryIndex(address _evmScriptFactory)
        private
        view
        returns (uint256 _index)
    {
        _index = evmScriptFactoryIndices[_evmScriptFactory];
        require(_index > 0, "EVM_SCRIPT_FACTORY_NOT_FOUND");
        _index -= 1;
    }

    function _isEVMScriptFactory(address _maybeEVMScriptFactory) private view returns (bool) {
        return evmScriptFactoryIndices[_maybeEVMScriptFactory] > 0;
    }
}

// File: OpenZeppelin/[email protected]/contracts/proxy/beacon/IBeacon.sol


pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// File: OpenZeppelin/[email protected]/contracts/utils/Address.sol


pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: OpenZeppelin/[email protected]/contracts/utils/StorageSlot.sol


pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// File: OpenZeppelin/[email protected]/contracts/proxy/ERC1967/ERC1967Upgrade.sol


pragma solidity ^0.8.2;




/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// File: OpenZeppelin/[email protected]/contracts/proxy/utils/UUPSUpgradeable.sol


pragma solidity ^0.8.0;


/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is ERC1967Upgrade {
    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// File: contracts/EasyTrack.sol

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

pragma solidity ^0.8.4;





/// @author psirex
/// @notice Contains main logic of Easy Track
contract EasyTrack is UUPSUpgradeable, MotionSettings, EVMScriptFactoriesRegistry {
    // -------------
    // EVENTS
    // -------------
    event MotionCreated(
        uint256 indexed _motionId,
        address _creator,
        address indexed _evmScriptFactory,
        bytes _evmScriptCallData,
        bytes _evmScript
    );
    event MotionObjected(
        uint256 indexed _motionId,
        address indexed _objector,
        uint256 _weight,
        uint256 _newObjectionsAmount,
        uint256 _newObjectionsAmountPct
    );
    event MotionRejected(uint256 indexed _motionId);
    event MotionCanceled(uint256 indexed _motionId);
    event MotionEnacted(uint256 indexed _motionId);
    event EVMScriptExecutorChanged(address indexed _evmScriptExecutor);

    // -------------
    // ERRORS
    // -------------
    string private constant ERROR_ALREADY_OBJECTED = "ALREADY_OBJECTED";
    string private constant ERROR_NOT_ENOUGH_BALANCE = "NOT_ENOUGH_BALANCE";
    string private constant ERROR_NOT_CREATOR = "NOT_CREATOR";
    string private constant ERROR_MOTION_NOT_PASSED = "MOTION_NOT_PASSED";
    string private constant ERROR_UNEXPECTED_EVM_SCRIPT = "UNEXPECTED_EVM_SCRIPT";
    string private constant ERROR_MOTION_NOT_FOUND = "MOTION_NOT_FOUND";
    string private constant ERROR_MOTIONS_LIMIT_REACHED = "MOTIONS_LIMIT_REACHED";

    // -------------
    // CONSTANTS
    // -------------

    // Stores 100% in basis points
    uint256 internal constant HUNDRED_PERCENT = 10000;

    // ------------------
    // EXTERNAL METHODS
    // ------------------

    /// @notice Creates new motion
    /// @param _evmScriptFactory Address of EVMScript factory registered in Easy Track
    /// @param _evmScriptCallData Encoded call data of EVMScript factory
    /// @return _newMotionId Id of created motion
    function createMotion(address _evmScriptFactory, bytes memory _evmScriptCallData)
        external
        whenNotPaused
        returns (uint256 _newMotionId)
    {
        require(motions.length < motionsCountLimit, ERROR_MOTIONS_LIMIT_REACHED);
        
        bytes memory evmScript =
            _createEVMScript(_evmScriptFactory, msg.sender, _evmScriptCallData);

        Motion storage newMotion = motions.push();
        _newMotionId = ++lastMotionId;

        newMotion.id = _newMotionId;
        newMotion.creator = msg.sender;
        newMotion.startDate = block.timestamp;
        newMotion.snapshotBlock = block.number;
        newMotion.duration = motionDuration;
        newMotion.objectionsThreshold = objectionsThreshold;
        newMotion.evmScriptFactory = _evmScriptFactory;
        newMotion.evmScriptHash = keccak256(evmScript);

        motionIndicesByMotionId[_newMotionId] = motions.length;

        emit MotionCreated(
            _newMotionId,
            msg.sender,
            _evmScriptFactory,
            _evmScriptCallData,
            evmScript
        );
    }

    /// @notice Enacts motion with given id
    /// @param _motionId Id of motion to enact
    /// @param _evmScriptCallData Encoded call data of EVMScript factory. Same as passed on the creation
    /// of motion with the given motion id. Transaction reverts if EVMScript factory call data differs
    function enactMotion(uint256 _motionId, bytes memory _evmScriptCallData)
        external
        whenNotPaused
    {
        Motion storage motion = _getMotion(_motionId);
        require(motion.startDate + motion.duration <= block.timestamp, ERROR_MOTION_NOT_PASSED);

        bytes memory evmScript =
            _createEVMScript(motion.evmScriptFactory, motion.creator, _evmScriptCallData);
        require(motion.evmScriptHash == keccak256(evmScript), ERROR_UNEXPECTED_EVM_SCRIPT);

        evmScriptExecutor.executeEVMScript(evmScript);
        _deleteMotion(_motionId);

        emit MotionEnacted(_motionId);
    }

    /// @notice Submits an objection from `governanceToken` holder.
    /// @param _motionId Id of motion to object
    function objectToMotion(uint256 _motionId) external {
        Motion storage motion = _getMotion(_motionId);
        require(!objections[_motionId][msg.sender], ERROR_ALREADY_OBJECTED);
        objections[_motionId][msg.sender] = true;

        uint256 snapshotBlock = motion.snapshotBlock;
        uint256 objectorBalance = governanceToken.balanceOfAt(msg.sender, snapshotBlock);
        require(objectorBalance > 0, ERROR_NOT_ENOUGH_BALANCE);

        uint256 totalSupply = governanceToken.totalSupplyAt(snapshotBlock);
        uint256 newObjectionsAmount = motion.objectionsAmount + objectorBalance;
        uint256 newObjectionsAmountPct = (HUNDRED_PERCENT * newObjectionsAmount) / totalSupply;

        emit MotionObjected(_motionId, msg.sender, objectorBalance, newObjectionsAmount, newObjectionsAmountPct);

        if (newObjectionsAmountPct < motion.objectionsThreshold) {
            motion.objectionsAmount = newObjectionsAmount;
            motion.objectionsAmountPct = newObjectionsAmountPct;
        } else {
            _deleteMotion(_motionId);
            emit MotionRejected(_motionId);
        }
    }

    /// @notice Cancels motion with given id
    /// @param _motionId Id of motion to cancel
    function cancelMotion(uint256 _motionId) external {
        Motion storage motion = _getMotion(_motionId);
        require(motion.creator == msg.sender, ERROR_NOT_CREATOR);
        _deleteMotion(_motionId);
        emit MotionCanceled(_motionId);
    }

    /// @notice Cancels all motions with given ids
    /// @param _motionIds Ids of motions to cancel
    function cancelMotions(uint256[] memory _motionIds) external onlyRole(CANCEL_ROLE) {
        for (uint256 i = 0; i < _motionIds.length; ++i) {
            if (motionIndicesByMotionId[_motionIds[i]] > 0) {
                _deleteMotion(_motionIds[i]);
                emit MotionCanceled(_motionIds[i]);
            }
        }
    }

    /// @notice Cancels all active motions
    function cancelAllMotions() external onlyRole(CANCEL_ROLE) {
        uint256 motionsCount = motions.length;
        while (motionsCount > 0) {
            motionsCount -= 1;
            uint256 motionId = motions[motionsCount].id;
            _deleteMotion(motionId);
            emit MotionCanceled(motionId);
        }
    }

    /// @notice Sets new EVMScriptExecutor
    /// @param _evmScriptExecutor Address of new EVMScriptExecutor
    function setEVMScriptExecutor(address _evmScriptExecutor)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        evmScriptExecutor = IEVMScriptExecutor(_evmScriptExecutor);
        emit EVMScriptExecutorChanged(_evmScriptExecutor);
    }

    /// @notice Pauses Easy Track if it isn't paused.
    /// Paused Easy Track can't create and enact motions
    function pause() external whenNotPaused onlyRole(PAUSE_ROLE) {
        _pause();
    }

    /// @notice Unpauses Easy Track if it is paused
    function unpause() external whenPaused onlyRole(UNPAUSE_ROLE) {
        _unpause();
    }

    /// @notice Returns if an _objector can submit an objection to motion with id equals to _motionId or not
    /// @param _motionId Id of motion to check opportunity to object
    /// @param _objector Address of objector
    function canObjectToMotion(uint256 _motionId, address _objector) external view returns (bool) {
        Motion storage motion = _getMotion(_motionId);
        uint256 balance = governanceToken.balanceOfAt(_objector, motion.snapshotBlock);
        return balance > 0 && !objections[_motionId][_objector];
    }

    /// @notice Returns list of active motions
    function getMotions() external view returns (Motion[] memory) {
        return motions;
    }

    /// @notice Returns motion with the given id
    /// @param _motionId Id of motion to retrieve
    function getMotion(uint256 _motionId) external view returns (Motion memory) {
        return _getMotion(_motionId);
    }

    // -------
    // INTERNAL METHODS
    // -------

    // Override for UUPSUpgradable method. Allows update of contract only to
    // the address with role 'DEFAULT_ADMIN_ROLE'
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    // -------
    // PRIVATE METHODS
    // -------

    // Removes motion from list of active moitons
    // To delete a motion from the moitons array in O(1), we swap the element to delete with the last one in
    // the array, and then remove the last element (sometimes called as 'swap and pop').
    function _deleteMotion(uint256 _motionId) private {
        uint256 index = motionIndicesByMotionId[_motionId] - 1;
        uint256 lastIndex = motions.length - 1;

        if (index != lastIndex) {
            Motion storage lastMotion = motions[lastIndex];
            motions[index] = lastMotion;
            motionIndicesByMotionId[lastMotion.id] = index + 1;
        }

        motions.pop();
        delete motionIndicesByMotionId[_motionId];
    }

    // Returns motion with given id if it exists
    function _getMotion(uint256 _motionId) private view returns (Motion storage) {
        uint256 _motionIndex = motionIndicesByMotionId[_motionId];
        require(_motionIndex > 0, ERROR_MOTION_NOT_FOUND);
        return motions[_motionIndex - 1];
    }
}