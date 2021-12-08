/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// SPDX-License-Identifier: MIT

// Sources flattened with hardhat v2.6.5 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

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

// File @openzeppelin/contracts/token/ERC721/[email protected]

pragma solidity ^0.8.0;

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

// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File @openzeppelin/contracts/utils/math/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

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

// File @openzeppelin/contracts-upgradeable/access/[email protected]

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

// File @openzeppelin/contracts-upgradeable/access/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
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

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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

// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

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

// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

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

    function __ERC165_init_unchained() internal initializer {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    uint256[50] private __gap;
}

// File @openzeppelin/contracts-upgradeable/access/[email protected]

pragma solidity ^0.8.0;

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
abstract contract AccessControlUpgradeable is
    Initializable,
    ContextUpgradeable,
    IAccessControlUpgradeable,
    ERC165Upgradeable
{
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {}

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

// File @openzeppelin/contracts-upgradeable/utils/structs/[email protected]

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
library EnumerableSetUpgradeable {
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

// File @openzeppelin/contracts-upgradeable/access/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is
    Initializable,
    IAccessControlEnumerableUpgradeable,
    AccessControlUpgradeable
{
    function __AccessControlEnumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
    }

    function __AccessControlEnumerable_init_unchained() internal initializer {}

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
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
    function grantRole(bytes32 role, address account)
        public
        virtual
        override(AccessControlUpgradeable, IAccessControlUpgradeable)
    {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override(AccessControlUpgradeable, IAccessControlUpgradeable)
    {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override(AccessControlUpgradeable, IAccessControlUpgradeable)
    {
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

    uint256[49] private __gap;
}

// File @openzeppelin/contracts-upgradeable/security/[email protected]

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

// File @openzeppelin/contracts-upgradeable/security/[email protected]

pragma solidity ^0.8.0;

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

// File contracts/IBoneyard.sol

pragma solidity 0.8.9;
pragma abicoder v2;

// Race statuses. We're not using enums, since they aren't backward compatible
uint8 constant STATUS_CREATED = 0;
uint8 constant STATUS_FINALIZED = 1;

struct Race {
    uint256 id;
    uint256 createBlock;
    uint256 startBlock;
    uint256 maxLevel;
    uint16 version;
    uint8 status;
}

struct RaceInfo {
    Race race;
    uint256[] racers;
}

struct RacerPosition {
    uint256 racer;
    uint256 position;
}

interface IBoneyard {
    /**
     * @dev Returns the NFT representing racers
     */
    function token() external view returns (IERC721Enumerable);

    /**
     * @dev Returns race data
     */
    function raceData(uint256 raceId) external view returns (RaceInfo memory);

    /**
     * @dev Returns race results
     */
    function raceResults(uint256 raceId) external view returns (RacerPosition[] memory);

    /**
     * @dev Returns the current level of racer
     */
    function levelOf(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Returns the current XP of racer
     */
    function xpOf(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Joins the boneyard
     */
    function joinBoneyard(uint256 tokenId) external;

    /**
     * @dev Joins the boneyard
     */
    function joinBoneyardMulti(uint256[] calldata tokenIds) external;

    /**
     * @dev Leaves the boneyard
     */
    function leaveBoneyard(uint256 tokenId) external;

    /**
     * @dev Leaves the boneyard
     */
    function leaveBoneyardMulti(uint256[] calldata tokenIds) external;

    /**
     * @dev Creates a new race and specifies the maximum number of racers
     */
    function createRace(uint256 tokenId, uint256 maxLevel) external returns (uint256);

    /**
     * @dev Joins a pending race
     */
    function joinRace(uint256 raceId, uint256 tokenId) external;

    /**
     * @dev Finalizes a finished and finalizable race
     */
    function finalizeRace(uint256 raceId) external;

    /**
     * @dev Calculates all racer positions iteratively during the specified number of blocks
     */
    function calcRacePositions(uint256 raceId, uint256 blocks) external view returns (RacerPosition[] memory);

    /**
     * @dev Returns whether a race is valid
     */
    function isRaceValid(uint256 raceId) external view returns (bool);

    /**
     * @dev Returns whether a race is pending
     */
    function isRacePending(uint256 raceId) external view returns (bool);

    /**
     * @dev Returns whether a race is live
     */
    function isRaceLive(uint256 raceId) external view returns (bool);

    /**
     * @dev Returns whether a race has finished
     */
    function isRaceFinished(uint256 raceId) external view returns (bool);

    /**
     * @dev Returns whether a race is finalizable
     */
    function isRaceFinalizable(uint256 raceId) external view returns (bool);

    /**
     * @dev Returns whether a race has been finalized
     */
    function isRaceFinalized(uint256 raceId) external view returns (bool);

    /**
     * @dev Returns whether a race has expired
     */
    function isRaceExpired(uint256 raceId) external view returns (bool);

    /**
     * @dev Returns whether a racer is participating in any ongoing race
     */
    function isParticipating(uint256 tokenId) external view returns (bool);
}

// File contracts/Boneyard.sol

pragma solidity 0.8.9;

error NotInitialized();
error AccessDenied();
error InvalidAddress();
error InvalidRace();
error InvalidArgument();
error AlreadyExists();
error TooManyRacers();
error LevelTooHigh();
error AlreadyRacing();
error NotRacing();

contract Boneyard is
    IBoneyard,
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    // The administrator role is only capable of pausing creation or finalization of new races while still allowing
    // racers to withdraw their tokens
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // The version of the current game
    uint8 public constant VERSION = 1;

    // The maximum number of racers who can participate in a single race
    uint8 public constant MAX_RACERS = 7;

    // The number of blocks which needs to pass before a created race is live
    uint16 public constant PENDING_BLOCKS = 600;

    // The number of blocks during which the race is live and the game is on
    uint8 public constant RACING_BLOCKS = 60;

    // The maximum number of blocks during which it'd still be possible to finalize
    uint8 public constant MAX_FINALIZATION_BLOCKS = 255 - RACING_BLOCKS + 1;

    // The maximum distance a racer can advance
    uint256 public constant MAX_DISTANCE_PER_BLOCK = 20;

    // The distance bonus for every bonus points
    uint8 public constant DISTANCE_BONUS = 1;

    // The number of levels required for each bonus point
    uint8 public constant LEVELS_PER_BONUS_POINT = 1;

    // The number of XP points required to gain a new level
    uint256 public constant XP_PER_LEVEL = 1000;

    // The base number of XP points a racer gains by beating another racer
    uint256 public constant XP_BASE_GAIN = 50;

    // The XP bonus for level differences
    uint256 public constant LEVEL_DIFF_XP_BONUS = 25;

    // The NFT representing racers
    IERC721Enumerable private immutable _token;

    // The ID of the next race
    uint256 internal _nextRaceId;

    // A mapping between race IDs and races
    mapping(uint256 => Race) private _races;

    // A mapping between race IDs and its participating racers
    mapping(uint256 => EnumerableSetUpgradeable.UintSet) private _racers;

    // A mapping of racer owners
    mapping(uint256 => address) internal _owners;

    // A mapping of participating racers and their current race IDs
    mapping(uint256 => uint256) internal _racing;

    // A mapping of racers IDs and their overall XP
    mapping(uint256 => uint256) internal _xp;

    // A mapping of race results
    mapping(uint256 => RacerPosition[]) private _results;

    // Future compatibility storage gap, since the contract is designed to be deployed as a proxy
    uint256[50 - 7] private __gap;

    // Triggered when a racer joins the boneyard
    event BoneyardJoined(address indexed racer, uint256 indexed racerTokenId);

    // Triggered when a racer leaves the boneyard
    event BoneyardLeft(address indexed racer, uint256 indexed racerTokenId);

    // Triggered when a race is created
    event RaceCreated(
        uint256 indexed raceId,
        address indexed host,
        uint256 indexed hostTokenId,
        uint256 createBlock,
        uint256 maxLevel
    );

    // Triggered when a racer joins a pending race
    event RaceJoined(uint256 indexed raceId, address indexed racer, uint256 indexed racerTokenId);

    // Triggered when a race is finalized
    event RaceFinalized(uint256 indexed raceId, uint256 indexed winnerTokenId);

    // This modifier is used to restrict the operation when the boneyard isn't initialized
    modifier whenInitialized() {
        _verifyInitialized();

        _;
    }

    // This modifier is used to restrict admin-only operations
    modifier onlyAdmin() {
        _hasRole(ADMIN_ROLE, msg.sender);

        _;
    }

    // This modifier is used to verify that a racer has joined the boneyard
    modifier onlyRacer(uint256 tokenId) {
        _verifyRacer(tokenId);

        _;
    }

    // This modifier is used to restrict the operation to participating racers
    modifier whenRacing(uint256 tokenId) {
        _verifyParticipation(tokenId, true);

        _;
    }

    // This modifier is used to restrict the operation to non-participating racers
    modifier whenNotRacing(uint256 tokenId) {
        _verifyParticipation(tokenId, false);

        _;
    }

    /**
     * @dev A constructor only used to initialize immutable storage variables
     */
    constructor(IERC721Enumerable initToken) {
        if (address(initToken) == address(0)) {
            revert InvalidAddress();
        }

        _token = initToken;
    }

    /**
     * @dev Initializes the contract
     */
    function initialize() external initializer {
        __Boneyard_init();
    }

    // solhint-disable func-name-mixedcase

    /**
     * @dev Initializes the contract and its parents
     */
    function __Boneyard_init() internal initializer {
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        __Boneyard_init_unchained();
    }

    /**
     * @dev Contract-specific initialization
     */
    function __Boneyard_init_unchained() internal initializer {
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);

        _nextRaceId = 1;
    }

    // solhint-enable func-name-mixedcase

    /**
     * @inheritdoc IBoneyard
     */
    function token() external view returns (IERC721Enumerable) {
        return _token;
    }

    /**
     * @inheritdoc IBoneyard
     */
    function raceData(uint256 raceId) external view returns (RaceInfo memory) {
        return RaceInfo({ race: _races[raceId], racers: _racers[raceId].values() });
    }

    /**
     * @inheritdoc IBoneyard
     */
    function raceResults(uint256 raceId) external view returns (RacerPosition[] memory) {
        return _results[raceId];
    }

    /**
     * @inheritdoc IBoneyard
     */
    function levelOf(uint256 tokenId) external view returns (uint256) {
        return _levelOf(tokenId);
    }

    /**
     * @inheritdoc IBoneyard
     */
    function xpOf(uint256 tokenId) external view returns (uint256) {
        return _xp[tokenId];
    }

    /**
     * @inheritdoc IBoneyard
     */
    function joinBoneyard(uint256 tokenId) external whenInitialized whenNotPaused {
        _joinBoneyard(msg.sender, tokenId);
    }

    /**
     * @inheritdoc IBoneyard
     */
    function joinBoneyardMulti(uint256[] calldata tokenIds) external whenInitialized whenNotPaused {
        uint256 length = tokenIds.length;

        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                _joinBoneyard(msg.sender, tokenIds[i]);
            }
        }
    }

    /**
     * @inheritdoc IBoneyard
     */
    function leaveBoneyard(uint256 tokenId) external whenNotRacing(tokenId) {
        _leaveBoneyard(msg.sender, tokenId);
    }

    /**
     * @inheritdoc IBoneyard
     */
    function leaveBoneyardMulti(uint256[] calldata tokenIds) external {
        uint256 length = tokenIds.length;

        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                uint256 tokenId = tokenIds[i];

                _verifyParticipation(tokenId, false);
                _leaveBoneyard(msg.sender, tokenId);
            }
        }
    }

    /**
     * @inheritdoc IBoneyard
     */
    function createRace(uint256 tokenId, uint256 maxLevel)
        external
        virtual
        nonReentrant
        whenNotRacing(tokenId)
        whenNotPaused
        returns (uint256)
    {
        if (_levelOf(tokenId) > maxLevel) {
            revert LevelTooHigh();
        }

        // Generate a new race ID
        uint256 raceId = _nextRaceId;
        unchecked {
            ++_nextRaceId;
        }

        // Create a new race and store it
        Race memory race = Race({
            id: raceId,
            version: VERSION,
            createBlock: block.number,
            startBlock: block.number + PENDING_BLOCKS - 1,
            maxLevel: maxLevel,
            status: STATUS_CREATED
        });

        _races[raceId] = race;

        // Add the current racer to the new race
        _racers[raceId].add(tokenId);
        _racing[tokenId] = raceId;

        emit RaceCreated({
            raceId: raceId,
            host: msg.sender,
            hostTokenId: tokenId,
            createBlock: block.number,
            maxLevel: maxLevel
        });

        return raceId;
    }

    /**
     * @inheritdoc IBoneyard
     */
    function joinRace(uint256 raceId, uint256 tokenId) external nonReentrant whenNotPaused whenNotRacing(tokenId) {
        Race memory race = _races[raceId];

        // Verify that the race is still pending
        if (!_isRacePending(race)) {
            revert InvalidRace();
        }

        if (_levelOf(tokenId) > race.maxLevel) {
            revert LevelTooHigh();
        }

        // Verify that there is still room in the race and start the race immediately if max racers have joined
        EnumerableSetUpgradeable.UintSet storage racers = _racers[raceId];
        uint256 newRacersCount = racers.length() + 1;
        unchecked {
            if (newRacersCount > MAX_RACERS) {
                revert TooManyRacers();
            }

            if (newRacersCount == MAX_RACERS) {
                _races[raceId].startBlock = block.number;
            }
        }

        // Add the new racer to the race
        if (!racers.add(tokenId)) {
            revert AlreadyExists();
        }

        _racing[tokenId] = raceId;

        emit RaceJoined({ raceId: raceId, racer: msg.sender, racerTokenId: tokenId });
    }

    /**
     * @inheritdoc IBoneyard
     */
    function finalizeRace(uint256 raceId) external nonReentrant whenNotPaused {
        Race memory race = _races[raceId];

        // Verify that the race has finished and it's still possible to finalize it
        if (!_isRaceFinalizable(race)) {
            revert InvalidRace();
        }

        // Calculate all racer positions after the duration of the whole race
        uint256[] memory positions = _calcRacePositions(race, RACING_BLOCKS);

        // Get the levels of the racers
        uint256[] memory racers = _racers[race.id].values();
        assert(positions.length == racers.length);
        uint256[] memory levels = new uint256[](racers.length);
        unchecked {
            for (uint256 i = 0; i < racers.length; ++i) {
                levels[i] = _levelOf(racers[i]);
            }
        }

        // Sort the positions in ascending order, in order to calculate the XP gains
        uint256[] memory indexes = new uint256[](racers.length);
        _sortWithIndexes(positions, indexes);

        unchecked {
            // Go over the sorted positions and updated the XP gains for each racer. Note that we're skipping over the
            // first racer as it hasn't beaten any other races thus gains no XP
            //
            // The XP gain of a level L1 racer beating a level L2 racer is calculated by :
            //
            //     DIFF = L2 - L1
            //     if DIFF > 0
            //         XP = XP_BASE_GAIN + (DIFF * LEVEL_DIFF_XP_BONUS)
            //     else
            //         XP = XP_BASE_GAIN
            //     end
            //
            for (uint256 i = 1; i < positions.length; ++i) {
                uint256 position = positions[i];
                uint256 winnerIndex = indexes[i];
                uint256 winnerRacerId = racers[winnerIndex];

                uint256 gain = 0;
                for (uint256 j = 0; j < i; ++j) {
                    // If there's a draw - neither of the racers gain XP
                    if (position == positions[j]) {
                        continue;
                    }

                    uint256 loserIndex = indexes[j];
                    uint256 winnerLevel = levels[winnerIndex];
                    uint256 loserLevel = levels[loserIndex];

                    // Calculate the current racer's XP gains according to the level of the racer he has beaten
                    gain +=
                        XP_BASE_GAIN +
                        (loserLevel > winnerLevel ? (loserLevel - winnerLevel) * LEVEL_DIFF_XP_BONUS : 0);
                }

                _xp[winnerRacerId] += gain;
            }
        }

        // Mark all racers as not racing
        for (uint256 i = 0; i < racers.length; ++i) {
            delete _racing[racers[i]];
        }

        // Mark the race as finalized
        _races[raceId].status = STATUS_FINALIZED;

        // Record race reults
        RacerPosition[] storage racePositions = _results[raceId];
        unchecked {
            for (uint256 i = 0; i < positions.length; ++i) {
                racePositions.push(RacerPosition({ racer: racers[indexes[i]], position: positions[i] }));
            }
        }

        emit RaceFinalized({ raceId: raceId, winnerTokenId: racers[indexes[indexes.length - 1]] });
    }

    /**
     * @dev Calculates all racer positions iteratively during the specified number of blocks
     */
    function calcRacePositions(uint256 raceId, uint256 blocks) external view returns (RacerPosition[] memory) {
        Race memory race = _races[raceId];

        // Verify that the race is valid
        if (!_isRaceValid(race)) {
            revert InvalidRace();
        }

        if (blocks == 0) {
            revert InvalidArgument();
        }

        uint256[] memory positions = _calcRacePositions(race, blocks);
        uint256[] memory racers = _racers[race.id].values();
        assert(positions.length == racers.length);

        RacerPosition[] memory racerPositions = new RacerPosition[](racers.length);
        unchecked {
            for (uint256 i = 0; i < racerPositions.length; ++i) {
                racerPositions[i] = RacerPosition({ racer: racers[i], position: positions[i] });
            }
        }

        return racerPositions;
    }

    /**
     * @inheritdoc IBoneyard
     */
    function isRaceValid(uint256 raceId) external view returns (bool) {
        return _isRaceValid(_races[raceId]);
    }

    /**
     * @inheritdoc IBoneyard
     */
    function isRacePending(uint256 raceId) external view returns (bool) {
        return _isRacePending(_races[raceId]);
    }

    /**
     * @inheritdoc IBoneyard
     */
    function isRaceLive(uint256 raceId) external view returns (bool) {
        Race memory race = _races[raceId];
        return _isRaceLive(race) && !_isRaceExpired(race);
    }

    /**
     * @inheritdoc IBoneyard
     */
    function isRaceFinished(uint256 raceId) external view returns (bool) {
        return _isRaceFinished(_races[raceId]);
    }

    /**
     * @inheritdoc IBoneyard
     */
    function isRaceFinalizable(uint256 raceId) external view returns (bool) {
        return _isRaceFinalizable(_races[raceId]);
    }

    /**
     * @inheritdoc IBoneyard
     */
    function isRaceFinalized(uint256 raceId) external view returns (bool) {
        return _isRaceStatusFinalized(_races[raceId]);
    }

    /**
     * @inheritdoc IBoneyard
     */
    function isRaceExpired(uint256 raceId) external view returns (bool) {
        return _isRaceExpired(_races[raceId]);
    }

    /**
     * @inheritdoc IBoneyard
     */
    function isParticipating(uint256 tokenId) external view returns (bool) {
        return _isParticipating(tokenId);
    }

    /**
     * @dev Pauses the contract. Please note that it's still possible to cancel a race and unlock all racers when the
     * contract is paused
     */
    function pause() external onlyAdmin {
        _pause();
    }

    /**
     * @dev Unpauses the contract
     */
    function unpause() external onlyAdmin {
        _unpause();
    }

    /**
     * @dev Joins the boneyard
     */
    function _joinBoneyard(address racer, uint256 tokenId) private {
        _lockRacer(racer, tokenId);

        emit BoneyardJoined({ racer: racer, racerTokenId: tokenId });
    }

    /**
     * @dev Leaves the boneyard
     */
    function _leaveBoneyard(address racer, uint256 tokenId) private {
        _unlockRacer(tokenId);

        emit BoneyardLeft({ racer: racer, racerTokenId: tokenId });
    }

    /**
     * @dev Calculates all racer positions iteratively during the specified number of blocks
     */
    function _calcRacePositions(Race memory race, uint256 blocks) private view returns (uint256[] memory) {
        uint256[] memory racers = _racers[race.id].values();

        // Calculate and cache per-level bonuses
        uint256[] memory levelBonuses = new uint256[](racers.length);
        unchecked {
            for (uint256 i = 0; i < racers.length; ++i) {
                // The per-level bonus is defined as:
                //
                //      BONUS_POINTS = (LEVEL - 1) / LEVELS_PER_BONUS_POINT + 1
                //      TOTAL_BONUS = BONUS * BONUS_POINTS
                //
                // E.g., +1 for levels 1-4, +2 for levels 5-8, +3 for levels 9-11, etc.)
                //
                levelBonuses[i] = DISTANCE_BONUS * (((_levelOf(racers[i]) - 1) / LEVELS_PER_BONUS_POINT) + 1);
            }
        }

        uint256[] memory positions = new uint256[](racers.length);
        bytes32 digest = bytes32(0);

        unchecked {
            uint256 fromBlock = race.startBlock;
            uint256 toBlock = fromBlock + Math.min(RACING_BLOCKS, blocks) - 1;

            for (uint256 blockNumber = fromBlock; blockNumber <= toBlock; ++blockNumber) {
                // Get a (weak) source of randomness from the current block. Please note, that although this is a weak
                // source of randomness, an attacker would need usually need to affect multiple blocks (up to RACING_BLOCKS),
                // which makes this source of randomness practically acceptable for our case
                digest = keccak256(abi.encodePacked(digest, _blockhash(blockNumber)));

                for (uint256 i = 0; i < racers.length; ++i) {
                    // Get a per-racer source of randomness
                    uint256 rand = uint256(keccak256(abi.encodePacked(digest, i)));

                    // Calculate the distance this race move during this block and apply its per-level bonus
                    positions[i] += (rand % (MAX_DISTANCE_PER_BLOCK + 1)) + levelBonuses[i];
                }
            }
        }

        return positions;
    }

    /**
     * @dev Returns whether a race is valid
     */
    function _isRaceValid(Race memory race) private pure returns (bool) {
        return race.id != 0;
    }

    /**
     * @dev Returns whether a race is pending
     */
    function _isRacePending(Race memory race) private view returns (bool) {
        if (!_isRaceValid(race)) {
            return false;
        }

        return block.number < race.startBlock;
    }

    /**
     * @dev Returns whether a race is live
     */
    function _isRaceLive(Race memory race) private view returns (bool) {
        if (!_isRaceValid(race)) {
            return false;
        }

        unchecked {
            uint256 currentBlock = block.number;
            uint256 finishBlock = race.startBlock + RACING_BLOCKS - 1;

            return race.startBlock <= currentBlock && currentBlock <= finishBlock;
        }
    }

    /**
     * @dev Returns whether a race has finished
     */
    function _isRaceFinished(Race memory race) private view returns (bool) {
        if (!_isRaceValid(race)) {
            return false;
        }

        unchecked {
            uint256 finishBlock = race.startBlock + RACING_BLOCKS - 1;

            return finishBlock < block.number;
        }
    }

    /**
     * @dev Returns whether a race is finalizable
     */
    function _isRaceFinalizable(Race memory race) private view returns (bool) {
        if (_isRaceStatusFinalized(race) || !_isRaceFinished(race) || _isRaceExpired(race)) {
            return false;
        }

        unchecked {
            uint256 finishBlock = race.startBlock + RACING_BLOCKS - 1;

            return finishBlock < block.number;
        }
    }

    /**
     * @dev Returns whether the time of the race has expired
     */
    function _isRaceTimeExpired(Race memory race) private view returns (bool) {
        unchecked {
            uint256 finishBlock = race.startBlock + RACING_BLOCKS - 1;

            return block.number > finishBlock + MAX_FINALIZATION_BLOCKS - 1;
        }
    }

    /**
     * @dev Returns whether a race has been finalized
     */
    function _isRaceStatusFinalized(Race memory race) private pure returns (bool) {
        return race.status == STATUS_FINALIZED;
    }

    /**
     * @dev Returns whether a race has expired
     */
    function _isRaceExpired(Race memory race) private view returns (bool) {
        if (!_isRaceValid(race) || _isRaceStatusFinalized(race)) {
            return true;
        }

        if (_isRacePending(race)) {
            return false;
        }

        // If the race has expired
        if (_isRaceTimeExpired(race)) {
            return true;
        }

        // If the creation block has passed and not enough racers have joined
        uint256 racersCount = _racers[race.id].length();

        return race.startBlock <= block.number && racersCount == 1;
    }

    /**
     * @dev Returns whether a racer is participating in any ongoing race
     */
    function _isParticipating(uint256 tokenId) private view returns (bool) {
        uint256 raceId = _racing[tokenId];
        return raceId != 0 && !_isRaceExpired(_races[raceId]);
    }

    /**
     * @dev Sorts the provided list in ascending order and returns its new indexes
     */
    function _sortWithIndexes(uint256[] memory list, uint256[] memory indexes) internal pure {
        unchecked {
            uint256 length = list.length;
            for (uint256 i = 0; i < length; i++) {
                indexes[i] = i;
            }

            for (uint256 i = 1; i < length; i++) {
                uint256 key = list[i];
                uint256 j = i - 1;
                while ((int256(j) >= 0) && (list[j] > key)) {
                    list[j + 1] = list[j];
                    indexes[j + 1] = indexes[j];

                    j--;
                }

                list[j + 1] = key;
                indexes[j + 1] = i;
            }
        }
    }

    /**
     * @dev Returns the level of a racer. Every racer starts at level 1
     */
    function _levelOf(uint256 tokenId) private view returns (uint256) {
        unchecked {
            return _xp[tokenId] / XP_PER_LEVEL + 1;
        }
    }

    /**
     * @dev Locks the racer by transferring it to the contract
     */
    function _lockRacer(address owner, uint256 tokenId) private {
        _owners[tokenId] = owner;

        _token.transferFrom(owner, address(this), tokenId);
    }

    /**
     * @dev Unlocks the racer by transferring it back to its previous owner
     */
    function _unlockRacer(uint256 tokenId) private {
        address owner = _owners[tokenId];
        delete _owners[tokenId];

        _token.transferFrom(address(this), owner, tokenId);
    }

    /**
     * @dev Returns whether the provided account has the specified role
     */
    function _hasRole(bytes32 role, address account) private view {
        if (!hasRole(role, account)) {
            revert AccessDenied();
        }
    }

    /**
     * @dev Verifies if a racer has joined the boneyard
     */
    function _verifyRacer(uint256 tokenId) private view {
        if (_owners[tokenId] != msg.sender) {
            revert AccessDenied();
        }
    }

    /**
     * @dev Verifies if a racer is a participating in a race
     */
    function _verifyParticipation(uint256 tokenId, bool participating) private view {
        _verifyRacer(tokenId);

        if (_isParticipating(tokenId) != participating) {
            if (participating) {
                revert NotRacing();
            } else {
                revert AlreadyRacing();
            }
        }
    }

    /**
     * @dev Returns whether the boneyard was initialized
     */
    function _isInitialized() private view returns (bool) {
        return _nextRaceId != 0;
    }

    /**
     * @dev Verifies whether the boneyard was initialized
     */
    function _verifyInitialized() private view {
        if (!_isInitialized()) {
            revert NotInitialized();
        }
    }

    /**
     * @dev Returns the hash of the specified block
     */
    function _blockhash(uint256 blockNumber) internal view virtual returns (bytes32) {
        return blockhash(blockNumber);
    }
}