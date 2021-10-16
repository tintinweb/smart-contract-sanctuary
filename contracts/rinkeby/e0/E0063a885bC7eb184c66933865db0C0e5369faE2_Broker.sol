// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
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

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IBroker.sol";
import "./libraries/Proposals.sol";
import "./libraries/Sales.sol";
import {IIssuer} from "../issuer/IIssuer.sol";
import "../token/sIERC20.sol";
import "../vault/IVault.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title Broker
 * @notice Handles the buyout of fractionalized NFTs.
 */
contract Broker is Context, AccessControlEnumerable, IBroker {
    using Address for address payable;
    using Proposals for Proposals.Proposal;
    using Sales for Sales.Sale;

    bytes32 public constant ESCAPE_ROLE = keccak256("ESCAPE_ROLE");
    bytes32 public constant REGISTER_ROLE = keccak256("REGISTER_ROLE");
    uint256 public constant MINIMUM_TIMELOCK = 1 weeks;
    uint256 public constant DECIMALS = 1e18; // !IMPORTANT: is the same as Issuer.DECIMALS
    uint256 public constant HUNDRED = 1e20;

    IVault private immutable _vault;
    IIssuer private immutable _issuer;
    address private _bank;
    uint256 private _protocolFee;
    mapping(sIERC20 => Sales.Sale) private _sales;

    constructor(
        IVault vault_,
        IIssuer issuer_,
        address bank_,
        uint256 protocolFee_
    ) {
        require(address(vault_) != address(0), "Broker: vault cannot be the zero address");
        require(address(issuer_) != address(0), "Broker: issuer cannot be the zero address");
        require(address(bank_) != address(0), "Broker: bank cannot be the zero address");
        require(protocolFee_ < HUNDRED, "Broker: protocol fee must be inferior to 100%");

        _vault = vault_;
        _issuer = issuer_;
        _setBank(bank_);
        _setProtocolFee(protocolFee_);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @notice Put the NFT pegged to `sERC20` on sale.
     * @dev - We do not check neither that `sERC20` is unregistered nor that it actually is an sERC20 to save gas.
     *      - Indeed, only trusted templates, registering sERC20s out of actual NFT fractionalizations, are supposed to be granted REGISTER_ROLE.
     *      - Other parameters are checked because they are passed by users and forwarded unchecked by templates.
     * @param sERC20 The sERC20 whose pegged NFT is put on sale.
     * @param guardian The account authorized to enable flash buyout and accept / reject proposals otherwise.
     * @param reserve The reserve price above which the NFT can be bought out.
     * @param multiplier The sale's buyout multiplier [expressed with 1e18 decimals].
     * @param timelock The period of time after which the sale opens [in seconds].
     * @param flash True if flash buyout is enabled, false otherwise.
     * @param escape True if spectre's multisig is allowed to escape sERC20's pegged NFT, false otherwise.
     */
    function register(
        sIERC20 sERC20,
        address guardian,
        uint256 reserve,
        uint256 multiplier,
        uint256 timelock,
        bool flash,
        bool escape
    ) external override {
        Sales.Sale storage sale = _sales[sERC20];

        require(hasRole(REGISTER_ROLE, _msgSender()), "Broker: must have REGISTER_ROLE to register");
        require(guardian != address(0), "Broker: guardian cannot be the zero address");
        require(timelock >= MINIMUM_TIMELOCK, "Broker: invalid timelock");

        sale._state = Sales.State.Pending;
        sale.guardian = guardian;
        sale.reserve = reserve;
        sale.multiplier = multiplier;
        sale.opening = block.timestamp + timelock;

        emit Register(sERC20, guardian, reserve, multiplier, block.timestamp + timelock);

        if (flash) _enableFlashBuyout(sERC20, sale);
        if (escape) _enableEscape(sERC20, sale);
    }

    /**
     * @notice Buyout the NFT pegged to `sERC20`.
     * @dev This function requires flash buyout to be enabled.
     * @param sERC20 The sERC20 whose pegged NFT is boughtout.
     */
    function buyout(sIERC20 sERC20) external payable override {
        Sales.Sale storage sale = _sales[sERC20];

        require(sale.state() == Sales.State.Opened, "Broker: invalid sale state");
        require(sale.flash, "Broker: flash buyout is disabled");

        address buyer = _msgSender();
        (uint256 value, uint256 collateral) = _priceOfFor(sERC20, sale, buyer);

        require(msg.value >= value, "Broker: insufficient value");

        _buyout(sERC20, sale, buyer, msg.value, collateral, false);
    }

    /**
     * @notice Create a proposal to buyout the NFT pegged to `sERC20`.
     * @param sERC20 The sERC20 whose pegged NFT is proposed to be bought out.
     * @param lifespan The lifespan of the proposal [in seconds].
     */
    function createProposal(sIERC20 sERC20, uint256 lifespan) external payable override returns (uint256) {
        Sales.Sale storage sale = _sales[sERC20];

        require(sale.state() == Sales.State.Opened, "Broker: invalid sale state");
        require(!sale.flash, "Broker: flash buyout is enabled");

        address buyer = _msgSender();
        (uint256 value, uint256 collateral) = _priceOfFor(sERC20, sale, buyer);

        require(msg.value >= value, "Broker: insufficient value");

        if (collateral > 0) sERC20.transferFrom(buyer, address(this), collateral);

        uint256 proposalId = sale.nbOfProposals++;
        uint256 expiration = lifespan == 0 ? 0 : block.timestamp + lifespan;
        sale.proposals[proposalId] = Proposals.Proposal({
            _state: Proposals.State.Pending,
            buyer: buyer,
            value: msg.value,
            collateral: collateral,
            expiration: expiration
        });

        emit CreateProposal(sERC20, proposalId, buyer, msg.value, collateral, expiration);

        return proposalId;
    }

    /**
     * @notice Accept proposal #`proposalId` to buyout the NFT pegged to `sERC20`.
     * @param sERC20 The sERC20 whose pegged NFT was proposed to be bought out.
     * @param proposalId The id of the buyout proposal.
     */
    function acceptProposal(sIERC20 sERC20, uint256 proposalId) external override {
        Sales.Sale storage sale = _sales[sERC20];
        Proposals.Proposal storage proposal = sale.proposals[proposalId];

        require(_msgSender() == sale.guardian, "Broker: must be sale's guardian to accept proposal");
        require(sale.state() == Sales.State.Opened, "Broker: invalid sale state");
        require(proposal.state() == Proposals.State.Pending, "Broker: invalid proposal state");
        require(!sale.flash, "Broker: flash buyout is enabled");

        proposal._state = Proposals.State.Accepted;

        emit AcceptProposal(sERC20, proposalId);

        _buyout(sERC20, sale, proposal.buyer, proposal.value, proposal.collateral, true);
    }

    /**
     * @notice Reject proposal #`proposalId` to buyout the NFT pegged to `sERC20`.
     * @dev This function is open to re-entrancy for it would be harmless.
     * @param sERC20 The sERC20 whose pegged NFT was proposed to be bought out.
     * @param proposalId The id of the buyout proposal.
     */
    function rejectProposal(sIERC20 sERC20, uint256 proposalId) external override {
        Sales.Sale storage sale = _sales[sERC20];
        Proposals.Proposal storage proposal = sale.proposals[proposalId];
        Proposals.State state = proposal.state();

        require(_msgSender() == sale.guardian, "Broker: must be sale's guardian to reject proposal");
        require(state == Proposals.State.Pending || state == Proposals.State.Lapsed, "Broker: invalid proposal state");

        address buyer = proposal.buyer;
        proposal._state = Proposals.State.Rejected;
        sERC20.transfer(buyer, proposal.collateral);
        payable(buyer).sendValue(proposal.value);

        emit RejectProposal(sERC20, proposalId);
    }

    /**
     * @notice Withdraw proposal #`proposalId` to buyout the NFT pegged to `sERC20`.
     * @dev This function is open to re-entrancy for it would be harmless.
     * @param sERC20 The sERC20 whose pegged NFT was proposed to be bought out.
     * @param proposalId The id of the buyout proposal.
     */
    function withdrawProposal(sIERC20 sERC20, uint256 proposalId) external override {
        Sales.Sale storage sale = _sales[sERC20];
        Proposals.Proposal storage proposal = sale.proposals[proposalId];
        Proposals.State state = proposal.state();

        require(_msgSender() == proposal.buyer, "Broker: must be proposal's buyer to withdraw proposal");
        require(state == Proposals.State.Pending || state == Proposals.State.Lapsed, "Broker: invalid proposal state");

        address buyer = proposal.buyer;
        proposal._state = Proposals.State.Withdrawn;
        sERC20.transfer(buyer, proposal.collateral);
        payable(buyer).sendValue(proposal.value);

        emit WithdrawProposal(sERC20, proposalId);
    }

    /**
     * @notice Claim shares of the buyout of the NFT pegged to `sERC20`.
     * @dev This function is open to re-entrancy for it would be harmless.
     * @param sERC20 The sERC20 whose buyout shares are claimed.
     */
    function claim(sIERC20 sERC20) external override {
        Sales.Sale storage sale = _sales[sERC20];
        address holder = _msgSender();
        uint256 balance = sERC20.balanceOf(holder);

        require(sale.state() == Sales.State.Closed, "Broker: invalid sale state");
        require(balance > 0, "Broker: nothing to claim");

        uint256 value = (sale.stock * balance) / sERC20.totalSupply();
        sale.stock -= value;
        sERC20.burnFrom(holder, balance);
        payable(holder).sendValue(value);

        emit Claim(sERC20, holder, value, balance);
    }

    /**
     * @notice Enable flash buyout for the NFT pegged to `sERC20`.
     * @param sERC20 The sERC20 whose pegged NFT is to be offered to flash buyout.
     */
    function enableFlashBuyout(sIERC20 sERC20) external override {
        Sales.Sale storage sale = _sales[sERC20];
        Sales.State state = sale.state();

        require(_msgSender() == sale.guardian, "Broker: must be sale's guardian to enable flash buyout");
        require(state == Sales.State.Pending || state == Sales.State.Opened, "Broker: invalid sale state");
        require(!sale.flash, "Broker: flash buyout already enabled");

        _enableFlashBuyout(sERC20, sale);
    }

    /**
     * @notice Enable escape for the NFT pegged to `sERC20`.
     * @param sERC20 The sERC20 whose pegged NFT is to be made escapable.
     */
    function enableEscape(sIERC20 sERC20) external override {
        Sales.Sale storage sale = _sales[sERC20];
        Sales.State state = sale.state();

        require(_msgSender() == sale.guardian, "Broker: must be sale's guardian to enable escape");
        require(state == Sales.State.Pending || state == Sales.State.Opened, "Broker: invalid sale state");
        require(!sale.escape, "Broker: escape already enabled");

        _enableEscape(sERC20, sale);
    }

    /**
     * @notice Disable escape for the NFT pegged to `sERC20`.
     * @param sERC20 The sERC20 whose pegged NFT is to be made un-escapable.
     */
    function disableEscape(sIERC20 sERC20) external override {
        Sales.Sale storage sale = _sales[sERC20];
        Sales.State state = sale.state();

        require(_msgSender() == sale.guardian, "Broker: must be sale's guardian to disable escape");
        require(state == Sales.State.Pending || state == Sales.State.Opened, "Broker: invalid sale state");
        require(sale.escape, "Broker: escape already disabled");

        _disableEscape(sERC20, sale);
    }

    function setBank(address bank_) external override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Broker: must have DEFAULT_ADMIN_ROLE to set bank");
        require(bank_ != address(0), "Broker: bank cannot be the zero address");

        _setBank(bank_);
    }

    function setProtocolFee(uint256 protocolFee_) external override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Broker: must have DEFAULT_ADMIN_ROLE to set protocol fee");
        require(protocolFee_ < HUNDRED, "Broker: protocol fee must be inferior to 100%");

        _setProtocolFee(protocolFee_);
    }

    /**
     * @notice Transfer all the NFTs pegged to `sERC20s `to `beneficiaries` with `datas` as ERC721#safeTransferFrom callback datas.
     * @dev This function is only meant to be used in case of an emergency or upgrade to transfer NFTs to a safer or up-to-date place.
     * @param sERC20s The sERC20s whose pegged NFTs are transferred.
     * @param beneficiaries The addresses escaped NFTs are transferred to.
     * @param datas The ERC721#transfer callback datas.
     */
    function _escape_(
        sIERC20[] calldata sERC20s,
        address[] calldata beneficiaries,
        bytes[] calldata datas
    ) external override {
        require(hasRole(ESCAPE_ROLE, _msgSender()), "Broker: must have ESCAPE_ROLE to escape NFTs");
        require(sERC20s.length == beneficiaries.length && sERC20s.length == datas.length, "Broker: parameters lengths mismatch");

        for (uint256 i = 0; i < sERC20s.length; i++) {
            require(_sales[sERC20s[i]].escape, "Broker: escape is disabled");

            _vault.unlock(sERC20s[i], beneficiaries[i], datas[i]);

            emit Escape(sERC20s[i], beneficiaries[i], datas[i]);
        }
    }

    /**
     * @notice Return the broker's vault.
     */
    function vault() public view override returns (IVault) {
        return _vault;
    }

    /**
     * @notice Return the broker's issuer.
     */
    function issuer() public view override returns (IIssuer) {
        return _issuer;
    }

    /**
     * @notice Return the broker's bank.
     */
    function bank() public view override returns (address) {
        return _bank;
    }

    /**
     * @notice Return the broker's protocol fee.
     */
    function protocolFee() public view override returns (uint256) {
        return _protocolFee;
    }

    /**
     * @notice Return what it costs for `buyer` to buyout the NFT pegged to `sERC20`.
     */
    function priceOfFor(sIERC20 sERC20, address buyer) public view override returns (uint256 value, uint256 collateral) {
        return _priceOfFor(sERC20, _sales[sERC20], buyer);
    }

    /**
     * @notice Return the sale of the NFT pegged to `sERC20`.
     */
    function saleOf(sIERC20 sERC20)
        public
        view
        override
        returns (
            Sales.State state,
            address guardian,
            uint256 reserve,
            uint256 multiplier,
            uint256 opening,
            uint256 stock,
            uint256 nbOfProposals,
            bool flash,
            bool escape
        )
    {
        Sales.Sale storage sale = _sales[sERC20];

        state = sale.state();
        guardian = sale.guardian;
        reserve = sale.reserve;
        multiplier = sale.multiplier;
        opening = sale.opening;
        stock = sale.stock;
        nbOfProposals = sale.nbOfProposals;
        flash = sale.flash;
        escape = sale.escape;
    }

    /**
     * @notice Return the proposal #`proposalId` to buyout the NFT pegged to `sERC20`.
     */
    function proposalFor(sIERC20 sERC20, uint256 proposalId)
        public
        view
        override
        returns (
            Proposals.State state,
            address buyer,
            uint256 value,
            uint256 collateral,
            uint256 expiration
        )
    {
        Proposals.Proposal storage proposal = _sales[sERC20].proposals[proposalId];

        state = proposal.state();
        buyer = proposal.buyer;
        value = proposal.value;
        collateral = proposal.collateral;
        expiration = proposal.expiration;
    }

    function _buyout(
        sIERC20 sERC20,
        Sales.Sale storage sale,
        address buyer,
        uint256 value,
        uint256 collateral,
        bool locked
    ) private {
        uint256 fee = (value * _protocolFee) / HUNDRED;

        sale._state = Sales.State.Closed;
        sale.stock = value - fee;

        _issuer.close(sERC20);

        if (collateral > 0) {
            if (locked) sERC20.burn(collateral);
            else sERC20.burnFrom(buyer, collateral);
        }

        _vault.unlock(sERC20, buyer, "");
        if (fee > 0) payable(_bank).sendValue(fee);

        emit Buyout(sERC20, buyer, value, collateral, fee);
    }

    function _enableFlashBuyout(sIERC20 sERC20, Sales.Sale storage sale) private {
        sale.flash = true;

        emit EnableFlashBuyout(sERC20);
    }

    function _enableEscape(sIERC20 sERC20, Sales.Sale storage sale) private {
        sale.escape = true;

        emit EnableEscape(sERC20);
    }

    function _disableEscape(sIERC20 sERC20, Sales.Sale storage sale) private {
        sale.escape = false;

        emit DisableEscape(sERC20);
    }

    function _setBank(address bank_) private {
        _bank = bank_;

        emit SetBank(bank_);
    }

    function _setProtocolFee(uint256 protocolFee_) private {
        _protocolFee = protocolFee_;

        emit SetProtocolFee(protocolFee_);
    }

    function _priceOfFor(
        sIERC20 sERC20,
        Sales.Sale storage sale,
        address buyer
    ) private view returns (uint256 value, uint256 collateral) {
        collateral = sERC20.balanceOf(buyer);
        uint256 supply = sERC20.totalSupply();
        uint256 marketValue = (((_issuer.twapOf(sERC20, IIssuer.TwapKind.ETH) * supply) / DECIMALS) * sale.multiplier) / DECIMALS;
        uint256 reserve = sale.reserve;
        uint256 rawValue = reserve >= marketValue ? reserve : marketValue;

        value = supply > 0 ? (rawValue * (DECIMALS - (collateral * DECIMALS) / supply)) / DECIMALS : rawValue;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./libraries/Sales.sol";
import {IIssuer} from "../issuer/IIssuer.sol";
import "../token/sIERC20.sol";
import "../vault/IVault.sol";

interface IBroker {
    event Register(sIERC20 indexed sERC20, address indexed guardian, uint256 reserve, uint256 multiplier, uint256 opening);
    event CreateProposal(sIERC20 indexed sERC20, uint256 indexed proposalId, address indexed buyer, uint256 value, uint256 collateral, uint256 expiration);
    event AcceptProposal(sIERC20 indexed sERC20, uint256 indexed proposalId);
    event RejectProposal(sIERC20 indexed sERC20, uint256 indexed proposalId);
    event WithdrawProposal(sIERC20 indexed sERC20, uint256 indexed proposalId);
    event Claim(sIERC20 indexed sERC20, address indexed holder, uint256 value, uint256 collateral);
    event Buyout(sIERC20 indexed sERC20, address indexed buyer, uint256 value, uint256 collateral, uint256 fee);
    event EnableFlashBuyout(sIERC20 indexed sERC20);
    event EnableEscape(sIERC20 indexed sERC20);
    event DisableEscape(sIERC20 indexed sERC20);
    event SetBank(address bank);
    event SetProtocolFee(uint256 protocolFee);
    event Escape(sIERC20 indexed sERC20, address indexed beneficiary, bytes data);

    function register(
        sIERC20 sERC20,
        address guardian,
        uint256 minimum,
        uint256 multiplier,
        uint256 timelock,
        bool flash,
        bool escape
    ) external;

    function buyout(sIERC20 sERC20) external payable;

    function createProposal(sIERC20 sERC20, uint256 lifespan) external payable returns (uint256);

    function acceptProposal(sIERC20 sERC20, uint256 proposalId) external;

    function rejectProposal(sIERC20 sERC20, uint256 proposalId) external;

    function withdrawProposal(sIERC20 sERC20, uint256 proposalId) external;

    function claim(sIERC20 sERC20) external;

    function enableFlashBuyout(sIERC20 sERC20) external;

    function enableEscape(sIERC20 sERC20) external;

    function disableEscape(sIERC20 sERC20) external;

    function setBank(address bank_) external;

    function setProtocolFee(uint256 protocolFee_) external;

    function _escape_(
        sIERC20[] calldata sERC20s,
        address[] calldata beneficiaries,
        bytes[] calldata datas
    ) external;

    function vault() external view returns (IVault);

    function issuer() external view returns (IIssuer);

    function bank() external view returns (address);

    function protocolFee() external view returns (uint256);

    function priceOfFor(sIERC20 sERC20, address buyer) external view returns (uint256 value, uint256 collateral);

    function saleOf(sIERC20 sERC20)
        external
        view
        returns (
            Sales.State state,
            address guardian,
            uint256 reserve,
            uint256 multiplier,
            uint256 opening,
            uint256 stock,
            uint256 nbOfProposals,
            bool flash,
            bool escape
        );

    function proposalFor(sIERC20 sERC20, uint256 proposalId)
        external
        view
        returns (
            Proposals.State state,
            address buyer,
            uint256 value,
            uint256 collateral,
            uint256 expiration
        );
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library Proposals {
    enum State {
        Null,
        Pending,
        Accepted,
        Rejected,
        Lapsed,
        Withdrawn
    }

    struct Proposal {
        State _state;
        address buyer;
        uint256 value;
        uint256 collateral;
        uint256 expiration;
    }

    function state(Proposal storage proposal) internal view returns (State) {
        State _state = proposal._state;
        uint256 expiration = proposal.expiration;

        if (_state == State.Pending && expiration != 0 && block.timestamp >= expiration) {
            return State.Lapsed;
        } else {
            return _state;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Proposals.sol";

library Sales {
    enum State {
        Null,
        Pending,
        Opened,
        Closed
    }

    struct Sale {
        State _state;
        address guardian;
        uint256 reserve;
        uint256 multiplier;
        uint256 opening;
        uint256 stock;
        uint256 nbOfProposals;
        mapping(uint256 => Proposals.Proposal) proposals;
        bool flash;
        bool escape;
    }

    function state(Sale storage sale) internal view returns (State) {
        State _state = sale._state;

        if (_state == State.Pending && block.timestamp >= sale.opening) {
            return State.Opened;
        } else {
            return _state;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./interfaces/IBalancer.sol";
import "./interfaces/IFractionalizationBootstrappingPool.sol";
import "./interfaces/IFractionalizationBootstrappingPoolFactory.sol";
import "./libraries/Issuances.sol";
import "../token/sIERC20.sol";

interface IIssuer {
    enum TwapKind {
        ETH,
        sERC20
    }

    event Register(
        sIERC20 indexed sERC20,
        address indexed guardian,
        IFractionalizationBootstrappingPool pool,
        bytes32 poolId,
        uint256 sMaxNormalizedWeight,
        uint256 sMinNormalizedWeight,
        uint256 swapFeePercentage,
        uint256 reserve,
        uint256 allocation,
        uint256 fee
    );
    event Issue(sIERC20 indexed sERC20, address indexed recipient, uint256 value, uint256 amount);
    event CreateProposal(sIERC20 indexed sERC20, uint256 indexed proposalId, address indexed buyer, uint256 value, uint256 price, uint256 expiration);
    event AcceptProposal(sIERC20 indexed sERC20, uint256 indexed proposalId);
    event RejectProposal(sIERC20 indexed sERC20, uint256 indexed proposalId);
    event WithdrawProposal(sIERC20 indexed sERC20, uint256 indexed proposalId);
    event Close(sIERC20);
    event EnableFlashIssuance(sIERC20 indexed sERC20);
    event SetBank(address bank);
    event SetProtocolFee(uint256 protocolFee);

    function register(
        sIERC20 sERC20,
        address guardian,
        uint256 sMaxNormalizedWeight,
        uint256 sMinNormalizedWeight,
        uint256 swapFeePercentage,
        uint256 reserve,
        uint256 allocation,
        uint256 fee,
        bool flash
    ) external;

    function issue(sIERC20 sERC20, uint256 expected) external payable;

    function createProposal(
        sIERC20 sERC20,
        uint256 amount,
        uint256 lifespan
    ) external payable returns (uint256);

    function acceptProposal(sIERC20 sERC20, uint256 proposalId) external;

    function rejectProposal(sIERC20 sERC20, uint256 proposalId) external;

    function withdrawProposal(sIERC20 sERC20, uint256 proposalId) external;

    function close(sIERC20 sERC20) external;

    function enableFlashIssuance(sIERC20 sERC20) external;

    function setBank(address bank_) external;

    function setProtocolFee(uint256 protocolFee_) external;

    function vault() external view returns (IBVault);

    function poolFactory() external view returns (IFractionalizationBootstrappingPoolFactory);

    function splitter() external view returns (address);

    function WETH() external view returns (address);

    function bank() external view returns (address);

    function protocolFee() external view returns (uint256);

    function issuanceOf(sIERC20 sERC20)
        external
        view
        returns (
            Issuances.State state,
            address guardian,
            IFractionalizationBootstrappingPool pool,
            bytes32 poolId,
            uint256 reserve,
            uint256 allocation,
            uint256 fee,
            uint256 nbOfProposals,
            bool flash,
            bool sERC20IsToken0
        );

    function proposalFor(sIERC20 sERC20, uint256 proposalId)
        external
        view
        returns (
            Proposals.State state,
            address buyer,
            uint256 value,
            uint256 price,
            uint256 expiration
        );

    function priceOf(sIERC20 sERC20) external view returns (uint256);

    function twapOf(sIERC20 sERC20, TwapKind Kind) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAsset {}

interface IPriceOracle {
    enum Variable {
        PAIR_PRICE,
        BPT_PRICE,
        INVARIANT
    }

    struct OracleAccumulatorQuery {
        Variable variable;
        uint256 ago;
    }

    struct OracleAverageQuery {
        Variable variable;
        uint256 secs;
        uint256 ago;
    }

    function getTimeWeightedAverage(OracleAverageQuery[] memory queries) external view returns (uint256[] memory results);

    function getLatest(Variable variable) external view returns (uint256);

    function getLargestSafeQueryWindow() external view returns (uint256);

    function getPastAccumulators(OracleAccumulatorQuery[] memory queries) external view returns (int256[] memory results);
}

interface IBVault {
    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    function WETH() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IBalancer.sol";

interface IFractionalizationBootstrappingPool {
    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT,
        ALL_TOKENS_IN_FOR_EXACT_BPT_OUT,
        REWARD
    }

    function poke() external;

    function totalSupply() external view returns (uint256);

    function getTimeWeightedAverage(IPriceOracle.OracleAverageQuery[] memory queries) external view returns (uint256[] memory prices);

    function getLatest(IPriceOracle.Variable variable) external view returns (uint256);

    function getNormalizedWeights() external view returns (uint256[] memory);

    function getPoolId() external view returns (bytes32);

    function sERC20IsToken0() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IFractionalizationBootstrappingPoolFactory {
    function create(
        string memory name,
        string memory symbol,
        address token0,
        address token1,
        uint256 sMaxNormalizedWeight,
        uint256 sMinNormalizedWeight,
        uint256 swapFeePercentage,
        bool sERC20IsToken0
    ) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Proposals.sol";
import "../interfaces/IFractionalizationBootstrappingPool.sol";

library Issuances {
    enum State {
        Null,
        Opened,
        Closed
    }

    struct Issuance {
        State state;
        address guardian;
        IFractionalizationBootstrappingPool pool;
        bytes32 poolId;
        uint256 reserve;
        uint256 allocation;
        uint256 fee;
        uint256 nbOfProposals;
        mapping(uint256 => Proposals.Proposal) proposals;
        bool flash;
        bool sERC20IsToken0;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library Proposals {
    enum State {
        Null,
        Pending,
        Accepted,
        Rejected,
        Lapsed,
        Withdrawn
    }

    struct Proposal {
        State _state;
        address buyer;
        uint256 value;
        uint256 price;
        uint256 expiration;
    }

    function state(Proposal storage proposal) internal view returns (State) {
        State _state = proposal._state;
        uint256 expiration = proposal.expiration;

        if (_state == State.Pending && expiration != 0) {
            if (block.timestamp < proposal.expiration) return State.Pending;
            else return State.Lapsed;
        } else {
            return _state;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../vault/IVault.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";

interface sIERC20 is IAccessControlUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable, IERC20PermitUpgradeable {
    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 cap_,
        address admin
    ) external;

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function pause() external;

    function unpause() external;

    function snapshot() external returns (uint256);

    function onERC1155Transferred(
        address from,
        address to,
        uint256 amount
    ) external;

    function vault() external view returns (IVault);

    function cap() external view returns (uint256);

    function paused() external view returns (bool);

    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256);

    function totalSupplyAt(uint256 snapshotId) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./libraries/Spectres.sol";
import "../token/sIERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IVault {
    event Fractionalize(IERC721 indexed collection, uint256 indexed tokenId, uint256 indexed id, sIERC20 sERC20, address broker);
    event Unlock(uint256 indexed id, address recipient);
    event Escape(IERC721 collection, uint256 tokenId, address recipient);

    function fractionalize(
        IERC721 collection,
        uint256 tokenId,
        string memory name,
        string memory symbol,
        uint256 cap,
        address admin,
        address broker
    ) external returns (uint256);

    function unlock(
        uint256 id,
        address recipient,
        bytes calldata data
    ) external;

    function unlock(
        sIERC20 sERC20,
        address recipient,
        bytes calldata data
    ) external;

    function escape(
        IERC721 collection,
        uint256 tokenId,
        address recipient,
        bytes memory data
    ) external;

    function setUnavailableURI(string memory unavailableURI_) external;

    function setUnlockedURI(string memory unlockedURI_) external;

    function onERC20Transferred(
        address from,
        address to,
        uint256 amount
    ) external;

    function sERC20Base() external view returns (address);

    function unavailableURI() external view returns (string memory);

    function unlockedURI() external view returns (string memory);

    function isLocked(IERC721 collection, uint256 tokenId) external view returns (bool);

    function tokenTypeOf(IERC721 collection, uint256 tokenId) external view returns (uint256);

    function spectreOf(uint256 id) external view returns (Spectres.Spectre memory);

    function spectreOf(sIERC20 sERC20) external view returns (Spectres.Spectre memory);

    function sERC20Of(uint256 id) external pure returns (sIERC20);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library Spectres {
    enum State {
        Null,
        Locked,
        Unlocked
    }

    struct Spectre {
        State state;
        IERC721 collection;
        uint256 tokenId;
        address broker;
    }
}