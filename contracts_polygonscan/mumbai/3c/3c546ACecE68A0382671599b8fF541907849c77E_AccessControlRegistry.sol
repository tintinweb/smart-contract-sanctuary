// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./RoleDeriver.sol";
import "./interfaces/IAccessControlRegistry.sol";

/// @title Contract that allows users to manage independent, tree-shaped access
/// control tables
/// @notice Multiple contracts can refer to this contract to check if their
/// users have granted accounts specific roles. Therefore, it aims to keep all
/// access control roles of its users in this single contract.
/// @dev Each user is called a "manager", and is the only member of their root
/// role. Starting from this root role, they can create an arbitrary tree of
/// roles and grant these to accounts. Each role has a description, and roles
/// adminned by the same role cannot have the same description.
contract AccessControlRegistry is
    AccessControl,
    RoleDeriver,
    IAccessControlRegistry
{
    /// @notice Initializes the manager by initializing its root role and
    /// granting it to them
    /// @dev Anyone can initialize a manager. An uninitialized manager
    /// attempting to initialize a role will be initialized automatically.
    /// Once a manager is initialized, subsequent initializations have no
    /// effect.
    /// @param manager Manager address to be initialized
    function initializeManager(address manager) public override {
        bytes32 rootRole = deriveRootRole(manager);
        if (!hasRole(rootRole, manager)) {
            _setupRole(rootRole, manager);
            emit InitializedManager(rootRole, manager);
        }
    }

    /// @notice Called for the account to renounce the role
    /// @dev Overriden to disallow managers to renounce their root roles
    /// @param role Role to be renounced
    /// @param account Account to renounce the role
    function renounceRole(bytes32 role, address account)
        public
        override(AccessControl, IAccessControl)
    {
        require(
            role != deriveRootRole(account),
            "role is root role of account"
        );
        AccessControl.renounceRole(role, account);
    }

    /// @notice Initializes a role, which includes setting its admin and
    /// granting it to the sender
    /// @dev If the sender should not have the initialized role, they should
    /// explicitly renounce it after initializing it.
    /// Once a role is initialized, subsequent initialization have no effect,
    /// other than granting the role to the sender.
    /// The sender must be a member of `adminRole`.
    /// If the sender is an uninitialized manager that is initializing a role
    /// directly under their root role, manager initialization will happen
    /// automatically, which will grant the sender `adminRole` and allow them
    /// to initialize the role.
    /// @param adminRole Admin role to be assigned to the initialized role
    /// @param description Human-readable description of the initialized role
    /// @return role Initialized role
    function initializeRole(bytes32 adminRole, string calldata description)
        public
        override
        returns (bytes32 role)
    {
        role = deriveRole(adminRole, description);
        // AccessControl roles have `DEFAULT_ADMIN_ROLE` (i.e., `bytes32(0)`)
        // as their `adminRole` by default. No account in AccessControlRegistry
        // can possibly have that role, which means all initialized roles will
        // have non-default admin roles, and vice versa.
        if (getRoleAdmin(role) == DEFAULT_ADMIN_ROLE) {
            // If the role to be initialized is adminned by the root role and
            // the respective manager is not initialized yet, we do it here so
            // that the manager can set up their entire configuration with a
            // single transaction. See the tests for examples.
            if (adminRole == deriveRootRole(_msgSender())) {
                initializeManager(_msgSender());
            }
            _setRoleAdmin(role, adminRole);
            emit InitializedRole(role, adminRole, description, _msgSender());
        }
        grantRole(role, _msgSender());
    }

    /// @notice Initializes roles and grants them to the respective accounts
    /// @dev Each initialized role is granted to the respective account. If you
    /// do not want to grant the role to an additional account, you can pass
    /// the sender address here (as the sender will already be granted the
    /// role so this would have no effect).
    /// Lengths of the arguments must be equal, and less than 33
    /// @param adminRoles Admin roles to be assigned to the initialized roles
    /// @param descriptions Human-readable descriptions of the initialized
    /// roles
    /// @param accounts Accounts the initialized roles will be granted to
    /// @return roles Initialized roles
    function initializeAndGrantRoles(
        bytes32[] calldata adminRoles,
        string[] calldata descriptions,
        address[] calldata accounts
    ) external override returns (bytes32[] memory roles) {
        uint256 argumentLength = adminRoles.length;
        require(
            argumentLength == descriptions.length &&
                argumentLength == accounts.length,
            "Argument length mismatch"
        );
        require(argumentLength <= 32, "Arguments too long");
        roles = new bytes32[](argumentLength);
        for (uint256 ind = 0; ind < argumentLength; ind++) {
            roles[ind] = initializeRole(adminRoles[ind], descriptions[ind]);
            grantRole(roles[ind], accounts[ind]);
        }
    }

    /// @notice Derives the root role of the manager
    /// @param manager Manager address
    /// @return rootRole Root role
    function deriveRootRole(address manager)
        public
        pure
        override
        returns (bytes32 rootRole)
    {
        rootRole = _deriveRootRole(manager);
    }

    /// @notice Derives the role using its admin role and description
    /// @dev This implies that roles adminned by the same role cannot have the
    /// same description
    /// @param adminRole Admin role
    /// @param description Human-readable description of the role
    /// @return role Role
    function deriveRole(bytes32 adminRole, string calldata description)
        public
        pure
        override
        returns (bytes32 role)
    {
        role = _deriveRole(adminRole, description);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title Contract that implements the AccessControlRegistry role derivation
/// logic
/// @notice If a contract interfaces with AccessControlRegistry and needs to
/// derive roles, it should inherit this contract instead of re-implementing
/// the logic
contract RoleDeriver {
    /// @notice Derives the root role of the manager
    /// @param manager Manager address
    /// @return rootRole Root role
    function _deriveRootRole(address manager)
        internal
        pure
        returns (bytes32 rootRole)
    {
        rootRole = keccak256(abi.encodePacked(manager));
    }

    /// @notice Derives the role using its admin role and description
    /// @dev This implies that roles adminned by the same role cannot have the
    /// same description
    /// @param adminRole Admin role
    /// @param description Human-readable description of the role
    /// @return role Role
    function _deriveRole(bytes32 adminRole, string memory description)
        internal
        pure
        returns (bytes32 role)
    {
        role = _deriveRole(adminRole, keccak256(abi.encodePacked(description)));
    }

    /// @notice Derives the role using its admin role and description hash
    /// @dev This implies that roles adminned by the same role cannot have the
    /// same description
    /// @param adminRole Admin role
    /// @param descriptionHash Hash of the human-readable description of the
    /// role
    /// @return role Role
    function _deriveRole(bytes32 adminRole, bytes32 descriptionHash)
        internal
        pure
        returns (bytes32 role)
    {
        role = keccak256(abi.encodePacked(adminRole, descriptionHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IAccessControlRegistry is IAccessControl {
    event InitializedManager(bytes32 indexed rootRole, address indexed manager);

    event InitializedRole(
        bytes32 indexed role,
        bytes32 indexed adminRole,
        string description,
        address sender
    );

    function initializeManager(address manager) external;

    function initializeRole(bytes32 adminRole, string calldata description)
        external
        returns (bytes32 role);

    function initializeAndGrantRoles(
        bytes32[] calldata adminRoles,
        string[] calldata descriptions,
        address[] calldata accounts
    ) external returns (bytes32[] memory roles);

    function deriveRootRole(address manager)
        external
        pure
        returns (bytes32 rootRole);

    function deriveRole(bytes32 adminRole, string calldata description)
        external
        pure
        returns (bytes32 role);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
     * bearer except when using {AccessControl-_setupRole}.
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
interface IERC165 {
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