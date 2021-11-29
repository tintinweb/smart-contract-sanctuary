/**
 *Submitted for verification at FtmScan.com on 2021-11-29
*/

// SPDX-License-Identifier: MIXED

// File @openzeppelin/contracts/utils/introspection/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// File @openzeppelin/contracts/token/ERC1155/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File @openzeppelin/contracts/access/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

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

// File @openzeppelin/contracts/access/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

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

// File @openzeppelin/contracts/utils/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// File @openzeppelin/contracts/utils/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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

// File @openzeppelin/contracts/utils/introspection/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File @openzeppelin/contracts/access/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File @openzeppelin/contracts/utils/structs/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/structs/EnumerableSet.sol)

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

// File @openzeppelin/contracts/access/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;



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
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// File @openzeppelin/contracts/token/ERC20/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// File @openzeppelin/contracts/token/ERC1155/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File contracts/interfaces/IStrategy.sol
// License-Identifier: MIT

pragma solidity ^0.8.6;

interface IStrategy {
    /**
     * @notice Gets the token this strategy compounds.
     * @dev This token might have a transfer-tax.
     * @dev Invariant: This variable may never change.
     */
    function underlyingToken() external view returns (IERC20);

    /**
     * @notice Gets the total amount of tokens either idle in this strategy or staked in an underlying strategy.
     */
    function totalUnderlying() external view returns (uint256 totalUnderlying);
    /**
     * @notice Gets the total amount of tokens either idle in this strategy or staked in an underlying strategy and only the tokens actually staked.
     */
    function totalUnderlyingAndStaked() external view returns (uint256 totalUnderlying, uint256 totalUnderlyingStaked);

    /**
     * @notice The panic function unstakes all staked funds from the strategy and leaves them idle in the strategy for withdrawal
     * @dev Authority: This function must only be callable by the VaultChef.
     */
    function panic() external;

    /**
     * @notice Executes a harvest on the underlying vaultchef.
     * @dev Authority: This function must only be callable by the vaultchef.
     */
    function harvest() external;
    /**
     * @notice Deposits `amount` amount of underlying tokens in the underlying strategy
     * @dev Authority: This function must only be callable by the VaultChef.
     */
    function deposit(uint256 amount) external;

    /**
     * @notice Withdraws `amount` amount of underlying tokens to `to`.
     * @dev Authority: This function must only be callable by the VaultChef.
     */
    function withdraw(address to, uint256 amount) external;

    /**
     * @notice Withdraws `amount` amount of `token` to `to`.
     * @notice This function is used to withdraw non-staking and non-native tokens accidentally sent to the strategy.
     * @notice It will also be used to withdraw tokens airdropped to the strategies.
     * @notice The underlying token can never be withdrawn through this method because VaultChef prevents it.
     * @dev Requirement: This function should in no way allow withdrawal of staking tokens
     * @dev Requirement: This function should in no way allow for the decline in shares or share value (this is also checked in the VaultChef);
     * @dev Validation is already done in the VaultChef that the staking token cannot be withdrawn.
     * @dev Authority: This function must only be callable by the VaultChef.
     */
    function inCaseTokensGetStuck(
        IERC20 token,
        uint256 amount,
        address to
    ) external;
}

// File contracts/interfaces/IVaultChefCore.sol
// License-Identifier: MIT

pragma solidity ^0.8.6;



/**
 * @notice The VaultChef is a vault management contract that manages vaults, their strategies and the share positions of investors in these vaults.
 * @notice Positions are not hardcoded into the contract like traditional staking contracts, instead they are managed as ERC-1155 receipt tokens.
 * @notice This receipt-token mechanism is supposed to simplify zapping and other derivative protocols.
 * @dev The VaultChef contract has the following design principles.
 * @dev 1. Simplicity of Strategies: Strategies should be as simple as possible.
 * @dev 2. Control of Governance: Governance should never be able to steal underlying funds.
 * @dev 3. Auditability: It should be easy for third-party reviewers to assess the safety of the VaultChef.
 */
interface IVaultChefCore is IERC1155 {
    /// @notice A vault is a strategy users can stake underlying tokens in to receive a share of the vault value.
    struct Vault {
        /// @notice The token this strategy will compound.
        IERC20 underlyingToken;
        /// @notice The timestamp of the last harvest, set to zero while no harvests have happened.
        uint96 lastHarvestTimestamp;
        /// @notice The strategy contract.
        IStrategy strategy;
        /// @notice The performance fee portion of the harvests that is sent to the feeAddress, denominated by 10,000.
        uint16 performanceFeeBP;
        /// @notice Whether deposits are currently paused.
        bool paused;
        /// @notice Whether the vault has panicked which means the funds are pulled from the strategy and it is paused forever.
        bool panicked;
    }

    /**
     * @notice Deposit `underlyingAmount` amount of underlying tokens into the vault and receive `sharesReceived` proportional to the actually staked amount.
     * @notice Deposits mint `sharesReceived` receipt tokens as ERC-1155 tokens to msg.sender with the tokenId equal to the vaultId.
     * @notice The tokens are transferred from `msg.sender` which requires approval if pulled is set to false, otherwise `msg.sender` needs to implement IPullDepositor.
     * @param vaultId The id of the vault.
     * @param underlyingAmount The intended amount of tokens to deposit (this might not equal the actual deposited amount due to tx/stake fees or the pull mechanism).
     * @param pulled Uses a pull-based deposit hook if set to true, otherwise traditional safeTransferFrom. The pull-based mechanism allows the depositor to send tokens using a hook.
     * @param minSharesReceived The minimum amount of shares that must be received, or the transaction reverts.
     * @dev This pull-based methodology is extremely valuable for zapping transfer-tax tokens more economically.
     * @dev `msg.sender` must be a smart contract implementing the `IPullDepositor` interface.
     * @return sharesReceived The number of shares minted to the msg.sender.
     */
    function depositUnderlying(
        uint256 vaultId,
        uint256 underlyingAmount,
        bool pulled,
        uint256 minSharesReceived
    ) external returns (uint256 sharesReceived);

    /**
     * @notice Withdraws `shares` from the vault into underlying tokens to the `msg.sender`.
     * @notice Burns `shares` receipt tokens from the `msg.sender`.
     * @param vaultId The id of the vault.
     * @param shares The amount of shares to burn, underlying tokens will be sent to msg.sender proportionally.
     * @param minUnderlyingReceived The minimum amount of underlying tokens that must be received, or the transaction reverts.
     */
    function withdrawShares(
        uint256 vaultId,
        uint256 shares,
        uint256 minUnderlyingReceived
    ) external returns (uint256 underlyingReceived);

    /**
     * @notice Withdraws `shares` from the vault into underlying tokens to the `to` address.
     * @notice To prevent phishing, we require msg.sender to be a contract as this is intended for more economical zapping of transfer-tax token withdrawals.
     * @notice Burns `shares` receipt tokens from the `msg.sender`.
     * @param vaultId The id of the vault.
     * @param shares The amount of shares to burn, underlying tokens will be sent to msg.sender proportionally.
     * @param minUnderlyingReceived The minimum amount of underlying tokens that must be received, or the transaction reverts.
     */
    function withdrawSharesTo(
        uint256 vaultId,
        uint256 shares,
        uint256 minUnderlyingReceived,
        address to
    ) external returns (uint256 underlyingReceived);

    /**
     * @notice Total amount of shares in circulation for a given vaultId.
     * @param vaultId The id of the vault.
     * @return The total number of shares currently in circulation.
     */
    function totalSupply(uint256 vaultId) external view returns (uint256);

    /**
     * @notice Calls harvest on the underlying strategy to compound pending rewards to underlying tokens.
     * @notice The performance fee is minted to the owner as shares, it can never be greater than 5% of the underlyingIncrease.
     * @return underlyingIncrease The amount of underlying tokens generated.
     * @dev Can only be called by owner.
     */
    function harvest(uint256 vaultId)
        external
        returns (uint256 underlyingIncrease);

    /**
     * @notice Adds a new vault to the vaultchef.
     * @param strategy The strategy contract that manages the allocation of the funds for this vault, also defines the underlying token
     * @param performanceFeeBP The percentage of the harvest rewards that are given to the governance, denominated by 10,000 and maximum 5%.
     * @dev Can only be called by owner.
     */
    function addVault(IStrategy strategy, uint16 performanceFeeBP) external;

    /**
     * @notice Updates the performanceFee of the vault.
     * @param vaultId The id of the vault.
     * @param performanceFeeBP The percentage of the harvest rewards that are given to the governance, denominated by 10,000 and maximum 5%.
     * @dev Can only be called by owner.
     */
    function setVault(uint256 vaultId, uint16 performanceFeeBP) external;
    /**
     * @notice Allows the `pullDepositor` to create pull-based deposits (useful for zapping contract).
     * @notice Having a whitelist is not necessary for this functionality as it is safe but upon defensive code recommendations one was added in.
     * @dev Can only be called by owner.
     */
    function setPullDepositor(address pullDepositor, bool isAllowed) external;
    
    /**
     * @notice Withdraws funds from the underlying staking contract to the strategy and irreversibly pauses the vault.
     * @param vaultId The id of the vault.
     * @dev Can only be called by owner.
     */
    function panicVault(uint256 vaultId) external;

    /**
     * @notice Returns true if there is a vault associated with the `vaultId`.
     * @param vaultId The id of the vault.
     */
    function isValidVault(uint256 vaultId) external returns (bool);

    /**
     * @notice Returns the Vault information of the vault at `vaultId`, returns if non-existent.
     * @param vaultId The id of the vault.
     */
    function vaultInfo(uint256 vaultId) external returns (Vault memory);

    /**
     * @notice Pauses the vault which means deposits and harvests are no longer permitted, reverts if already set to the desired value.
     * @param vaultId The id of the vault.
     * @param paused True to pause, false to unpause.
     * @dev Can only be called by owner.
     */
    function pauseVault(uint256 vaultId, bool paused) external;

    /**
     * @notice Transfers tokens from the VaultChef to the `to` address.
     * @notice Cannot be abused by governance since the protocol never ever transfers tokens to the VaultChef. Any tokens stored there are accidentally sent there.
     * @param token The token to withdraw from the VaultChef.
     * @param to The address to send the token to.
     * @dev Can only be called by owner.
     */
    function inCaseTokensGetStuck(IERC20 token, address to) external;

    /**
     * @notice Transfers tokens from the underlying strategy to the `to` address.
     * @notice Cannot be abused by governance since VaultChef prevents token to be equal to the underlying token.
     * @param token The token to withdraw from the strategy.
     * @param to The address to send the token to.
     * @param amount The amount of tokens to withdraw.
     * @dev Can only be called by owner.
     */
    function inCaseVaultTokensGetStuck(
        uint256 vaultId,
        IERC20 token,
        address to,
        uint256 amount
    ) external;
}

// File contracts/interfaces/IMasterChef.sol
// License-Identifier: MIT

pragma solidity ^0.8.6;

/// @dev The VaultChef implements the masterchef interface for compatibility with third-party tools.
interface IMasterChef {
    /// @dev An active vault has a dummy allocPoint of 1 while an inactive one has an allocPoint of zero.
    /// @dev This is done for better compatibility with third-party tools.
    function poolInfo(uint256 pid)
        external
        view
        returns (
            IERC20 lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accTokenPerShare
        );

    function userInfo(uint256 pid, address user)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function startBlock() external view returns (uint256);

    function poolLength() external view returns (uint256);

    /// @dev Returns the total number of active vaults.
    function totalAllocPoint() external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;
}

// File contracts/interfaces/IERC20Metadata.sol
// License-Identifier: MIT
// Based on: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/1b27c13096d6e4389d62e7b0766a1db53fbb3f1b/contracts/token/ERC20/extensions/IERC20Metadata.sol

pragma solidity ^0.8.6;
/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata {
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

// File contracts/interfaces/IVaultChefWrapper.sol
// License-Identifier: MIT

pragma solidity ^0.8.6;



interface IVaultChefWrapper is IMasterChef, IERC20Metadata{
     /**
     * @notice Interface function to fetch the total underlying tokens inside a vault.
     * @notice Calls the totalUnderlying function on the vault strategy.
     * @param vaultId The id of the vault.
     */
    function totalUnderlying(uint256 vaultId) external view returns (uint256);

     /**
     * @notice Changes the ERC-20 metadata for etherscan listing.
     * @param newName The new ERC-20-like token name.
     * @param newSymbol The new ERC-20-like token symbol.
     * @param newDecimals The new ERC-20-like token decimals.
     */
    function changeMetadata(
        string memory newName,
        string memory newSymbol,
        uint8 newDecimals
    ) external;

     /**
     * @notice Sets the ERC-1155 metadata URI.
     * @param newURI The new ERC-1155 metadata URI.
     */
    function setURI(string memory newURI) external;

    /// @notice mapping that returns true if the strategy is set as a vault.
    function strategyExists(IStrategy strategy) external view returns(bool);


    /// @notice Utility mapping for UI to figure out the vault id of a strategy.
    function strategyVaultId(IStrategy strategy) external view returns(uint256);

}

// File contracts/interfaces/IVaultChef.sol
// License-Identifier: MIT

pragma solidity ^0.8.6;


/// @notice Interface for derivative protocols.
interface IVaultChef is IVaultChefWrapper, IVaultChefCore {
   
}

// File contracts/interfaces/IOwnable.sol
// License-Identifier: MIT

pragma solidity ^0.8.6;


interface IOwnable {
   function transferOwnership() external;
   function setPendingOwner(address newPendingOwner) external;
}

// File contracts/governance/VaultChefGovernor.sol
// License-Identifier: MIT

pragma solidity ^0.8.6;




/**
 * @notice The VaultChefGovernor is the first owner of the vaultchef and manages the permissions of various
 * @notice Privileged addresses can be inspected by iterating over the different roles (ADD_VAULT_ROLE, SET_VAULT_ROLE, PAUSE_VAULT_ROLE and DEFAULT_ADMIN_ROLE).
 * @notice ADD_VAULT_ROLE can add new vaults to the vaultChef
 * @notice SET_VAULT_ROLE can update the performance fee of vaults on the vaultChef
 * @notice PAUSE_VAULT_ROLE can pause and panic vaults on the vaulChef
 * @notice DEFAULT_ADMIN_ROLE is the administrator to modify roles and can furthermore call the rest of the governance functions. These should be multisigs or long timelocks.
 * @notice DEFAULT_ADMIN_ROLE can also execute arbitrary functions so it can do all the actions of the other roles as well.
 */
contract VaultChefGovernor is AccessControlEnumerable, IERC1155Receiver {
    /// @dev The underlying vaultChef to administer.
    IVaultChef public immutable vaultChef;

    /// @dev Can add new vaults to the vaultChef.
    bytes32 public constant ADD_VAULT_ROLE = keccak256("ADD_VAULT_ROLE");
    /// @dev Can update the performance fee of vaults.
    bytes32 public constant SET_VAULT_ROLE = keccak256("SET_VAULT_ROLE");
    /// @dev Can pause and panic vaults.
    bytes32 public constant PAUSE_VAULT_ROLE = keccak256("PAUSE_VAULT_ROLE");
    /// @dev Can process harvest fees.
    bytes32 public constant FEE_PROCESSOR_ROLE =
        keccak256("FEE_PROCESSOR_ROLE");

    event FeesTransferred(
        uint256 indexed fromId,
        uint256 indexed length,
        address indexed to
    );

    constructor(IVaultChef _vaultChef, address _owner) {
        vaultChef = _vaultChef;
        /// @dev Make msg.sender the default admin
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantAllRoles(_owner);
    }

    /// @notice Grants an account all roles. Must be called from a DEFAULT_ADMIN.
    function grantAllRoles(address account)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantAllRoles(account);
    }

    function _grantAllRoles(address account) internal {
        _setupRole(DEFAULT_ADMIN_ROLE, account);
        _setupRole(ADD_VAULT_ROLE, account);
        _setupRole(SET_VAULT_ROLE, account);
        _setupRole(PAUSE_VAULT_ROLE, account);
    }

    /// @notice Revokes all roles from an account. Must be called by a DEFAULT_ADMIN.
    function revokeAllRoles(address account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(ADD_VAULT_ROLE, account);
        revokeRole(SET_VAULT_ROLE, account);
        revokeRole(PAUSE_VAULT_ROLE, account);
        revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @notice Generic function proxy, only callable by the DEFAULT_ADMIN.
    function executeTransaction(
        address target,
        uint256 value,
        bytes memory data
    ) external payable onlyRole(DEFAULT_ADMIN_ROLE) returns (bytes memory) {
        (bool success, bytes memory returnData) = target.call{value: value}(
            data
        );
        require(success, "!reverted");
        return returnData;
    }

    function addVault(IStrategy strategy, uint16 performanceFeeBP)
        external
        onlyRole(ADD_VAULT_ROLE)
    {
        vaultChef.addVault(strategy, performanceFeeBP);
    }

    function setVault(uint256 vaultId, uint16 performanceFeeBP)
        external
        onlyRole(SET_VAULT_ROLE)
    {
        vaultChef.setVault(vaultId, performanceFeeBP);
    }

    function panicVault(uint256 vaultId) external onlyRole(PAUSE_VAULT_ROLE) {
        vaultChef.panicVault(vaultId);
    }

    function pauseVault(uint256 vaultId, bool paused)
        external
        onlyRole(PAUSE_VAULT_ROLE)
    {
        vaultChef.pauseVault(vaultId, paused);
    }

    function setPullDepositor(address pullDepositor, bool isAllowed)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        vaultChef.setPullDepositor(pullDepositor, isAllowed);
    }

    function inCaseTokensGetStuck(IERC20 token, address to)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        vaultChef.inCaseTokensGetStuck(token, to);
    }

    function inCaseVaultTokensGetStuck(
        uint256 vaultId,
        IERC20 token,
        address to,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        vaultChef.inCaseVaultTokensGetStuck(vaultId, token, to, amount);
    }

    function transferAllFees(address to) external onlyRole(FEE_PROCESSOR_ROLE) {
        transferFeesBatch(0, vaultChef.poolLength(), to);
    }

    function transferFeesBatch(
        uint256 fromId,
        uint256 length,
        address to
    ) public onlyRole(FEE_PROCESSOR_ROLE) {
        uint256[] memory ids = new uint256[](length);
        address[] memory accounts = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            ids[i] = fromId + i;
            accounts[i] = address(this);
        }
        uint256[] memory amounts = vaultChef.balanceOfBatch(accounts, ids);
        vaultChef.safeBatchTransferFrom(address(this), to, ids, amounts, "");

        emit FeesTransferred(fromId, length, to);
    }

    function changeMetadata(
        string memory newName,
        string memory newSymbol,
        uint8 newDecimals
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        vaultChef.changeMetadata(newName, newSymbol, newDecimals);
    }

    function setURI(string memory newURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        vaultChef.setURI(newURI);
    }

    function transferOwnership() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _transferOwnership();
    }

    function _transferOwnership() internal {
        IOwnable(address(vaultChef)).transferOwnership();
    }

    function onERC1155Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*id*/,
        uint256 /*value*/,
        bytes calldata /*data*/
    ) external override pure returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address /*operator*/,
        address /*from*/,
        uint256[] calldata /*ids*/,
        uint256[] calldata /*values*/,
        bytes calldata /*data*/
    ) external override pure returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }
}