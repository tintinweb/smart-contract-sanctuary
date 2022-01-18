/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;
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

 
/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

 
/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

 
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

 
/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

 
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

 
/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

 
/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

 
/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

 
/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

 
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

 
/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

 
contract DragonKartNFTCore is
    Ownable,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable
{
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;
    string private _baseTokenURI;
    uint256 private _cap;

    EnumerableSet.UintSet private _supportedBoxTypes;

    struct Item {
        bytes32 dna;
        uint256 artifacts;
    }

    mapping(uint256 => Item) private _items;

    event CapUpdated(uint256 cap);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        uint256 initialCap_
    ) ERC721(name_, symbol_) {
        require(initialCap_ > 0, "DragonKartNFTCore: cap is 0");
        _updateCap(initialCap_);
        _baseTokenURI = baseTokenURI_;
        _tokenIdTracker.increment();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _mint(address to_, uint256 tokenId_) internal virtual override {
        require(
            ERC721Enumerable.totalSupply() < cap(),
            "DragonKartNFTCore: cap exceeded"
        );
        super._mint(to_, tokenId_);
    }

    function _updateCap(uint256 cap_) private {
        _cap = cap_;
        emit CapUpdated(cap_);
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from_, to_, tokenId_);
    }

    function exists(uint256 tokenId_) external view returns (bool) {
        return _exists(tokenId_);
    }

    function cap() public view returns (uint256) {
        return _cap;
    }

    function increaseCap(uint256 amount_) public onlyOwner {
        require(amount_ > 0, "DragonKartNFTCore: amount is 0");

        uint256 newCap = cap() + amount_;
        _updateCap(newCap);
    }

    function updateBaseTokenURI(string memory baseTokenURI_) public onlyOwner {
        _baseTokenURI = baseTokenURI_;
    }

    function mint(address to_) public onlyOwner returns (uint256) {
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        uint256 _tokenId = _tokenIdTracker.current();
        _mint(to_, _tokenId);
        _tokenIdTracker.increment();

        return _tokenId;
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must be owner.
     */
    function pause() public virtual onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must be owner.
     */
    function unpause() public virtual onlyOwner {
        _unpause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId_)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId_);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId_),
            "DragonKartNFTCore: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            string(
                abi.encodePacked(
                    baseURI,
                    tokenId_.toHexString(),
                    "/",
                    _items[tokenId_].artifacts.toHexString()
                )
            );
    }

    function updateTokenMetaData(uint256 tokenId_, uint256 artifacts_)
        external
        onlyOwner
    {
        require(_exists(tokenId_));

        Item storage _info = _items[tokenId_];
        _info.artifacts = artifacts_;
    }

    function updateTokenMetaData(
        uint256 tokenId_,
        uint256 artifacts_,
        bytes32 dna_
    ) external onlyOwner {
        require(_exists(tokenId_));

        Item storage _info = _items[tokenId_];
        _info.artifacts = artifacts_;

        if (dna_ != 0 && _info.dna == 0) {
            _info.dna = dna_;
        }
    }

    function tokenMetaData(uint256 tokenId_)
        external
        view
        returns (bytes32 _dna, uint256 _artifacts)
    {
        _dna = _items[tokenId_].dna;
        _artifacts = _items[tokenId_].artifacts;
    }
}

 
interface IItemFactory {
    function rarityDecimal() external view returns (uint256);

    function totalSupply(uint256 boxType) external view returns (uint256);

    function addItem(
        uint256 boxType,
        uint256 itemType,
        uint256 itemId,
        uint256 rarity
    ) external;

    function artifactsLength(uint256 itemType_)
        external
        view
        returns (uint256);

    function artifactIdAt(uint256 itemType_, uint256 index_)
        external
        view
        returns (uint256);

    function getRandomArtifactValue(uint256 randomness_, uint256 artifactId_)
        external
        view
        returns (uint256);

    function getRandomItem(uint256 randomness, uint256 boxType)
        external
        view
        returns (uint256 itemId, uint256 itemType);

    event ItemAdded(
        uint256 indexed boxType,
        uint256 indexed itemType,
        uint256 indexed itemId,
        uint256 rarity
    );
}

 
contract ItemFactoryManager {
    IItemFactory public itemFactory;

    event ItemFactoryUpdated(address itemFactory_);

    constructor(address itemFactory_) {
        _updateItemFactory(itemFactory_);
    }

    function _updateItemFactory(address itemFactory_) internal {
        itemFactory = IItemFactory(itemFactory_);
        emit ItemFactoryUpdated(itemFactory_);
    }
}

 
interface IRandomGenerator {
    function requestRandomNumber(uint256 tokenId) external;

    function getResultByTokenId(uint256 tokenId) external view returns (uint256);
}

 
interface IRandomConsumer {
    function rawFulfillRandomness(uint256 tokenId_, uint256 randomness_)
        external;
}

 
abstract contract RandomConsumerBase is Context, IRandomConsumer {
    IRandomGenerator public randomGenerator;
    uint256 public randomFee;

    event UpdateRandomGenerator(address randomGenerator);
    event UpdateRandomFee(uint256 randomFee);

    constructor(address randomGenerator_, uint256 randomFee_) {
        _updateRandomGenerator(randomGenerator_);
        _updateRandomFee(randomFee_);
    }

    function _updateRandomGenerator(address randomGenerator_) internal {
        randomGenerator = IRandomGenerator(randomGenerator_);
        emit UpdateRandomGenerator(randomGenerator_);
    }

    function fulfillRandomness(uint256 tokenId_, uint256 randomness_)
        internal
        virtual;

    function rawFulfillRandomness(uint256 tokenId_, uint256 randomness_)
        external
    {
        require(
            _msgSender() == address(randomGenerator),
            "RandomConsumerBase: only selected generator can call this method"
        );
        fulfillRandomness(tokenId_, randomness_);
    }

    function _updateRandomFee(uint256 randomFee_) internal {
        randomFee = randomFee_;
        emit UpdateRandomFee(randomFee_);
    }

    function _takeRandomFee() internal {
        if (randomFee > 0) {
            require(
                msg.value >= randomFee,
                "RandomConsumerBase: insufficient fee"
            );
            (bool success, ) = address(randomGenerator).call{value: msg.value}(
                new bytes(0)
            );
            require(
                success,
                "RandomConsumerBase: fee required"
            );
        }
    }
}

 
contract DragonKartNFTManager is
    AccessControlEnumerable,
    RandomConsumerBase,
    ItemFactoryManager
{
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant CAP_MANAGER_ROLE = keccak256("CAP_MANAGER_ROLE");
    bytes32 public constant CONTRACT_UPGRADER = keccak256("CONTRACT_UPGRADER");
    bytes32 public constant NFT_UPGRADER = keccak256("NFT_UPGRADER");

    DragonKartNFTCore public immutable nftCore;

    // Box type:
    // Normal: 1 - 100
    // Combo: 101 - 200
    EnumerableSet.UintSet private _supportedBoxTypes;

    mapping(uint256 => uint256[]) private _comboToBoxes;

    uint256 constant MAX_UNBOX_BLOCK_COUNT = 100;
    mapping(uint256 => uint256) private _tokenIdToUnboxBlockNumber;

    event UnboxToken(uint256 indexed tokenId);
    event TokenFulfilled(uint256 indexed tokenId);

    constructor(
        // string memory name_,
        // string memory symbol_,
        // string memory baseTokenURI_,
        // uint256 initialCap_,
        address nftCore_,
        address itemFactory_,
        address randomGenerator_,
        uint256 randomFee_
    )
        RandomConsumerBase(randomGenerator_, randomFee_)
        ItemFactoryManager(itemFactory_)
    {
        nftCore = DragonKartNFTCore(nftCore_);

        _supportedBoxTypes.add(1); // characters
        _supportedBoxTypes.add(2); // cars
        _supportedBoxTypes.add(3); // weapons
        _supportedBoxTypes.add(4); // characters, cars, weapons

        _addComboType(101); // Combo characters, cars, weapons
        _addBoxTypeToCombo(101, 1); // characters
        _addBoxTypeToCombo(101, 2); // cars
        _addBoxTypeToCombo(101, 3); // weapons

        _addComboType(102); // Combo characters, cars
        _addBoxTypeToCombo(102, 1); // characters
        _addBoxTypeToCombo(102, 2); // cars

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(CAP_MANAGER_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(CONTRACT_UPGRADER, _msgSender());
    }

    modifier onlySupportedBoxType(uint256 boxType_) {
        require(
            _supportedBoxTypes.contains(boxType_),
            "DragonKartNFT: unsupported box type"
        );
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId_) {
        require(
            nftCore.ownerOf(tokenId_) == _msgSender(),
            "DragonKartNFT: caller is not owner"
        );
        _;
    }

    modifier onlyMysteryBox(uint256 tokenId_) {
        (bytes32 _dna, ) = nftCore.tokenMetaData(tokenId_);
        require(_dna == 0, "DragonKartNFT: token is already unboxed");
        _;
    }

    modifier onlyExistedToken(uint256 tokenId_) {
        require(
            nftCore.exists(tokenId_),
            "DragonKartNFT: token does not exists"
        );
        _;
    }

    function _getBitMask(uint256 lsbIndex_, uint256 length_)
        private
        pure
        returns (uint256)
    {
        return ((1 << length_) - 1) << lsbIndex_;
    }

    function _clearBits(
        uint256 data_,
        uint256 lsbIndex_,
        uint256 length_
    ) private pure returns (uint256) {
        return data_ & (~_getBitMask(lsbIndex_, length_));
    }

    function _getArtifactValue(
        uint256 artifacts_,
        uint256 lsbIndex_,
        uint256 length_
    ) private pure returns (uint256) {
        return (artifacts_ & _getBitMask(lsbIndex_, length_)) >> lsbIndex_;
    }

    function _addArtifactValue(
        uint256 artifacts_,
        uint256 lsbIndex_,
        uint256 length_,
        uint256 artifactValue_
    ) private pure returns (uint256) {
        return
            ((artifactValue_ << lsbIndex_) & _getBitMask(lsbIndex_, length_)) |
            _clearBits(artifacts_, lsbIndex_, length_);
    }

    function _addComboType(uint256 comboType_) private {
        require(comboType_ > 100);
        require(_supportedBoxTypes.add(comboType_));
    }

    function _addBoxTypeToCombo(uint256 comboType_, uint256 boxType_) private {
        require(comboType_ > 100);
        require(
            _supportedBoxTypes.contains(comboType_) &&
                _supportedBoxTypes.contains(boxType_)
        );
        require(comboType_ != boxType_);
        _comboToBoxes[comboType_].push(boxType_);
    }

    function _mint(address to_, uint256 boxType_) private {
        uint256 _tokenId = nftCore.mint(to_);
        (, uint256 _artifacts) = nftCore.tokenMetaData(_tokenId);

        // Add box type: size 1 byte
        _artifacts = _addArtifactValue(_artifacts, 0, 8, boxType_);

        // Add item level: size 1 byte
        _artifacts = _addArtifactValue(_artifacts, 8, 8, uint256(1));

        nftCore.updateTokenMetaData(_tokenId, _artifacts);
    }

    function _mintSpecificToken(
        address to_,
        uint256 boxType_,
        uint256 level_,
        uint256 itemId_
    ) private {
        uint256 _tokenId = nftCore.mint(to_);
        (, uint256 _artifacts) = nftCore.tokenMetaData(_tokenId);

        // Add box type: size 1 byte
        _artifacts = _addArtifactValue(_artifacts, 0, 8, boxType_);

        // Add item level: size 1 byte
        _artifacts = _addArtifactValue(_artifacts, 8, 8, level_);

        // add item type: size 1 byte
        _artifacts = _addArtifactValue(_artifacts, 16, 8, boxType_);

        // add item id: size 2 byte
        _artifacts = _addArtifactValue(_artifacts, 24, 16, itemId_);

        uint256 _artifactsLength = itemFactory.artifactsLength(boxType_);

        for (uint256 _index = 0; _index < _artifactsLength; _index++) {
            // add artifact id
            uint256 _artifactId = itemFactory.artifactIdAt(boxType_, _index);
            _artifacts = _addArtifactValue(
                _artifacts,
                40 + _index * 24,
                8,
                _artifactId
            );

            // add artifact value
            uint256 _artifactValue = itemFactory.getRandomArtifactValue(
                uint256(blockhash(block.number - 1)),
                _artifactId
            );
            _artifacts = _addArtifactValue(
                _artifacts,
                48 + _index * 24,
                16,
                _artifactValue
            );
        }

        nftCore.updateTokenMetaData(_tokenId, _artifacts);
    }

    // NFT core features
    function upgradeContract(address newContract_)
        external
        onlyRole(CONTRACT_UPGRADER)
    {
        nftCore.transferOwnership(newContract_);
    }

    function increaseCap(uint256 amount_) external onlyRole(CAP_MANAGER_ROLE) {
        nftCore.increaseCap(amount_);
    }

    function updateBaseTokenURI(string memory baseTokenURI_)
        external
        onlyRole(MANAGER_ROLE)
    {
        nftCore.updateBaseTokenURI(baseTokenURI_);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        nftCore.pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        nftCore.unpause();
    }

    function setNFTUpgrader(address upgrader_) external onlyRole(MANAGER_ROLE) {
        _setupRole(NFT_UPGRADER, upgrader_);
    }

    // Governance contract features
    function updateItemFactory(address itemFactory_)
        public
        onlyRole(CONTRACT_UPGRADER)
    {
        require(
            itemFactory_ != address(0),
            "DragonKartNFT: itemFactory_ is the zero address"
        );

        _updateItemFactory(itemFactory_);
    }

    function updateRandomGenerator(address randomGenerator_)
        public
        onlyRole(CONTRACT_UPGRADER)
    {
        require(
            randomGenerator_ != address(0),
            "DragonKartNFT: randomGenerator_ is the zero address"
        );

        _updateRandomGenerator(randomGenerator_);
    }

    function updateRandomFee(uint256 randomFee_) public onlyRole(MANAGER_ROLE) {
        _updateRandomFee(randomFee_);
    }

    function mint(address to_, uint256 boxType_)
        public
        onlyRole(MINTER_ROLE)
        onlySupportedBoxType(boxType_)
    {
        _mint(to_, boxType_);
    }

    function mintSpecificToken(
        address to_,
        uint256 boxType_,
        uint256 level_,
        uint256 itemId_
    ) public onlyRole(MINTER_ROLE) onlySupportedBoxType(boxType_) {
        _mintSpecificToken(to_, boxType_, level_, itemId_);
    }

    function mintBatch(
        address to_,
        uint256 boxType_,
        uint256 amount_
    ) external onlyRole(MINTER_ROLE) onlySupportedBoxType(boxType_) {
        require(amount_ > 0, "DragonKartNFT: amount_ is 0");
        require(
            nftCore.totalSupply() + amount_ <= nftCore.cap(),
            "cap exceeded"
        );

        for (uint256 _index = 0; _index < amount_; _index++) {
            _mint(to_, boxType_);
        }
    }

    function unbox(uint256 tokenId_)
        public
        payable
        onlyExistedToken(tokenId_)
        onlyTokenOwner(tokenId_)
        onlyMysteryBox(tokenId_)
    {
        (, uint256 _artifacts) = nftCore.tokenMetaData(tokenId_);
        uint256 _boxType = _getArtifactValue(_artifacts, 0, 8);

        // Check if box is combo
        if (_boxType > 100) {
            uint256[] storage boxTypes = _comboToBoxes[_boxType];
            _boxType = boxTypes[0];
            _artifacts = _addArtifactValue(_artifacts, 0, 8, _boxType);
            nftCore.updateTokenMetaData(tokenId_, _artifacts);
            for (uint256 _index = 1; _index < boxTypes.length; _index++) {
                _mint(_msgSender(), boxTypes[_index]);
            }
        } else {
            require(
                _tokenIdToUnboxBlockNumber[tokenId_] == uint256(0) ||
                    _tokenIdToUnboxBlockNumber[tokenId_] <
                    block.number - MAX_UNBOX_BLOCK_COUNT,
                "NFT: token is unboxing"
            );
            _tokenIdToUnboxBlockNumber[tokenId_] = block.number;

            _takeRandomFee();
            randomGenerator.requestRandomNumber(tokenId_);
            emit UnboxToken(tokenId_);
        }
    }

    function fulfillRandomness(uint256 tokenId_, uint256 randomness_)
        internal
        override(RandomConsumerBase)
    {
        (bytes32 _dna, uint256 _artifacts) = nftCore.tokenMetaData(tokenId_);
        _dna = bytes32(keccak256(abi.encodePacked(tokenId_, randomness_)));

        uint256 _boxType = _getArtifactValue(_artifacts, 0, 8);
        (uint256 _itemId, uint256 _itemType) = itemFactory.getRandomItem(
            randomness_,
            _boxType
        );
        _artifacts = _addArtifactValue(_artifacts, 16, 8, _itemType); // add itemType
        _artifacts = _addArtifactValue(_artifacts, 24, 16, _itemId); // add itemId

        uint256 _artifactsLength = itemFactory.artifactsLength(_itemType);

        for (uint256 _index = 0; _index < _artifactsLength; _index++) {
            // add artifact id
            uint256 _artifactId = itemFactory.artifactIdAt(_itemType, _index);
            _artifacts = _addArtifactValue(
                _artifacts,
                40 + _index * 24,
                8,
                _artifactId
            );

            uint256 _randomness = uint256(
                keccak256(
                    abi.encodePacked(
                        randomness_,
                        block.number,
                        _itemType,
                        _artifactId,
                        _index
                    )
                )
            );

            // add artifact value
            uint256 _artifactValue = itemFactory.getRandomArtifactValue(
                _randomness,
                _artifactId
            );
            _artifacts = _addArtifactValue(
                _artifacts,
                48 + _index * 24,
                16,
                _artifactValue
            );
        }

        delete _tokenIdToUnboxBlockNumber[tokenId_];

        nftCore.updateTokenMetaData(tokenId_, _artifacts, _dna);
        emit TokenFulfilled(tokenId_);
    }

    function addBoxType(uint256 boxType_) external onlyRole(MANAGER_ROLE) {
        require(boxType_ > 0 && boxType_ <= 100);
        bool success = _supportedBoxTypes.add(boxType_);
        require(success, "DragonKartNFT: box type is already supported");
    }

    function addComboType(uint256 comboType_) external onlyRole(MANAGER_ROLE) {
        _addComboType(comboType_);
    }

    function addBoxTypeToCombo(uint256 comboType_, uint256 boxType_) external {
        _addBoxTypeToCombo(comboType_, boxType_);
    }

    function boxTypesIncombo(uint256 comboType_)
        external
        view
        returns (uint256[] memory)
    {
        return _comboToBoxes[comboType_];
    }

    function supportedBoxTypes() external view returns (uint256[] memory) {
        return _supportedBoxTypes.values();
    }

    // Reserve
    // Only NFT upgrader contract can call this function
    function upgradeNFT(uint256 tokenId_, uint256 artifacts_)
        external
        onlyRole(NFT_UPGRADER)
    {
        nftCore.updateTokenMetaData(tokenId_, artifacts_);
    }
}

 
interface INFTUpgrade {
    function upgrade(
        uint256[] memory tokenIds_,
        uint256[] memory charmTokenIds_,
        uint256 upgradeId_
    ) external payable returns (uint256);
}

 
contract DragonKartNFTUpgrade is
    INFTUpgrade,
    AccessControlEnumerable,
    RandomConsumerBase,
    ItemFactoryManager
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant CONTRACT_UPGRADER = keccak256("CONTRACT_UPGRADER");
    bytes32 public constant RATIO_CONTROL_ROLE =
        keccak256("RATIO_CONTROL_ROLE");
    bytes32 public constant ARTIFACTS_UPDATE_ROLE =
        keccak256("ARTIFACTS_UPDATE_ROLE");

    DragonKartNFTCore private immutable _nftCore;
    DragonKartNFTManager private _dragonKartManager;
    uint256 private _enhancementRatioRate;
    uint256 private _transformationRatioRate;
    uint256 private _cloningRatioRate;
    uint256 private _randomness;

    event SetEnhancementRatioRate(uint256 ratioRate);
    event SetFusionRatioRate(uint256 ratioRate);
    event SetTransformationRatioRate(uint256 ratioRate);
    event SetCloningRatioRate(uint256 ratioRate);

    constructor(
        address nftCore_,
        address nftManger_,
        address itemFactory_,
        address randomGenerator_,
        uint256 randomFee_
    )
        RandomConsumerBase(randomGenerator_, randomFee_)
        ItemFactoryManager(itemFactory_)
    {
        _dragonKartManager = DragonKartNFTManager(nftManger_);
        _nftCore = DragonKartNFTCore(nftCore_);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(CONTRACT_UPGRADER, _msgSender());
        _setupRole(RATIO_CONTROL_ROLE, _msgSender());
        _setupRole(ARTIFACTS_UPDATE_ROLE, _msgSender());
    }

    modifier onlyTokenOwner(uint256 tokenId_) {
        require(
            _nftCore.ownerOf(tokenId_) == _msgSender(),
            "Upgrade: caller is not owner."
        );
        _;
    }

    function _getBitMask(uint256 lsbIndex_, uint256 length_)
        private
        pure
        returns (uint256)
    {
        return ((1 << length_) - 1) << lsbIndex_;
    }

    function _clearBits(
        uint256 data_,
        uint256 lsbIndex_,
        uint256 length_
    ) private pure returns (uint256) {
        return data_ & (~_getBitMask(lsbIndex_, length_));
    }

    function _getArtifactValue(
        uint256 artifacts_,
        uint256 lsbIndex_,
        uint256 length_
    ) private pure returns (uint256) {
        return (artifacts_ & _getBitMask(lsbIndex_, length_)) >> lsbIndex_;
    }

    function _addArtifactValue(
        uint256 artifacts_,
        uint256 lsbIndex_,
        uint256 length_,
        uint256 artifactValue_
    ) private pure returns (uint256) {
        return
            ((artifactValue_ << lsbIndex_) & _getBitMask(lsbIndex_, length_)) |
            _clearBits(artifacts_, lsbIndex_, length_);
    }

    // Governance contract features
    function mint(address to_, uint256 boxType_) public onlyRole(MINTER_ROLE) {
        _dragonKartManager.mint(to_, boxType_);
    }

    function mintBatch(
        address to_,
        uint256 boxType_,
        uint256 amount_
    ) external onlyRole(MINTER_ROLE) {
        _dragonKartManager.mintBatch(to_, boxType_, amount_);
    }

    function updateLevelBatch(uint256[] memory tokenIds_, uint256 level_)
        public
        onlyRole(ARTIFACTS_UPDATE_ROLE)
    {
        require(tokenIds_.length > 0, "Upgrade: tokenId array is empty.");
        require(level_ > 0, "Upgrade: level_ is 0.");
        for (uint256 _index = 0; _index < tokenIds_.length; _index++) {
            (, uint256 _artifacts) = _nftCore.tokenMetaData(tokenIds_[_index]);
            _artifacts = _addArtifactValue(_artifacts, 8, 8, level_);
            _dragonKartManager.upgradeNFT(tokenIds_[_index], _artifacts);
        }
    }

    function updateItemIdBatch(uint256[] memory tokenIds_, uint256 itemId_)
        public
        onlyRole(ARTIFACTS_UPDATE_ROLE)
    {
        require(tokenIds_.length > 0, "Upgrade: tokenId array is empty.");
        require(itemId_ > 0, "Upgrade: itemId_ is 0.");
        for (uint256 _index = 0; _index < tokenIds_.length; _index++) {
            (, uint256 _artifacts) = _nftCore.tokenMetaData(tokenIds_[_index]);
            require(
                _getArtifactValue(_artifacts, 16, 8) == 10,
                "Upgrade: one of input token is not a upgrade token."
            );
            _addArtifactValue(_artifacts, 24, 16, itemId_);
            _dragonKartManager.upgradeNFT(tokenIds_[_index], _artifacts);
        }
    }

    function setEnhancementRatioRate(uint256 ratioRate_)
        external
        onlyRole(RATIO_CONTROL_ROLE)
    {
        _enhancementRatioRate = ratioRate_;
        emit SetEnhancementRatioRate(ratioRate_);
    }

    function setTransformationRatioRate(uint256 ratioRate_)
        external
        onlyRole(RATIO_CONTROL_ROLE)
    {
        _transformationRatioRate = ratioRate_;
        emit SetTransformationRatioRate(ratioRate_);
    }

    function setCloningRatioRate(uint256 ratioRate_)
        external
        onlyRole(RATIO_CONTROL_ROLE)
    {
        _cloningRatioRate = ratioRate_;
        emit SetCloningRatioRate(ratioRate_);
    }

    function updateItemFactory(address itemFactory_)
        public
        onlyRole(CONTRACT_UPGRADER)
    {
        require(
            itemFactory_ != address(0),
            "Upgrade: itemFactory_ is the zero address."
        );

        _updateItemFactory(itemFactory_);
    }

    function updateRandomGenerator(address randomGenerator_)
        public
        onlyRole(CONTRACT_UPGRADER)
    {
        require(
            randomGenerator_ != address(0),
            "Upgrade: randomGenerator_ is the zero address"
        );

        _updateRandomGenerator(randomGenerator_);
    }

    function updateManager(address nftManager_)
        public
        onlyRole(CONTRACT_UPGRADER)
    {
        require(
            nftManager_ != address(0),
            "Upgrade: dragonKartManager_ is the zero address"
        );
        _dragonKartManager = DragonKartNFTManager(nftManager_);
    }

    // function updateNFTCore(address nftCore_)
    //     public
    //     onlyRole(CONTRACT_UPGRADER)
    // {
    //     require(
    //         nftCore_ != address(0),
    //         "Upgrade: nftCore_ is the zero address"
    //     );
    //     _nftCore = DragonKartNFTCore(nftCore_);
    // }

    function updateRandomFee(uint256 randomFee_)
        public
        onlyRole(CONTRACT_UPGRADER)
    {
        _updateRandomFee(randomFee_);
    }

    function fulfillRandomness(uint256 tokenId_, uint256 randomness_)
        internal
        override(RandomConsumerBase)
    {
        _randomness =
            (uint256(keccak256(abi.encodePacked(tokenId_, randomness_))) %
                100) +
            1;
    }

    //upgrade functions
    function _validatingCharm(uint256[] memory charmTokenIds_)
        private
        view
        returns (uint256)
    {
        if(charmTokenIds_.length > 0){
            (, uint256 _charmArtifacts1) = _nftCore.tokenMetaData(
                charmTokenIds_[0]
            );
            uint256 _charmType1 = _getArtifactValue(_charmArtifacts1, 16, 8);
            uint256 _charmId1 = _getArtifactValue(_charmArtifacts1, 24, 16);
            require(
                _charmType1 == 10 && _charmId1 >= 5 && _charmId1 <= 6,
                "Upgrade: 1st token can not use as charm for this upgrade"
            );
            (, uint256 _charmArtifacts2) = _nftCore.tokenMetaData(
                charmTokenIds_[1]
            );
            uint256 _charmType2 = _getArtifactValue(_charmArtifacts2, 16, 8);
            uint256 _charmId2 = _getArtifactValue(_charmArtifacts2, 24, 16);
            require(
                _charmType2 == 10 && _charmId2 >= 5 && _charmId2 <= 6,
                "Upgrade: 2nd token can not use as charm for this upgrade"
            );
            require(
                _charmId1 != _charmId2,
                "Upgrade: 1st charm is the same as 2nd charm"
            );
            if (_charmId1 == 5 || _charmId2 == 5) {
            return uint256(25);
            }
        }
        return uint256(0);
    }

    function _calculateEnhancementSuccessRate(
        uint256 level_,
        uint256 upgradeLevel_,
        uint256[] memory charmTokenIds_
    ) private view returns (uint256) {
        return
            (_enhancementRatioRate +
                uint256(75) *
                upgradeLevel_ +
                _validatingCharm(charmTokenIds_)) / level_;
    }

    function _calculateTransformationSuccessRate(
        uint256 level_,
        uint256 upgradeLevel_,
        uint256[] memory charmTokenIds_
    ) private view returns (uint256) {
        return
            (_transformationRatioRate +
                uint256(75) *
                upgradeLevel_ +
                _validatingCharm(charmTokenIds_)) / level_;
    }

    function _calculateCloningSuccessRate(
        uint256 level_,
        uint256 upgradeLevel_,
        uint256[] memory charmTokenIds_
    ) private view returns (uint256) {
        return
            (_cloningRatioRate +
                uint256(75) *
                upgradeLevel_ +
                _validatingCharm(charmTokenIds_)) / level_;
    }

    function _createRandomAccessory(
        uint256 artifacts_,
        uint256 itemType_
    ) private view returns(uint256){
        uint256 _artifactsLength = itemFactory.artifactsLength(itemType_);

        for (uint256 _index = 0; _index < _artifactsLength; _index++) {
            // add artifact id
            uint256 _artifactId = itemFactory.artifactIdAt(itemType_, _index);
            artifacts_ = _addArtifactValue(
                artifacts_,
                40 + _index * 24,
                8,
                _artifactId
            );

            uint256 _randomnessEncode = uint256(
                keccak256(
                    abi.encodePacked(
                        _randomness,
                        block.number,
                        itemType_,
                        _artifactId,
                        _index
                    )
                )
            );

            // add artifact value
            uint256 _artifactValue = itemFactory.getRandomArtifactValue(
                _randomnessEncode,
                _artifactId
            );
            artifacts_ = _addArtifactValue(
                artifacts_,
                48 + _index * 24,
                16,
                _artifactValue
            );
        }
        return artifacts_;
    }

    function _echancement(
        uint256 tokenId_,
        uint256 artifacts_,
        uint256[] memory charmTokenIds_,
        bool isSucceeding_
    ) private returns (uint256) {
        bool _isUsingMagicCharm;
        if(charmTokenIds_.length > 0){
            (, uint256 _charmArtifacts1) = _nftCore.tokenMetaData(
                charmTokenIds_[0]
            );
            uint256 _charmId1 = _getArtifactValue(_charmArtifacts1, 24, 16);
            (, uint256 _charmArtifacts2) = _nftCore.tokenMetaData(
                charmTokenIds_[1]
            );
            uint256 _charmId2 = _getArtifactValue(_charmArtifacts2, 24, 16);

            _isUsingMagicCharm = (_charmId1 == 6 || _charmId2 == 6);
        }
        uint256 _level = _getArtifactValue(artifacts_, 8, 8);
        if (isSucceeding_) {
            artifacts_ = _addArtifactValue(artifacts_, 8, 8, _level + 1);
        } else if (!_isUsingMagicCharm) {
            artifacts_ = _addArtifactValue(artifacts_, 8, 8, _level - 1);
        }
        _dragonKartManager.upgradeNFT(tokenId_, artifacts_);
        return tokenId_;
    }

    function _transformation(
        uint256 tokenId_,
        uint256 artifacts_,
        bool isSucceeding_
    ) private returns (uint256) {
        uint256 _itemType = _getArtifactValue(artifacts_, 16, 8);

        (uint256 _itemId, ) = itemFactory.getRandomItem(
            _randomness,
            _itemType
        );
        if (isSucceeding_) {
            //add itemid of new token
            artifacts_ = _addArtifactValue(artifacts_, 24, 16, _itemId);
            //create random accessory
            artifacts_ = _createRandomAccessory(artifacts_, _itemType);
            _dragonKartManager.upgradeNFT(tokenId_, artifacts_);
        }
        return tokenId_;
    }

    function _cloning(
        uint256 tokenId_,
        uint256 artifacts_,
        uint256 upgradeId_,
        uint256 upgradeArtifacts_,
        bool isSucceeding_
    ) private returns (uint256) {
        if (isSucceeding_) {
            uint256 _itemType = _getArtifactValue(artifacts_, 16, 8);
            upgradeArtifacts_ = artifacts_;

            //create random accessory
            upgradeArtifacts_ = _createRandomAccessory(upgradeArtifacts_, _itemType);
            _dragonKartManager.upgradeNFT(upgradeId_, upgradeArtifacts_);
            return upgradeId_;
        } else {
            return tokenId_;
        }
    }

    function upgrade(
        uint256[] memory tokenIds_,
        uint256[] memory charmTokenIds_,
        uint256 upgradeId_
    ) external payable onlyTokenOwner(tokenIds_[0]) returns (uint256) {
        require(
            tokenIds_.length == 1,
            "Upgrade: contract only needed 1 input token."
        );
        require(
            tokenIds_[0] > 0,
            "Upgrade: token id is 0."
        );

        (, uint256 _artifacts) = _nftCore.tokenMetaData(tokenIds_[0]);
        uint256 _level = _getArtifactValue(_artifacts, 8, 8);

        (, uint256 _upgradeArtifacts) = _nftCore.tokenMetaData(upgradeId_);
        uint256 _upgradeType = _getArtifactValue(_upgradeArtifacts, 16, 8);
        uint256 _upgradeId = _getArtifactValue(_upgradeArtifacts, 24, 16);
        uint256 _upgradeLevel = _getArtifactValue(_upgradeArtifacts, 8, 8);

        require(
            _upgradeType == 10 && _upgradeId >= 1 && _upgradeId <= 4,
            "Upgrade: Token is not an upgrade"
        );

        _takeRandomFee();
        randomGenerator.requestRandomNumber(upgradeId_);

        uint256 _resultToken;
        if (_upgradeId == 1) {
            uint256 _rate = _calculateEnhancementSuccessRate(
                _level,
                _upgradeLevel,
                charmTokenIds_
            );
            bool _isSucceeding = _randomness > 0 && _randomness <= _rate;
            _resultToken = _echancement(
                tokenIds_[0],
                _artifacts,
                charmTokenIds_,
                _isSucceeding
            );
            _nftCore.burn(_upgradeId);
        } else if (_upgradeId == 2) {
            //fusion
        } else if (_upgradeId == 3) {
            uint256 _rate = _calculateTransformationSuccessRate(
                _level,
                _upgradeLevel,
                charmTokenIds_
            );
            bool _isSucceeding = _randomness > 0 && _randomness <= _rate;
            _resultToken = _transformation(
                tokenIds_[0],
                _artifacts,
                _isSucceeding
            );
            _nftCore.burn(_upgradeId);
        } else {
            uint256 _rate = _calculateCloningSuccessRate(
                _level,
                _upgradeLevel,
                charmTokenIds_
            );
            bool _isSucceeding = _randomness > 0 && _randomness <= _rate;
            _resultToken = _cloning(
                tokenIds_[0],
                _artifacts,
                upgradeId_,
                _upgradeArtifacts,
                _isSucceeding
            );
        }
        return _resultToken;
    }
}