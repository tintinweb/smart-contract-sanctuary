/**
 *Submitted for verification at BscScan.com on 2021-11-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

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

interface IERC20Mintable is IERC20 {
    function mint(address to, uint256 amount) external;
}

interface ITokensVesting {
    enum Participant {
        Unknown,
        Seeding,
        PrivateSale,
        PublicSale,
        Team,
        DeFi,
        Marketing,
        Reserve,
        GameIncentives,
        Liquidity,
        Development,
        OutOfRange
    }

    struct VestingInfo {
        uint256 genesisTimestamp;
        uint256 totalAmount;
        uint256 tgeAmount;
        uint256 finalAmount;
        uint256 basis;
        uint256 cliff;
        uint256 duration;
        uint256 releasedAmount;
        address beneficiary;
        bytes32 role;
        Participant participant;
    }

    event BeneficiaryAddressAdded(
        address indexed beneficiary,
        uint256 amount,
        uint8 participant
    );
    event BeneficiaryRoleAdded(
        bytes32 indexed role,
        uint256 amount,
        uint8 participant
    );
    event BeneficiaryRevoked(uint256 indexed index);
    event TokensReleased(address indexed recipient, uint256 amount);

    function addBeneficiary(
        address beneficiary,
        bytes32 role,
        uint256 genesisTimestamp,
        uint256 totalAmount,
        uint256 tgeAmount,
        uint256 finalAmount,
        uint256 basis,
        uint256 cliff,
        uint256 duration,
        uint8 participant
    ) external returns (uint256);

    function token() external view returns (IERC20Mintable);

    function releaseAll() external;

    function releaseParticipant(uint8 participant) external;

    function releaseMyTokens() external;

    function releaseTokensOfRole(bytes32 role, uint256 amount) external;

    function release(uint256 index) external;

    function revokeTokensOfParticipant(uint8 participant) external;

    function revokeTokensOfAddress(address beneficiary) external;

    function revokeTokensOfRole(bytes32 role) external;

    function revoke(uint256 index) external;

    function releasableAmount() external view returns (uint256);

    function releasableAmountOfParticipant(uint8 participant)
        external
        view
        returns (uint256);

    function releasableAmountOfAddress(address beneficiary)
        external
        view
        returns (uint256);

    function releasableAmountOfRole(bytes32 role)
        external
        view
        returns (uint256);

    function releasableAmountAt(uint256 index) external view returns (uint256);

    function totalAmount() external view returns (uint256);

    function totalAmountOfParticipant(uint8 participant)
        external
        view
        returns (uint256);

    function totalAmountOfAddress(address beneficiary)
        external
        view
        returns (uint256);

    function totalAmountOfRole(bytes32 role) external view returns (uint256);

    function totalAmountAt(uint256 index) external view returns (uint256);

    function releasedAmount() external view returns (uint256);

    function releasedAmountOfParticipant(uint8 participant)
        external
        view
        returns (uint256);

    function releasedAmountOfAddress(address beneficiary)
        external
        view
        returns (uint256);

    function releasedAmountOfRole(bytes32 role) external view returns (uint256);

    function releasedAmountAt(uint256 index) external view returns (uint256);

    function vestingInfoAt(uint256 index)
        external
        view
        returns (VestingInfo memory);

    function indexesOfBeneficiary(address beneficiary)
        external
        view
        returns (uint256[] memory);

    function indexesOfRole(bytes32 role)
        external
        view
        returns (uint256[] memory);

    function revokedIndexes() external view returns (uint256[] memory);
}

contract TokensVesting is AccessControlEnumerable, ITokensVesting {
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");
    bytes32 public constant DEFI_ROLE = keccak256("DEFI_ROLE");
    bytes32 public constant GAME_INCENTIVES_ROLE =
        keccak256("GAME_INCENTIVES_ROLE");

    IERC20Mintable public immutable token;

    VestingInfo[] private _beneficiaries;
    mapping(address => EnumerableSet.UintSet)
        private _beneficiaryAddressIndexes;
    mapping(bytes32 => EnumerableSet.UintSet) private _beneficiaryRoleIndexes;
    EnumerableSet.UintSet private _revokedBeneficiaryIndexes;

    constructor(address token_) {
        require(
            token_ != address(0),
            "TokensVesting::constructor: _token is the zero address!"
        );
        token = IERC20Mintable(token_);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MAINTAINER_ROLE, _msgSender());
    }

    function _addBeneficiary(
        address beneficiary_,
        bytes32 role_,
        uint256 genesisTimestamp_,
        uint256 totalAmount_,
        uint256 tgeAmount_,
        uint256 finalAmount_,
        uint256 basis_,
        uint256 cliff_,
        uint256 duration_,
        uint8 participant_
    ) private returns (uint256 _index) {
        require(
            beneficiary_ != address(0) || role_ != 0,
            "TokensVesting: must specify beneficiary or role"
        );

        if (beneficiary_ != address(0)) {
            VestingInfo storage _info = _beneficiaries.push();
            _info.beneficiary = beneficiary_;
            _info.genesisTimestamp = genesisTimestamp_;
            _info.totalAmount = totalAmount_;
            _info.tgeAmount = tgeAmount_;
            _info.finalAmount = finalAmount_;
            _info.basis = basis_;
            _info.cliff = cliff_;
            _info.duration = duration_;
            _info.participant = Participant(participant_);

            _index = _beneficiaries.length - 1;

            require(
                _beneficiaryAddressIndexes[beneficiary_].add(_index),
                "TokensVesting: Duplicated index"
            );

            emit BeneficiaryAddressAdded(
                beneficiary_,
                totalAmount_,
                participant_
            );
        } else {
            VestingInfo storage _info = _beneficiaries.push();
            _info.role = role_;
            _info.genesisTimestamp = genesisTimestamp_;
            _info.totalAmount = totalAmount_;
            _info.tgeAmount = tgeAmount_;
            _info.finalAmount = finalAmount_;
            _info.basis = basis_;
            _info.cliff = cliff_;
            _info.duration = duration_;
            _info.participant = Participant(participant_);

            _index = _beneficiaries.length - 1;

            require(
                _beneficiaryRoleIndexes[role_].add(_index),
                "TokensVesting: Duplicated index"
            );

            emit BeneficiaryRoleAdded(role_, totalAmount_, participant_);
        }
    }

    function _vestedAmount(uint256 index_) private view returns (uint256) {
        VestingInfo storage _info = _beneficiaries[index_];

        if (block.timestamp < _info.genesisTimestamp) {
            return 0;
        }

        uint256 _elapsedTime = block.timestamp - _info.genesisTimestamp;
        if (_elapsedTime < _info.cliff) {
            return _info.tgeAmount;
        }

        if (_elapsedTime >= _info.cliff + _info.duration) {
            return _info.totalAmount;
        }

        uint256 _releaseMilestones = (_elapsedTime - _info.cliff) /
            _info.basis +
            1;
        uint256 _totalReleaseMilestones = (_info.duration + _info.basis - 1) /
            _info.basis +
            1;

        if (_releaseMilestones >= _totalReleaseMilestones) {
            return _info.totalAmount;
        }

        // _totalReleaseMilestones > 1
        uint256 _linearVestingAmount = _info.totalAmount -
            _info.tgeAmount -
            _info.finalAmount;
        return
            (_linearVestingAmount / (_totalReleaseMilestones - 1)) *
            _releaseMilestones +
            _info.tgeAmount;
    }

    function _releasableAmount(uint256 index_) private view returns (uint256) {
        if (_revokedBeneficiaryIndexes.contains(index_)) {
            return 0;
        }

        VestingInfo storage _info = _beneficiaries[index_];
        return _vestedAmount(index_) - _info.releasedAmount;
    }

    function _releaseAll() private {
        for (uint256 _index = 0; _index < _beneficiaries.length; _index++) {
            VestingInfo storage _info = _beneficiaries[_index];
            if (_info.beneficiary != address(0)) {
                uint256 _unreleaseAmount = _releasableAmount(_index);
                if (_unreleaseAmount > 0) {
                    _info.releasedAmount =
                        _info.releasedAmount +
                        _unreleaseAmount;
                    token.mint(_info.beneficiary, _unreleaseAmount);
                    emit TokensReleased(_info.beneficiary, _unreleaseAmount);
                }
            }
        }
    }

    function _releaseParticipant(uint8 participant_) private {
        for (uint256 _index = 0; _index < _beneficiaries.length; _index++) {
            VestingInfo storage _info = _beneficiaries[_index];
            if (
                _info.beneficiary != address(0) &&
                uint8(_info.participant) == participant_
            ) {
                uint256 _unreleaseAmount = _releasableAmount(_index);
                if (_unreleaseAmount > 0) {
                    _info.releasedAmount =
                        _info.releasedAmount +
                        _unreleaseAmount;
                    token.mint(_info.beneficiary, _unreleaseAmount);
                    emit TokensReleased(_info.beneficiary, _unreleaseAmount);
                }
            }
        }
    }

    function _release(uint256 index_, address recipient_) private {
        VestingInfo storage _info = _beneficiaries[index_];
        uint256 _unreleaseAmount = _releasableAmount(index_);
        if (_unreleaseAmount > 0) {
            _info.releasedAmount = _info.releasedAmount + _unreleaseAmount;
            token.mint(recipient_, _unreleaseAmount);
            emit TokensReleased(recipient_, _unreleaseAmount);
        }
    }

    /**
     * Only call this function when releasableAmountOfRole >= amount_
     */
    function _releaseTokensOfRole(
        bytes32 role_,
        uint256 amount_,
        address reicipient_
    ) private {
        uint256 _amountToRelease = amount_;

        for (
            uint256 _index = 0;
            _index < _beneficiaryRoleIndexes[role_].length();
            _index++
        ) {
            uint256 _beneficiaryIndex = _beneficiaryRoleIndexes[role_].at(
                _index
            );
            VestingInfo storage _info = _beneficiaries[_beneficiaryIndex];
            uint256 _unreleaseAmount = _releasableAmount(_beneficiaryIndex);

            if (_unreleaseAmount > 0) {
                if (_unreleaseAmount >= _amountToRelease) {
                    _info.releasedAmount =
                        _info.releasedAmount +
                        _amountToRelease;
                    break;
                } else {
                    _info.releasedAmount =
                        _info.releasedAmount +
                        _unreleaseAmount;
                    _amountToRelease -= _unreleaseAmount;
                }
            }
        }

        token.mint(reicipient_, amount_);
        emit TokensReleased(_msgSender(), amount_);
    }

    function _revoke(uint256 index_) private {
        bool _success = _revokedBeneficiaryIndexes.add(index_);
        if (_success) {
            emit BeneficiaryRevoked(index_);
        }
    }

    function addBeneficiary(
        address beneficiary_,
        bytes32 role_,
        uint256 genesisTimestamp_,
        uint256 totalAmount_,
        uint256 tgeAmount_,
        uint256 finalAmount_,
        uint256 basis_,
        uint256 cliff_,
        uint256 duration_,
        uint8 participant_
    ) external onlyRole(MAINTAINER_ROLE) returns (uint256) {
        require(genesisTimestamp_ > 0, "TokensVesting: genesisTimestamp_ is 0");
        require(
            totalAmount_ >= tgeAmount_ + finalAmount_,
            "TokensVesting: bad args"
        );
        require(basis_ > 0, "TokensVesting: basis_ must be greater than 0");
        require(
            genesisTimestamp_ + cliff_ + duration_ <= type(uint256).max,
            "TokensVesting: out of uint256 range"
        );
        require(
            Participant(participant_) > Participant.Unknown &&
                Participant(participant_) < Participant.OutOfRange,
            "TokensVesting: participant_ out of range"
        );

        return
            _addBeneficiary(
                beneficiary_,
                role_,
                genesisTimestamp_,
                totalAmount_,
                tgeAmount_,
                finalAmount_,
                basis_,
                cliff_,
                duration_,
                participant_
            );
    }

    function releaseAll() external onlyRole(MAINTAINER_ROLE) {
        _releaseAll();
    }

    function releaseParticipant(uint8 participant_)
        external
        onlyRole(MAINTAINER_ROLE)
    {
        _releaseParticipant(participant_);
    }

    function releaseMyTokens() external {
        require(
            _beneficiaryAddressIndexes[_msgSender()].length() > 0,
            "TokensVesting: sender is not in vesting plan"
        );

        for (
            uint256 _index = 0;
            _index < _beneficiaryAddressIndexes[_msgSender()].length();
            _index++
        ) {
            uint256 _beneficiaryIndex = _beneficiaryAddressIndexes[_msgSender()]
                .at(_index);
            VestingInfo storage _info = _beneficiaries[_beneficiaryIndex];

            uint256 _unreleaseAmount = _releasableAmount(_beneficiaryIndex);
            if (_unreleaseAmount > 0) {
                _info.releasedAmount = _info.releasedAmount + _unreleaseAmount;
                token.mint(_msgSender(), _unreleaseAmount);
                emit TokensReleased(_msgSender(), _unreleaseAmount);
            }
        }
    }

    function releaseTokensOfRole(bytes32 role_, uint256 amount_) external {
        require(
            hasRole(role_, _msgSender()),
            "TokensVesting: unauthorized sender"
        );
        require(
            releasableAmountOfRole(role_) > 0,
            "TokensVesting: no tokens are due"
        );
        require(
            releasableAmountOfRole(role_) >= amount_,
            "TokensVesting: insufficient amount"
        );

        _releaseTokensOfRole(role_, amount_, _msgSender());
    }

    function release(uint256 index_) external {
        require(
            _beneficiaries[index_].beneficiary != address(0),
            "TokensVesting: bad index_"
        );
        require(
            hasRole(MAINTAINER_ROLE, _msgSender()) ||
                _beneficiaries[index_].beneficiary == _msgSender(),
            "TokensVesting: unauthorized sender"
        );

        _release(index_, _beneficiaries[index_].beneficiary);
    }

    function revokeTokensOfParticipant(uint8 participant_)
        external
        onlyRole(MAINTAINER_ROLE)
    {
        for (uint256 _index = 0; _index < _beneficiaries.length; _index++) {
            if (uint8(_beneficiaries[_index].participant) == participant_) {
                _revoke(_index);
            }
        }
    }

    function revokeTokensOfAddress(address beneficiary_)
        external
        onlyRole(MAINTAINER_ROLE)
    {
        for (
            uint256 _index = 0;
            _index < _beneficiaryAddressIndexes[beneficiary_].length();
            _index++
        ) {
            uint256 _addressIndex = _beneficiaryAddressIndexes[beneficiary_].at(
                _index
            );
            _revoke(_addressIndex);
        }
    }

    function revokeTokensOfRole(bytes32 role_)
        external
        onlyRole(MAINTAINER_ROLE)
    {
        for (
            uint256 _index = 0;
            _index < _beneficiaryRoleIndexes[role_].length();
            _index++
        ) {
            uint256 _roleIndex = _beneficiaryRoleIndexes[role_].at(_index);
            _revoke(_roleIndex);
        }
    }

    function revoke(uint256 index_) external onlyRole(MAINTAINER_ROLE) {
        require(
            _revokedBeneficiaryIndexes.add(index_),
            "TokensVesting: already revoked"
        );
        emit BeneficiaryRevoked(index_);
    }

    function releasableAmount() public view returns (uint256 _amount) {
        for (uint256 _index = 0; _index < _beneficiaries.length; _index++) {
            _amount += _releasableAmount(_index);
        }
    }

    function releasableAmountOfParticipant(uint8 participant_)
        public
        view
        returns (uint256 _amount)
    {
        for (uint256 _index = 0; _index < _beneficiaries.length; _index++) {
            if (uint8(_beneficiaries[_index].participant) == participant_) {
                _amount += _releasableAmount(_index);
            }
        }
    }

    function releasableAmountOfAddress(address beneficiary_)
        public
        view
        returns (uint256 _amount)
    {
        for (
            uint256 _index = 0;
            _index < _beneficiaryAddressIndexes[beneficiary_].length();
            _index++
        ) {
            uint256 _addressIndex = _beneficiaryAddressIndexes[beneficiary_].at(
                _index
            );
            _amount += _releasableAmount(_addressIndex);
        }
    }

    function releasableAmountOfRole(bytes32 role_)
        public
        view
        returns (uint256 _amount)
    {
        for (
            uint256 _index = 0;
            _index < _beneficiaryRoleIndexes[role_].length();
            _index++
        ) {
            uint256 _roleIndex = _beneficiaryRoleIndexes[role_].at(_index);
            _amount += _releasableAmount(_roleIndex);
        }
    }

    function releasableAmountAt(uint256 index_)
        public
        view
        returns (uint256 _amount)
    {
        return _releasableAmount(index_);
    }

    function totalAmount() public view returns (uint256 _amount) {
        for (uint256 _index = 0; _index < _beneficiaries.length; _index++) {
            _amount += _beneficiaries[_index].totalAmount;
        }
    }

    function totalAmountOfParticipant(uint8 participant_)
        public
        view
        returns (uint256 _amount)
    {
        for (uint256 _index = 0; _index < _beneficiaries.length; _index++) {
            if (uint8(_beneficiaries[_index].participant) == participant_) {
                _amount += _beneficiaries[_index].totalAmount;
            }
        }
    }

    function totalAmountOfAddress(address beneficiary_)
        public
        view
        returns (uint256 _amount)
    {
        for (uint256 _index = 0; _index < _beneficiaries.length; _index++) {
            if (_beneficiaries[_index].beneficiary == beneficiary_) {
                _amount += _beneficiaries[_index].totalAmount;
            }
        }
    }

    function totalAmountOfRole(bytes32 role_)
        public
        view
        returns (uint256 _amount)
    {
        for (uint256 _index = 0; _index < _beneficiaries.length; _index++) {
            if (_beneficiaries[_index].role == role_) {
                _amount += _beneficiaries[_index].totalAmount;
            }
        }
    }

    function totalAmountAt(uint256 index_) public view returns (uint256) {
        return _beneficiaries[index_].totalAmount;
    }

    function releasedAmount() public view returns (uint256 _amount) {
        for (uint256 _index = 0; _index < _beneficiaries.length; _index++) {
            _amount += _beneficiaries[_index].releasedAmount;
        }
    }

    function releasedAmountOfParticipant(uint8 participant_)
        public
        view
        returns (uint256 _amount)
    {
        for (uint256 _index = 0; _index < _beneficiaries.length; _index++) {
            if (uint8(_beneficiaries[_index].participant) == participant_) {
                _amount += _beneficiaries[_index].releasedAmount;
            }
        }
    }

    function releasedAmountOfAddress(address beneficiary_)
        public
        view
        returns (uint256 _amount)
    {
        for (uint256 _index = 0; _index < _beneficiaries.length; _index++) {
            if (_beneficiaries[_index].beneficiary == beneficiary_) {
                _amount += _beneficiaries[_index].releasedAmount;
            }
        }
    }

    function releasedAmountOfRole(bytes32 role_)
        public
        view
        returns (uint256 _amount)
    {
        for (uint256 _index = 0; _index < _beneficiaries.length; _index++) {
            if (_beneficiaries[_index].role == role_) {
                _amount += _beneficiaries[_index].releasedAmount;
            }
        }
    }

    function releasedAmountAt(uint256 index_) public view returns (uint256) {
        return _beneficiaries[index_].releasedAmount;
    }

    function vestingInfoAt(uint256 index_)
        public
        view
        returns (VestingInfo memory)
    {
        return _beneficiaries[index_];
    }

    function indexesOfBeneficiary(address beneficiary_)
        public
        view
        returns (uint256[] memory)
    {
        return _beneficiaryAddressIndexes[beneficiary_].values();
    }

    function indexesOfRole(bytes32 role_)
        public
        view
        returns (uint256[] memory)
    {
        return _beneficiaryRoleIndexes[role_].values();
    }

    function revokedIndexes() public view returns (uint256[] memory) {
        return _revokedBeneficiaryIndexes.values();
    }
}