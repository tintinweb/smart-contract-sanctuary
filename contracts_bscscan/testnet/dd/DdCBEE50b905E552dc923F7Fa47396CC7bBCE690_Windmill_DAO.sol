/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

// SPDX-License-Identifier: MIT
// Version: 1.0.0
pragma solidity 0.8.10;

// Version: 1.0.0

// Version: 1.0.0

// Version: 1.0.0

interface I_With_DAORole{
    /**
     * DAO_ROLE is able to grant and revoke roles. It can be used when the DAO
     * vote to change some contracts of Windmill.
     */
    function DAO_ROLE() external view returns (bytes32);
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

contract With_DAORole is AccessControlEnumerable, I_With_DAORole{
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");

    constructor(){
        _setRoleAdmin(DAO_ROLE, DAO_ROLE);
        _setupRole(DAO_ROLE, msg.sender);
    }
}
// Version: 1.0.0



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

// Version: 1.0.0

interface I_Math{
    struct Fraction{
        uint256 numerator;
        uint256 denominator;
    }
}

/**
 * @notice Windmill_Power is the ERC20 token (PWR) representing
 * a share of the fund in the Windmill_Fund contract.
 *
 * There is a primary market that value PWR in the form of
 * mint and burn by the Windmill_Fund contract.
 * In exchange of depositing or withdrawing BUSD from the fund,
 * PWR token are minted to or burned from the user address.
 * The minting/burning value of PWR only depends on the total supply
 * in BUSD in the fund related to the total supply of PWR.
 * This mean that PWR will gain primary value only via
 * Windmill traders performance
 *
 * Also, as PWR is an ERC20 token, it can be freely traded, so secondary
 * markets can exist.
 */
interface I_Windmill_Power is I_Math, IAccessControlEnumerable, I_With_DAORole, IERC20{
    /**
     * MINTER_ROLE is able to mint PWR to an address.
     *
     * BURNER_ROLE is able to burn PWR from an address.
     *
     * MOVER_ROLE is able to transfer PWR from an address to another.
     */
    function MINTER_ROLE() external view returns (bytes32);
    function BURNER_ROLE() external view returns (bytes32);
    function MOVER_ROLE() external view returns (bytes32);
    
    /**
     * @notice Allow the Windmill_Fund to mint PWR for an address

     * Windmill_Fund can use this method to buy PWR in exchange of BUSD
     * This do not change the PWR price because there is the corresponding amount of BUSD
     * that have been added to the fund.
     *
     * Windmill_Competition, Windmill_stacking and Windmill_Royalties can alsoo mint PWR
     * for their usage (competition and stacking reward, royalties).
     * These minting will decrease the value of PWR from the Windmill_Fund contract.
     */
    function mintTo(address to, uint256 amount) external;

    /**
     * @notice Allow the Windmill_Fund to burn PWR from an address
     * in exchange of withdrawing BUSD from the fund to the address.

     * When Windmill_Fund use this method, this do not change the PWR price
     * because there is the right amount of BUSD that have been removed
     * from the fund.
     */
    function burnFrom(address from, uint256 amount) external;

    /**
     * @notice Allow the Windmill_Fund to transfert PWR from an address
     * to a trade contract

     * Windmill_Stacking and Windmill_Trade_Manager use this method to lock the PWR from
     * direct withdraw. There is two main reason for this to happen :
     *
     * - PWR are locked from user to Windmill_Trade contract by Windmill_Trade_Manager
     * contract when starting a new trade. The corresponding BUSD from Windmill_Fund are also
     * allocated to the trade. These locked PWR are returned at the end of the trade.
     *
     * - PWR are stacked by the user in Windmill_Stacking. These PWR are returned
     * at the end of the stacking period. Note that returned PWR can be still
     * locked in a trade, that will be returned at the end of trade.
     */
    function transferFromTo(address from, address to, uint256 amount) external;
}// Version: 1.0.0



interface I_With_PWRToken is IAccessControlEnumerable, I_With_DAORole{
    function setPWRToken(I_Windmill_Power token) external;
}

contract With_PWRToken is AccessControlEnumerable, With_DAORole, I_With_PWRToken{
    I_Windmill_Power public PWRToken;

    function setPWRToken(I_Windmill_Power token) external onlyRole(DAO_ROLE){
        PWRToken = token;
    }
}// Version: 1.0.0


// Version: 1.0.0

// Version: 1.0.0



interface I_With_BUSDToken is IAccessControlEnumerable, I_With_DAORole{
    function setBUSDToken(IERC20 token) external;
}// Version: 1.0.0



interface I_With_WBNBToken is IAccessControlEnumerable, I_With_DAORole{
    function setWBNBToken(IERC20 token) external;
}// Version: 1.0.0



interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface PancakeRouter is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface I_With_PancakeRouter is IAccessControlEnumerable, I_With_DAORole{
    function setPancakeRouter(PancakeRouter token) external;
}// Version: 1.0.0

interface I_Payable{
    receive() external payable;
}
// Version: 1.0.0



interface I_Windmill_Trade_Abstract is IAccessControlEnumerable, I_With_DAORole, I_With_BUSDToken{
	function initTrade(address _owner, address _manager, address _fund) external;
	
	function endTrade() external;
	
	function updateNeeded() external view returns (bool);
	
	function update() external;
	
	function estimateBUSDBalance() external view returns (uint256);
}// Version: 1.0.0

// Version: 1.0.0

// Version: 1.0.0



interface I_With_FundContract is IAccessControlEnumerable, I_With_DAORole{
    function setFund(I_Windmill_Fund _fund) external;
}// Version: 1.0.0



interface I_With_DAOAddress is IAccessControlEnumerable, I_With_DAORole{
    function setDAOAddress(address _DAOAddress) external;
}// Version: 1.0.0



interface I_Windmill_Trade_Deployer_Abstract is IAccessControlEnumerable, I_With_DAORole, I_With_BUSDToken{
	function name() external returns (string memory);
	
	function tradeTemplate() external view returns (address);
	
	function setTradeCode(bytes memory bytecode, string memory name) external;
	
	function deployNewTrade(address owner, address manager, address fund) external returns (I_Windmill_Trade_Abstract);
	
	function checkProposal(uint256 id, uint256 paramsUint256, address paramsAddress) external view returns (bool);
	
	function applyProposal(uint256 id, uint256 paramsUint256, address paramsAddress) external;
}

interface I_Windmill_Trade_Manager is I_Math, IAccessControlEnumerable, I_With_DAORole,
                                      I_With_FundContract, I_With_DAOAddress, I_With_BUSDToken{
    struct DeployerData{
        I_Windmill_Trade_Deployer_Abstract deployer;
        bool enabled;
    }
    
    struct TradeData{
        I_Windmill_Trade_Abstract trade;
        address owner;
        uint256 energy;
        bool isActive;
    }
    
    function setMaxLeverage(uint256 numerator, uint256 denominator) external;
    
    function setMinimumBUSDToTrade(uint256 _minimumBUSDToTrade) external;
    
    function setTraderLevel(address addr, uint8 level) external;
    
    function getMaxEnergy(address addr) external view returns (uint256);
    
    function getRemainingEnergy(address addr) external view returns (uint256);
    
    function getEnergyValueBUSD() external view returns (uint256);
    
    function getMinimumEnergyToTrade() external view returns (uint256);
    
    function addTradeDeployer(I_Windmill_Trade_Deployer_Abstract trade) external;
    
    function disableTradeDeployer(uint256 deployerId) external;
    
    function getNbTradeDeployers() external view returns (uint256);
    
    function getNbTrades() external view returns (uint256);
    
    function getTrade(uint256 id) external view returns (TradeData memory);
    
    function getNbOpenTrades() external view returns (uint);
    
    function getOpenTrade(uint openId) external view returns (TradeData memory, uint256);
    
    function getTradeDeployer(uint256 id) external view returns (DeployerData memory);
    
    function startTrade(uint256 deployerId, uint256 nbEnergy) external returns (uint256);
    
    function endTrade(uint256 tradeId) external;
}

interface I_With_TradeManagerContract is IAccessControlEnumerable, I_With_DAORole{
    function setTradeManager(I_Windmill_Trade_Manager _tradeManager) external;
}

/**
 * @notice Windmill_Fund is the contract that store and manage the BUSD used for
 * Windmill activities.
 *
 * The features of this contract are :
 * - Mint/burn PWR in exchange of depositing/withdrawing BUSD.
 * - Send BUSD to a Windmill_Contract trade.
 */
interface I_Windmill_Fund is I_Math, I_Payable, IAccessControlEnumerable, I_With_DAORole,
                             I_With_PWRToken, I_With_BUSDToken, I_With_WBNBToken, I_With_PancakeRouter, I_With_TradeManagerContract{

    function TRADE_MANAGER_ROLE() external view returns (bytes32);
    
    function setUpdaterAddress(address addr) external;
    
    function setWithdrawFees(uint256 numerator, uint256 denominator) external;

    /**
     * Transfer the BUSD of this contract when the DAO
     * change the Windmill_Fund contract.
     */
    function migrateFunds(address newfund) external;

    function getBNBForGasRefund(uint256 amountBNB) external;

    /**
     * Compute the BUSD hold buy Windmill contracts.
     */
    function getFundBUSD() external view returns (uint256);

    /**
     * Compute the BUSD hold buy Windmill contracts.
     */
    function getAvailableBUSD() external view returns (uint256);
    
    function sendBUSDToTrade(I_Windmill_Trade_Abstract trade, uint256 nbBUSD) external;
    
    /**
     * Compute the PWR total supply.
     */
    function getTotalPWR() external view returns (uint256);

    /**
     * Compute The number of PWR that corresponds to "amountBUSD" BUSD.
     */
    function getPWRAmountFromBUSD(uint256 amountBUSD) external view returns (uint256);

    /**
     * Compute The number of BUSD that corresponds to "amountPWR" PWR.
     */
    function getBUSDAmountFromPWR(uint256 amountPWR) external view returns (uint256);

    /**
     * Allow an address to buy PWR at the contract price for "amountBUSD" BUSD.
     * Node that the address must approve the transfer before calling this function.
     */
    function buyPWR(uint256 amountBUSD) external;

    /**
     * Allow an address to sell "amountPWR" PWR at the contract price for BUSD.
     */
    function sellPWR(uint256 amountPWR) external;
}

contract With_FundContract is AccessControlEnumerable, With_DAORole, I_With_FundContract{
    I_Windmill_Fund public fund;

    function setFund(I_Windmill_Fund _fund) external onlyRole(DAO_ROLE){
        fund = _fund;
    }
}// Version: 1.0.0




contract With_TradeManagerContract is AccessControlEnumerable, With_DAORole, I_With_TradeManagerContract{
    I_Windmill_Trade_Manager public tradeManager;

    function setTradeManager(I_Windmill_Trade_Manager _tradeManager) external onlyRole(DAO_ROLE){
        tradeManager = _tradeManager;
    }
}// Version: 1.0.0


contract Math is I_Math{
    /**
     * @notice Compute the number of digits in an uint256 number.
     *
     * Node that if number = 0, it returns 0.
     */
    function numDigits(uint256 number) internal pure returns (uint8) {
        uint8 digits = 0;
        while (number != 0) {
            number /= 10;
            digits++;
        }
        return digits;
    }
    
    function min(uint256 a, uint256 b) internal pure returns (uint256){
        if (a<b){
            return a;
        }
        return b;
    }
}
// Version: 1.0.0

contract Adressable{
    address payable immutable internal thisAddr;

    constructor(){
        thisAddr = payable(address(this));
    }
}

// Version: 1.0.0




/**
 * @notice Windmill_Royalties
 */
interface I_Windmill_Royalty is I_Math, IAccessControlEnumerable, I_With_DAORole, IERC20, I_With_PWRToken{
    function percentPWRRoyaltyMint() external view returns (uint256, uint256);

    function mintTo(address to, uint256 amount) external;

    function setRoyaltyRatio(uint256 numerator, uint256 denominator) external;

    /**
     * @notice The loop length have a maximum of ROY supply (in ether)
     */
    function processRoyalties() external;

    function migrateTo(I_Windmill_Royalty newRoyalty) external;

}// Version: 1.0.0



/**
 * @notice Windmill_Stacking
 */
interface I_Windmill_Stacking is I_Math, IAccessControlEnumerable, I_With_DAORole, I_With_PWRToken{
    struct StackingGroup{
        uint256 nbPWR;
        uint256 nbSPWR;
        uint256 startCycle;
        uint256 endCycle;
        bool stacked;
        address userAddr;
    }

    struct CycleData{
        uint256 sPWRSupply;
        uint256 totalPWRMinted;
    }

    function percentPWRStackingMint() external view returns (uint256, uint256);

    function stackingBonusFactor() external view returns (uint256, uint256);

    function earlyUnstackFeesPercyclePercent() external view returns (uint256, uint256);

    function setCurrentCycle(uint256 _currentCycle) external;

    function setStackingRewardRatio(uint256 numerator, uint256 denominator) external;

    function setStackingBonusRatio(uint256 numerator, uint256 denominator) external;

    function setEarlyUnstackingFeesPercent(uint256 numerator, uint256 denominator) external;

    function getStackedGroups(address addr) external view returns (uint256[] memory);
    
    function stackPWR(uint256 nbPWR, uint256 nbCycle) external;

    function getUnstackFees(uint256 groupId) external view returns (uint256);

    function unstackPWR(uint256 groupId) external;

    function updateCycle(uint256 cycleId) external;

    function updateStackingNeeded() external view returns (bool);
    
    function updateOneStackingNeeded(uint256 groupId) external view returns (bool);

    function updateOneStacking(uint256 groupId) external;

    function updateStacking() external;

}// Version: 1.0.0

// Version: 1.0.0

// Version: 1.0.0


interface I_Gas_Refundable is I_Math{
    struct RefundData{
        uint256 usedGas;
        uint256 refundLastBlock;
    }

    function refundBNBBonusRatio() external view returns (uint256, uint256);

    function getRefundableGas(address addr) external view returns (uint256);

    function isRefundAvailable(address addr) external view returns (bool);

    function refundGas() external;
}// Version: 1.0.0



interface I_With_DAOContract is IAccessControlEnumerable, I_With_DAORole{
    function setDAO(I_Windmill_DAO _DAO) external;
}

interface I_Windmill_Updater is I_Payable, I_Gas_Refundable, IAccessControlEnumerable, I_With_DAORole, I_With_DAOContract, I_With_FundContract,
                            I_With_TradeManagerContract{
    function init() external;
    
    function setRoyaltyAddress(I_Windmill_Royalty _royalty) external;

    function setStackingAddress(I_Windmill_Stacking _stacking) external;

    function setDAOCycleDuration(uint256 duration) external;

    function setStackingCycleDuration(uint256 duration) external;

    function setRoyaltyCycleDuration(uint256 duration) external;
    
    function setUserGovernorStatus(address user, bool isGovernor) external;
    
    function setRefundGasDefaultPrice(uint256 val) external;
    
    function setRefundNbBlockDelay(uint256 val) external;
    
    function setRefundBNBBonusRatio(uint256 numerator) external;
    
    function setRefundNbBNBMin(uint256 val) external;
}



/**
 * @notice Windmill_DAO is the contract that manage de DAO of Windmill.
 *
 * It can modify all the parameters of Windmill, and update the Windmill contracts
 */
interface I_Windmill_DAO is IAccessControlEnumerable, I_With_DAORole, I_With_FundContract,
                            I_With_TradeManagerContract, I_With_PWRToken{
    /**
     * @notice Define an address capability about the DAO
     *
     * level -> Determines what the address is able to
     * - 0 (anonymous) -> This address can only buy, sell and stake PWR
     * - 1 (junior trader) -> This address can also make trade with limited sizing
     * - 2 (senior trader) -> This address can also make trade with full sizing
     * - 3 (governor) -> This address can also make proposals on the DAO
     *
     * nbProposalsDone -> How many proposals have been made in the lastProposalCycle cycle
     * lastProposalDAOCycle -> Last cycle where the address have made a proposal
     */
    struct DAOLevel{
        uint256 lastProposalDAOCycle;
        uint8 level;
        uint16 nbProposalsDone;
    }

    /**
     * @notice Define a proposal.
     *
     * id -> Identifiant of the proposal
     * paramsUint256 -> parameter of type uint256 associated with the proposal
     * paramsAddress -> parameter of type address associated with the proposal
     * - 0 -> Change the number of proposals per user per cycle
     *      (uint256) [1, 100] -> Number of proposals
     * - 1 -> Change the duration of vote
     *      (uint256) [28800 (1 day), 864000 (1 month)] -> Number of block
     * - 2 -> Change the quorum
     *      (uint256) [1, 100] -> Number of vote
     * - 3 -> Change the max number of open proposals
     *      (uint256) [10, 1000] -> Number of open proposals
     * - 4 -> Change the vote majority percent
     *      (uint256) [50, 100] -> Percent of yes votes
     * - 5 -> Change the duration of a super vote
     *      (uint256) [28800 (1 day), 864000 (1 month)] -> Number of block
     * - 6 -> Change the quorum of a super vote
     *      (uint256) [1, 100] -> Number of vote
     * - 7 -> Change the vote majority percent of a super vote
     *      (uint256) [50, 100] -> Percent of yes votes
     * - 8 -> promote a vote to super status
     *      (uint256) [0, nbProposals] -> Vote id
     * - 9 -> demote a vote from super status
     *      (uint256) [0, nbProposals] -> Vote id
     * - 10 ->
     * - 11 ->
     * - 12 -> Change the DAO cycle duration
     *      (uint256) [201600 (7 days), 10512000 (1 year)] -> Number of block
     * - 13 -> Change the gas refund price
     *      (uint256) [0, 100000000000 (100 gwei)] -> Gas price in Wei
     * - 14 -> Change the refund minimum BNB quantity
     *      (uint256) [0, inf] -> Minimum BNB quantity to refund
     * - 15 -> Change the refund bonus
     *      (uint256) [100, 200] -> 100 + Percent of bonus
     * - 16 -> Promote a user to junior trader (set it level 1 if <1) - It cannot demote a user
     *      (address) -> user address
     * - 17 -> Promote a user to senior trader (set it level 2 if <2) - It cannot demote a user
     *      (address) -> user address
     * - 18 -> Promote a user to governor (set it level 3)
     *      (address) -> user address
     * - 19 -> Demote user privilege (set it level 0)
     *      (address) -> user address
     * - 20 -> Change the minimum delay between two user refund
     *      (uint256) [28800 (1 day), 864000 (1 month)] -> Number of block
     * - 21 -> Change the royalty minting ratio
     *      (uint256) [0, 1000] -> ratio (per 10.000 ratio -> 100 = 1%)
     * - 22 ->
     * - 23 -> Change the Royalty cycle duration
     *      (uint256) [28800 (1 day), 10512000 (1 year)] -> Number of block
     * - 24 -> Change the Stacking cycle duration
     *      (uint256) [28800 (1 day), 10512000 (1 year)] -> Number of block
     * - 25 -> Change the Stacking reward minting ratio
     *      (uint256) [0, 1000] -> ratio (per 10.000 ratio -> 100 = 1%)
     * - 26 -> Change the Stacking bonus factor per cycle lock
     *      (uint256) [10000, 30000] -> ratio (per 10.000 ratio -> 100000 = 0% / 10100 = 1%)
     * - 27 -> Change the early unstacking fees per remaining cycle
     *      (uint256) [0, 10000] -> ratio (per 10.000 ratio -> 100 = 1%)
     * - 28 -> Change the fund PWR sell fees
     *      (uint256) [0, 2500] -> ratio (per 10.000 ratio -> 100 = 1%)
     * - 29 -> Trade deployer proposal
     *      (uint16) [0, 65536] -> Deployer id in Windmill_Trade_Manaager
     *      (uint8) [0, 255] -> Deployer proposal id
     *      (uint232) -> Parameter of type integer
     *      (address) -> Parameter of type address
     * - 30 -> Add deployer
     *      (address) -> Deployer address
     *
     * startBlock -> Voting is allowed since this block number
     * endBlock -> Voting is terminated since this block number
     * nbYesVotes -> Number of yes vote
     * nbNoVotes -> Number of no vote
     * done -> Proposal is closed
     *
     * status -> Proposal status
     * - 0: Vote period not terminated
     * - 1: Not applied because quorum is not reached
     * - 2: Not applies because "no" majority
     * - 3: Applied
     */
    struct Proposal{
        uint256 paramsUint256;
        address paramsAddress;
        uint256 startBlock;
        uint256 endBlock;
        uint64 nbYesVotes;
        uint64 nbNoVotes;
        uint16 id;
        uint16 status;
        bool done;
    }

    function getUserData(address addr) external view returns (DAOLevel memory);
    
    /**
     *            uint256 _nbProposalPerUserPerCycle,
     *            uint256 _maxNbOpenProposals,
     *            uint256 _voteBlockDuration,
     *            uint256 _quorum,
     *            uint256 _voteMajorityPercent,
     *            uint256 _superVoteBlockDuration,
     *            uint256 _superQuorum,
     *            uint256 _superVoteMajorityPercent,
     *            uint256 _DAOcycleDurationNbBlock,
     *            uint256 _royaltyCycleDurationNbBlock,
     *            uint256 _stackingCycleDurationNbBlock,
     *
     */
    function init(uint256[11] calldata data,
                  bool[] calldata _isProposalSuper) external;

    function setDAOCycle(uint256 cycle) external;
    
    function getNbOpenProposalIds() external view returns (uint256);
    
    function updateOpenProposalNeeded(uint256 i) external view returns (bool);
    
    function updateOneOpenProposal(uint256 i) external;
    
    /**
     * @notice Set the address of the Windmill_Royalty contract (used only at DAO contract initialization).
     */
    function setRoyaltyAddress(I_Windmill_Royalty _royalty) external;

    /**
     * @notice Set the address of the Windmill_Stacking contract (used only at DAO contract initialization).
     */
    function setStackingAddress(I_Windmill_Stacking _stacking) external;

    function setUpdaterAddress(I_Windmill_Updater _updater) external;
    /**
     * @notice Add a user with capability on the DAO (used only at DAO contract initialization).
     */
    function addUser(address addr, uint8 level) external;

    /**
     * @notice Get the number of votes for an address.
     *
     * The number of vote is rounded down log10 of 10^3 times the address
     * part of the PWR total supply.
     *
     * This means only address >= 0.1% of the supply will be able to vote.
     *
     * An address can have from 1 to 4 votes, depending on its PWR.
     */
    function getVotes(address addr) external view returns (uint8);

    /**
     * @notice Get the number of remaining proposals for an address
     */
    function getRemainingProposals(address addr) external view returns (uint256);

    /**
     * @notice Submit a new proposal then vote yes
     */
    function submitProposal(uint16 id, uint256 paramsUint256, address paramsAddress) external;

    function vote(uint256 id, bool isYes) external;
}


contract Windmill_DAO is Math, Adressable, AccessControlEnumerable, With_DAORole, With_FundContract,
                         With_TradeManagerContract, With_PWRToken, I_Windmill_DAO{
    ////
    ////
    ////
    //////////////// Public variables ////////////////
    uint256 public constant nbProposals = 31;

    bool[nbProposals] public isProposalSuper;

    I_Windmill_Royalty public royalty;
    I_Windmill_Stacking public stacking;
    I_Windmill_Updater public updater;

    mapping(address => DAOLevel) public users;

    uint256 public currentDAOCycle;
    uint256 public nbProposalPerUserPerDAOCycle;

    uint256 public voteBlockDuration;
    uint256 public superVoteBlockDuration;

    uint256 public quorum;
    uint256 public superQuorum;

    uint256 public voteMajorityPercent;
    uint256 public superVoteMajorityPercent;

    /**
     * @notice Used for security, to avoid max gaz error when updating
     */
    uint256 public maxNbOpenProposals;

    /**
     * @notice When a proposal is sent, it is added to "openProposals".
     *
     * "openProposalIds" keep a track of open proposals to avoid
     * a full scan of proposals array when updating.
     */
    Proposal[] public proposals;

    /**
     * @notice Keep track of address votes
     */
    mapping(address => mapping(uint256 => bool)) public hasVoted;

    ////
    ////
    ////
    //////////////// Private variables ////////////////
    uint256[] internal openProposalIds;



    ////
    ////
    ////
    //////////////// Constructor & Modifiers ////////////////
    modifier onlyGovernor(){
        require(users[msg.sender].level == 3, "Windmill_DAO: Only governor are allowed to call this function.");
        _;
    }

    constructor(){
    }

    function getUserData(address addr) external view returns (DAOLevel memory){
        return users[addr];
    }
    
    ////
    ////
    ////
    //////////////// Public functions ////////////////

    /**
     *          0  uint256 _nbProposalPerUserPerCycle,
     *          1  uint256 _maxNbOpenProposals,
     *          2  uint256 _voteBlockDuration,
     *          3  uint256 _quorum,
     *          4  uint256 _voteMajorityPercent,
     *          5  uint256 _superVoteBlockDuration,
     *          6  uint256 _superQuorum,
     *          7  uint256 _superVoteMajorityPercent,
     *          8  uint256 _DAOcycleDurationNbBlock,
     *          9  uint256 _royaltyCycleDurationNbBlock,
     *          10 uint256 _stackingCycleDurationNbBlock,
     *
     */
    function init(uint256[11] calldata data,
                  bool[] calldata _isProposalSuper) external onlyRole(DAO_ROLE){

        require(_isProposalSuper.length == nbProposals, "Windmill_DAO: _isProposalSuper is not correct length.");
        
        nbProposalPerUserPerDAOCycle = data[0];
        maxNbOpenProposals = data[1];

        voteBlockDuration = data[2];
        quorum = data[3];
        voteMajorityPercent = data[4];

        superVoteBlockDuration = data[5];
        superQuorum = data[6];
        superVoteMajorityPercent = data[7];
        
        updater.setDAOCycleDuration(data[8]);
        updater.setRoyaltyCycleDuration(data[9]);
        updater.setStackingCycleDuration(data[10]);
        updater.init();

        bool[nbProposals] memory arr;
        for(uint i=0; i<nbProposals; i++){
            arr[i] = _isProposalSuper[i];
        }
        isProposalSuper = arr;
    }

    function setRoyaltyAddress(I_Windmill_Royalty _royalty) external onlyRole(DAO_ROLE){
        royalty = _royalty;
    }

    function setStackingAddress(I_Windmill_Stacking _stacking) external onlyRole(DAO_ROLE){
        stacking = _stacking;
    }

    function setUpdaterAddress(I_Windmill_Updater _updater) external onlyRole(DAO_ROLE){
        updater = _updater;
    }
    
    function addUser(address addr, uint8 level) external onlyRole(DAO_ROLE){
        require(level <= 3, "Windmill_DAO: the max level is 3");

        DAOLevel storage user = users[addr];
        user.level = level;
        
        tradeManager.setTraderLevel(addr, level);
        
        updater.setUserGovernorStatus(addr, level == 3);
    }

    function getVotes(address addr) public view returns (uint8){
        if (users[addr].level < 3){
            return 0;
        }

        uint256 balance = PWRToken.balanceOf(addr);

        if (balance == 0){
            return 0;
        }

        uint256 PWRSupply = PWRToken.totalSupply();
        uint256 fraction = ((10**3) * (balance)) / PWRSupply;
        uint8 nbVotes = numDigits(fraction);

        return nbVotes;
    }

    function getRemainingProposals(address addr) public view returns (uint256){
        DAOLevel storage user = users[addr];

        if (user.level < 3){
            return 0;
        }

        if (currentDAOCycle > user.lastProposalDAOCycle){
            return nbProposalPerUserPerDAOCycle;
        }

        return nbProposalPerUserPerDAOCycle - user.nbProposalsDone;
    }


    function submitProposal(uint16 id, uint256 paramsUint256, address paramsAddress) external onlyGovernor{
        require(openProposalIds.length < maxNbOpenProposals, "Windmill_DAO: Max number of open proposals reached");
        require(id < nbProposals, "Windmill_DAO: This is not a valid proposal id");
        require(getRemainingProposals(msg.sender) > 0, "Windmill_DAO: No remaining proposals for this address");

        Proposal memory proposal;
        proposal.id = id;
        proposal.paramsUint256 = paramsUint256;
        proposal.paramsAddress = paramsAddress;
        proposal.startBlock = block.number;
        if (isProposalSuper[id]){
            proposal.endBlock = block.number + superVoteBlockDuration;
        }else{
            proposal.endBlock = block.number + voteBlockDuration;
        }

        require(_checkProposalParameters(proposal), "Windmill_DAO: Error in parameters");

        DAOLevel storage user = users[msg.sender];

        if (user.lastProposalDAOCycle == currentDAOCycle){
            user.nbProposalsDone += 1;
        }else{
            user.nbProposalsDone = 1;
            user.lastProposalDAOCycle = currentDAOCycle;
        }

        openProposalIds.push(proposals.length);
        proposals.push(proposal);

        vote(proposals.length-1, true);
    }

    function vote(uint256 id, bool isYes) public onlyGovernor{
        uint8 nbVotes = getVotes(msg.sender);
        require(nbVotes>0, "Windmill_DAO: There is 0 vote for this address");


        require(id < proposals.length, "Windmill_DAO: Proposal does not exist");
        Proposal storage proposal = proposals[id];

        require(!hasVoted[msg.sender][id], "Windmill_DAO: address have already voted");

        require(block.number >= proposal.startBlock, "Windmill_DAO: Proposal is not opened to vote");
        require(block.number < proposal.endBlock, "Windmill_DAO: Proposal is closed to vote");

        hasVoted[msg.sender][id] = true;

        if (isYes){
            proposal.nbYesVotes += nbVotes;
        }else{
            proposal.nbNoVotes += nbVotes;
        }
    }
    
    function setDAOCycle(uint256 cycle) external onlyRole(DAO_ROLE){
        currentDAOCycle = cycle;
    }
    
    function getNbOpenProposalIds() external view returns (uint256){
        return openProposalIds.length;
    }
    
    function updateOpenProposalNeeded(uint256 i) public view onlyRole(DAO_ROLE) returns (bool){
        uint256 l = openProposalIds.length;
        
        require(i < l, "Windmill_DAO: Open proposal ID not found.");
        
        Proposal storage proposal = proposals[openProposalIds[i]];
        
        if (block.number >= proposal.endBlock && !proposal.done){
            return true;
        }
        return false;
    }
    
    function updateOneOpenProposal(uint256 i) external onlyRole(DAO_ROLE){
        uint256 l = openProposalIds.length;
        
        require(i < l, "Windmill_DAO: Open proposal ID not found.");
        
        _updateOneDAO(i);
    }

    ////
    ////
    ////
    //////////////// Private functions ////////////////
    function _updateOneDAO(uint256 i) internal{
        uint256 proposalI = openProposalIds[i];
        bool isSuper = isProposalSuper[proposalI];
        Proposal storage proposal = proposals[proposalI];
        if (updateOpenProposalNeeded(i)){
            _updateProposal(proposal, isSuper);
            
            if (i < openProposalIds.length-1){
                openProposalIds[i] = openProposalIds[openProposalIds.length-1];
            }
            openProposalIds.pop();
        }
    }
    
    function _updateProposal(Proposal storage proposal, bool isSuper) internal{
        uint256 totalVotes = proposal.nbYesVotes+proposal.nbNoVotes;
        uint256 percentYes = (100*proposal.nbYesVotes)/totalVotes;

        if (isSuper){
            if (percentYes > superVoteMajorityPercent){
                if (totalVotes >= superQuorum){
                    _applyProposal(proposal);
                    proposal.status = 3;
                }else{
                    proposal.status = 1;
                }
            }else{
                proposal.status = 2;
            }
        }else{
            if (percentYes > voteMajorityPercent){
                if (totalVotes >= quorum){
                    _applyProposal(proposal);
                    proposal.status = 3;
                }else{
                    proposal.status = 1;
                }
            }else{
                proposal.status = 2;
            }
        }
        proposal.done = true;

    }

    function _applyProposal(Proposal storage proposal) internal{
        if (proposal.id == 0){
            nbProposalPerUserPerDAOCycle = proposal.paramsUint256;
        }else if(proposal.id == 1){
            voteBlockDuration = proposal.paramsUint256;
        }else if (proposal.id == 2){
            quorum = proposal.paramsUint256;
        }else if (proposal.id == 3){
            maxNbOpenProposals = proposal.paramsUint256;
        }else if (proposal.id == 4){
            voteMajorityPercent = proposal.paramsUint256;
        }else if (proposal.id == 5){
            superVoteBlockDuration = proposal.paramsUint256;
        }else if (proposal.id == 6){
            superQuorum = proposal.paramsUint256;
        }else if (proposal.id == 7){
            superVoteMajorityPercent = proposal.paramsUint256;
        }else if (proposal.id == 8){
            isProposalSuper[proposal.paramsUint256] = true;
        }else if (proposal.id == 9){
            isProposalSuper[proposal.paramsUint256] = false;
        }else if (proposal.id == 12){
            updater.setDAOCycleDuration(proposal.paramsUint256);
        }else if (proposal.id == 13){
            updater.setRefundGasDefaultPrice(proposal.paramsUint256);
        }else if (proposal.id == 14){
            updater.setRefundNbBNBMin(proposal.paramsUint256);
        }else if (proposal.id == 15){
            updater.setRefundBNBBonusRatio(proposal.paramsUint256);
        }else if (proposal.id == 16){
            if (users[proposal.paramsAddress].level < 1){
                tradeManager.setTraderLevel(proposal.paramsAddress, 1);
                users[proposal.paramsAddress].level = 1;
            }
        }else if (proposal.id == 17){
            if (users[proposal.paramsAddress].level < 2){
                tradeManager.setTraderLevel(proposal.paramsAddress, 2);
                users[proposal.paramsAddress].level = 2;
            }
        }else if (proposal.id == 18){
            tradeManager.setTraderLevel(proposal.paramsAddress, 3);
            users[proposal.paramsAddress].level = 3;
            updater.setUserGovernorStatus(proposal.paramsAddress, true);
        }else if (proposal.id == 19){
            tradeManager.setTraderLevel(proposal.paramsAddress, 0);
            users[proposal.paramsAddress].level = 0;
            updater.setUserGovernorStatus(proposal.paramsAddress, false);
        }else if (proposal.id == 20){
            updater.setRefundNbBlockDelay(proposal.paramsUint256);
        }else if (proposal.id == 21){
            royalty.setRoyaltyRatio(proposal.paramsUint256, 10000);
        }else if (proposal.id == 23){
            updater.setRoyaltyCycleDuration(proposal.paramsUint256);
        }else if (proposal.id == 24){
            updater.setStackingCycleDuration(proposal.paramsUint256);
        }else if (proposal.id == 25){
            stacking.setStackingRewardRatio(proposal.paramsUint256, 10000);
        }else if (proposal.id == 26){
            stacking.setStackingBonusRatio(proposal.paramsUint256, 10000);
        }else if (proposal.id == 27){
            stacking.setEarlyUnstackingFeesPercent(proposal.paramsUint256, 10000);
        }else if (proposal.id == 28){
            fund.setWithdrawFees(proposal.paramsUint256, 10000);
        }else if (proposal.id == 29){
            (uint256 param, uint256 deployerProposalId, uint256 deployerId) = _unpackDeployerProposalData(proposal.paramsUint256);
            
            I_Windmill_Trade_Manager.DeployerData memory data = tradeManager.getTradeDeployer(deployerId);
            
            data.deployer.applyProposal(deployerProposalId, param, proposal.paramsAddress);
        }else if (proposal.id == 30){
            I_Windmill_Trade_Deployer_Abstract deployer = I_Windmill_Trade_Deployer_Abstract(payable(proposal.paramsAddress));
            tradeManager.addTradeDeployer(deployer);
        }
    }

    function _checkProposalParameters(Proposal memory proposal) internal view returns (bool){
        if (proposal.id == 0){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 1
                || proposal.paramsUint256 > 100){
                return false;
            }
        }else if (proposal.id == 1){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 28800
                || proposal.paramsUint256 > 864000){
                return false;
            }
        }else if (proposal.id == 2){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 1
                || proposal.paramsUint256 > 10){
                return false;
            }
        }else if (proposal.id == 3){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 10
                || proposal.paramsUint256 > 1000){
                return false;
            }
        }else if (proposal.id == 4){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 50
                || proposal.paramsUint256 > 100){
                return false;
            }
        }else if (proposal.id == 5){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 28800
                || proposal.paramsUint256 > 864000){
                return false;
            }
        }else if (proposal.id == 6){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 1
                || proposal.paramsUint256 > 100){
                return false;
            }
        }else if (proposal.id == 7){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 50
                || proposal.paramsUint256 > 100){
                return false;
            }
        }else if (proposal.id == 8){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 0
                || proposal.paramsUint256 >= nbProposals){
                return false;
            }
        }else if (proposal.id == 9){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 0
                || proposal.paramsUint256 >= nbProposals){
                return false;
            }
        }else if (proposal.id == 12){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 201600
                || proposal.paramsUint256 > 10512000){
                return false;
            }
        }else if (proposal.id == 13){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 > 100000000000){
                return false;
            }
        }else if (proposal.id == 14){
            if (   proposal.paramsAddress != address(0x0)){
                return false;
            }
        }else if (proposal.id == 15){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 100
                || proposal.paramsUint256 > 200){
                return false;
            }
        }else if (proposal.id == 16){
            if (   proposal.paramsAddress == address(0x0)
                || users[proposal.paramsAddress].level>=1){
                return false;
            }
        }else if (proposal.id == 17){
            if (   proposal.paramsAddress == address(0x0)
                || users[proposal.paramsAddress].level>=2){
                return false;
            }
        }else if (proposal.id == 18){
            if (   proposal.paramsAddress == address(0x0)){
                return false;
            }
        }else if (proposal.id == 19){
            if (   proposal.paramsAddress == address(0x0)){
                return false;
            }
        }else if (proposal.id == 20){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 28800
                || proposal.paramsUint256 > 864000){
                return false;
            }
        }else if (proposal.id == 21){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 > 1000){
                return false;
            }
        }else if (proposal.id == 23){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 28800
                || proposal.paramsUint256 > 10512000){
                return false;
            }
        }else if (proposal.id == 24){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 28800
                || proposal.paramsUint256 > 10512000){
                return false;
            }
        }else if (proposal.id == 25){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 > 1000){
                return false;
            }
        }else if (proposal.id == 26){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 < 10000
                || proposal.paramsUint256 > 30000){
                return false;
            }
        }else if (proposal.id == 27){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 > 10000){
                return false;
            }
        }else if (proposal.id == 28){
            if (   proposal.paramsAddress != address(0x0)
                || proposal.paramsUint256 > 2500){
                return false;
            }
        }else if (proposal.id == 29){
            (uint256 param, uint256 deployerProposalId, uint256 deployerId) = _unpackDeployerProposalData(proposal.paramsUint256);
            
            if (deployerId >= tradeManager.getNbTradeDeployers()){
                return false;
            }
            
            I_Windmill_Trade_Manager.DeployerData memory data = tradeManager.getTradeDeployer(deployerId);
            
            if (!data.enabled){
                return false;
            }
            
            return data.deployer.checkProposal(deployerProposalId, param, proposal.paramsAddress);
        }else if (proposal.id == 30){
            I_Windmill_Trade_Deployer_Abstract deployer = I_Windmill_Trade_Deployer_Abstract(payable(proposal.paramsAddress));
            if (   proposal.paramsUint256 != 0
                || !deployer.hasRole(deployer.DAO_ROLE(), address(tradeManager))
                || deployer.tradeTemplate() == address(0x0)){
                return false;
            }
        }

        return true;
    }
    
    function _unpackDeployerProposalData(uint256 data) internal pure returns (uint256, uint256, uint256){
        uint256 param = data >> (8+16);
        uint256 deployerProposalId = (data << (256-8-16)) >> (256-8);
        uint256 deployerId = (data << (256-16)) >> (256-16);
        
        return (param, deployerProposalId, deployerId);
    }
}