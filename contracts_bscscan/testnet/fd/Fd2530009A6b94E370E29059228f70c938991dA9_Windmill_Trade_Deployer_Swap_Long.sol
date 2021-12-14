/**
 *Submitted for verification at BscScan.com on 2021-12-14
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
    function DAO_ROLE() external returns (bytes32);
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
event GasLog_With_DAORole(uint256 line, uint256 gas);
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");

    constructor(){
        _setRoleAdmin(DAO_ROLE, DAO_ROLE);
        _setupRole(DAO_ROLE, msg.sender);
    }
}// Version: 1.0.0


// Version: 1.0.0


interface I_With_UpdaterRole is I_With_DAORole{
    /**
     * UPDATER_ROLE is able to update contracts.
     */
    function UPDATER_ROLE() external returns (bytes32);
}

contract With_UpdaterRole is AccessControlEnumerable, With_DAORole, I_With_UpdaterRole{
event GasLog_With_UpdaterRole(uint256 line, uint256 gas);
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    constructor(){
        _setRoleAdmin(UPDATER_ROLE, DAO_ROLE);
    }
}// Version: 1.0.0


// Version: 1.0.0


interface I_With_TradeManagerRole is I_With_DAORole{
    /**
     * UPDATER_ROLE is able to update contracts.
     */
    function TRADE_MANAGER_ROLE() external returns (bytes32);
}

contract With_TradeManagerRole is AccessControlEnumerable, With_DAORole, I_With_TradeManagerRole{
event GasLog_With_TradeManagerRole(uint256 line, uint256 gas);
    bytes32 public constant TRADE_MANAGER_ROLE = keccak256("TRADE_MANAGER_ROLE");

    constructor(){
        _setRoleAdmin(TRADE_MANAGER_ROLE, DAO_ROLE);
    }
}// Version: 1.0.0

contract Adressable{
event GasLog_Adressable(uint256 line, uint256 gas);
    address payable immutable internal thisAddr;

    constructor(){
        thisAddr = payable(address(this));
    }
}
// Version: 1.0.0


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

interface I_With_BUSDToken is IAccessControlEnumerable, I_With_DAORole{
    function setBUSDToken(IERC20 token) external;
}

contract With_BUSDToken is AccessControlEnumerable, With_DAORole, I_With_BUSDToken{
event GasLog_With_BUSDToken(uint256 line, uint256 gas);
    IERC20 public BUSDToken;

    function setBUSDToken(IERC20 token) external onlyRole(DAO_ROLE){
emit GasLog_With_BUSDToken(15, gasleft());
        BUSDToken = token;
emit GasLog_With_BUSDToken(16, gasleft());
    }
}
// Version: 1.0.0

// Version: 1.0.0

// Version: 1.0.0



interface I_With_FundContract is IAccessControlEnumerable, I_With_DAORole{
    function setFund(address _fund) external;
}// Version: 1.0.0



interface I_With_WithdrawerContract is IAccessControlEnumerable, I_With_DAORole{
    function setWithdrawer(address _withdrawer) external;
}// Version: 1.0.0



interface I_With_TradeManagerContract is IAccessControlEnumerable, I_With_DAORole{
    function setTradeManager(address _tradeManager) external;
}// Version: 1.0.0

interface I_Math{
    struct Fraction{
        uint256 numerator;
        uint256 denominator;
    }
}


interface I_Windmill_Trade_Abstract is I_Math, IAccessControlEnumerable, I_With_DAORole, I_With_UpdaterRole, I_With_TradeManagerRole,
									   I_With_BUSDToken, I_With_FundContract, I_With_TradeManagerContract, I_With_WithdrawerContract{
	
	function initTrade(address _owner, address _manager, address _fund, address _updater, address _withdrawer) external;
	
	function setTradeId(uint256 _tradeId) external;
	
	function endTrade() external;
	
	function updateNeeded() external returns (bool);
	
	function update() external;
	
	function estimateBUSDBalance() external returns (uint256);
}

interface I_Windmill_Trade_Deployer_Abstract is IAccessControlEnumerable, I_With_DAORole, I_With_UpdaterRole, I_With_TradeManagerRole, I_With_BUSDToken{
	function name() external returns (string memory);
	
	function tradeTemplate() external returns (address);
	
	function setTradeCode(bytes memory bytecode, string memory name) external;
	
	function deployNewTrade(address owner, address manager, address fund, address updater, address withdrawer) external returns (I_Windmill_Trade_Abstract);
	
	function checkProposal(uint256 id, uint256 paramsUint256, address paramsAddress) external returns (bool);
	
	function applyProposal(uint256 id, uint256 paramsUint256, address paramsAddress) external;
}



/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

abstract contract Windmill_Trade_Deployer_Abstract is Adressable, AccessControlEnumerable, With_DAORole, With_UpdaterRole,
                                                      With_TradeManagerRole, With_BUSDToken, I_Windmill_Trade_Deployer_Abstract{
event GasLog_Windmill_Trade_Deployer_Abstract(uint256 line, uint256 gas);
    ////
    ////
    ////
    //////////////// Public variables ////////////////
    address public tradeTemplate;
    string public name;
    bytes public tradeBytecode;
    
    ////
    ////
    ////
    //////////////// Private variables ////////////////
    uint256 salt;

    ////
    ////
    ////
    //////////////// Constructor & Modifiers ////////////////
    constructor(){
    }

    ////
    ////
    ////
    //////////////// Public functions ////////////////
	function setTradeCode(bytes memory _bytecode, string memory _name) external onlyRole(DAO_ROLE){
emit GasLog_Windmill_Trade_Deployer_Abstract(45, gasleft());
        name = _name;
emit GasLog_Windmill_Trade_Deployer_Abstract(46, gasleft());
        tradeBytecode = _bytecode;
emit GasLog_Windmill_Trade_Deployer_Abstract(47, gasleft());
        tradeTemplate = address(0x1);
emit GasLog_Windmill_Trade_Deployer_Abstract(48, gasleft());
    }
	
	function deployNewTrade(address owner, address manager, address fund, address updater, address withdrawer) external onlyRole(TRADE_MANAGER_ROLE) returns (I_Windmill_Trade_Abstract){
emit GasLog_Windmill_Trade_Deployer_Abstract(51, gasleft());
        I_Windmill_Trade_Abstract trade =  I_Windmill_Trade_Abstract(_deployNewTrade());
emit GasLog_Windmill_Trade_Deployer_Abstract(52, gasleft());
        _initTrade(trade, owner, manager, fund, updater, withdrawer);
emit GasLog_Windmill_Trade_Deployer_Abstract(53, gasleft());
        
        return trade;
emit GasLog_Windmill_Trade_Deployer_Abstract(55, gasleft());
    }
    
    ////
    ////
    ////
    //////////////// Private functions ////////////////
	function _deployNewTrade() internal returns (address){
emit GasLog_Windmill_Trade_Deployer_Abstract(62, gasleft());
        address addr = Create2.deploy(0, bytes32(salt), tradeBytecode);
emit GasLog_Windmill_Trade_Deployer_Abstract(63, gasleft());
        salt += 1;
emit GasLog_Windmill_Trade_Deployer_Abstract(64, gasleft());
        
        return addr;
emit GasLog_Windmill_Trade_Deployer_Abstract(66, gasleft());
    }
    
    function _initTrade(I_Windmill_Trade_Abstract trade, address owner, address manager, address fund, address updater, address withdrawer) internal virtual{
emit GasLog_Windmill_Trade_Deployer_Abstract(69, gasleft());
        trade.setBUSDToken(BUSDToken);
emit GasLog_Windmill_Trade_Deployer_Abstract(70, gasleft());
        trade.initTrade(owner, manager, fund, updater, withdrawer);
emit GasLog_Windmill_Trade_Deployer_Abstract(71, gasleft());
    }
}// Version: 1.0.0


// Version: 1.0.0



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
}


contract With_PancakeRouter is AccessControlEnumerable, With_DAORole, I_With_PancakeRouter{
event GasLog_With_PancakeRouter(uint256 line, uint256 gas);
    PancakeRouter public pancakeRouter;

    function setPancakeRouter(PancakeRouter addr) external onlyRole(DAO_ROLE){
emit GasLog_With_PancakeRouter(16, gasleft());
        pancakeRouter = addr;
emit GasLog_With_PancakeRouter(17, gasleft());
    }
}
// Version: 1.0.0


interface I_Windmill_Trade_Swap_Long is I_With_PancakeRouter, I_Windmill_Trade_Abstract{
	struct LimitOrder{
		bool increaseSize;
		uint256 sizeIn;
		uint256 triggerPrice;
	}
}// Version: 1.0.0



interface I_Windmill_Trade_Deployer_Swap_Long is I_With_PancakeRouter, I_Windmill_Trade_Deployer_Abstract{
	struct Token{
		IERC20 token;
		uint256 routeId;
	}
	
    function TRADE_ROLE() external returns (bytes32);
	
	function getRoute(uint256 routeId) external returns (address[] memory);
}

contract Windmill_Trade_Deployer_Swap_Long is Windmill_Trade_Deployer_Abstract, With_PancakeRouter, I_Windmill_Trade_Deployer_Swap_Long{
event GasLog_Windmill_Trade_Deployer_Swap_Long(uint256 line, uint256 gas);
    ////
    ////
    ////
    //////////////// Public variables ////////////////
    Token[] public authorizedTokens;
    mapping(uint=>address[]) public routes;
    uint256 public lastRouteId;
    
    bytes32 public constant TRADE_ROLE = keccak256("TRADE_ROLE");
    ////
    ////
    ////
    //////////////// Private variables ////////////////

    ////
    ////
    ////
    //////////////// Constructor & Modifiers ////////////////
    constructor(){
        _setRoleAdmin(TRADE_ROLE, DAO_ROLE);
    }

    ////
    ////
    ////
    //////////////// Public functions ////////////////
    
    /* @notice
     * id -> Identifiant of the proposal
     * paramsUint256 -> parameter of type uint256 associated with the proposal
     * paramsAddress -> parameter of type address associated with the proposal
     * - 0 -> Add an authorized token to trade
 *          (uint24) -> No used
     *      (uint232) -> Route
     *          (uint4) [0, 16] -> Route size
     *          [(uint14),...] [0, 16384] (15 routes max) -> authorized token id
     *          (uint18) -> No used
     *      (address) -> Address of the ERC20 token that have a valid BUSD/Token pair
     * - 1 -> Delete an authorized token
     *      (uint256) -> Id of the token to delete
     *
     */
	function checkProposal(uint256 id, uint256 paramsUint256, address paramsAddress) external onlyRole(DAO_ROLE) returns (bool){
emit GasLog_Windmill_Trade_Deployer_Swap_Long(56, gasleft());
        require(id < 2, "Windmill_Trade_Deployer_Swap_Long: Proposal id not found");
emit GasLog_Windmill_Trade_Deployer_Swap_Long(57, gasleft());
        
        if (id == 0){
emit GasLog_Windmill_Trade_Deployer_Swap_Long(59, gasleft());
            address[] memory route = _unpackRoute(paramsUint256, paramsAddress);
emit GasLog_Windmill_Trade_Deployer_Swap_Long(60, gasleft());
            
            try pancakeRouter.getAmountsOut(1 ether, route) returns (uint256[] memory){
emit GasLog_Windmill_Trade_Deployer_Swap_Long(62, gasleft());
                return true;
emit GasLog_Windmill_Trade_Deployer_Swap_Long(63, gasleft());
            }catch{
emit GasLog_Windmill_Trade_Deployer_Swap_Long(64, gasleft());
                return false;
emit GasLog_Windmill_Trade_Deployer_Swap_Long(65, gasleft());
            }
            
        }else if (id == 1){
emit GasLog_Windmill_Trade_Deployer_Swap_Long(68, gasleft());
            return paramsUint256 < authorizedTokens.length;
emit GasLog_Windmill_Trade_Deployer_Swap_Long(69, gasleft());
        }
        
        return false;
emit GasLog_Windmill_Trade_Deployer_Swap_Long(72, gasleft());
    }
	
	function applyProposal(uint256 id, uint256 paramsUint256, address paramsAddress) external onlyRole(DAO_ROLE){
emit GasLog_Windmill_Trade_Deployer_Swap_Long(75, gasleft());
        if (id == 0){
emit GasLog_Windmill_Trade_Deployer_Swap_Long(76, gasleft());
            Token memory token;
emit GasLog_Windmill_Trade_Deployer_Swap_Long(77, gasleft());
            token.token = IERC20(paramsAddress);
emit GasLog_Windmill_Trade_Deployer_Swap_Long(78, gasleft());
            token.routeId = lastRouteId;
emit GasLog_Windmill_Trade_Deployer_Swap_Long(79, gasleft());
            
            routes[lastRouteId] = _unpackRoute(paramsUint256, paramsAddress);
emit GasLog_Windmill_Trade_Deployer_Swap_Long(81, gasleft());
            
            lastRouteId += 1;
emit GasLog_Windmill_Trade_Deployer_Swap_Long(83, gasleft());
            
            authorizedTokens.push(token);
emit GasLog_Windmill_Trade_Deployer_Swap_Long(85, gasleft());
            
        }else if (id == 1){
emit GasLog_Windmill_Trade_Deployer_Swap_Long(87, gasleft());
            authorizedTokens[paramsUint256] = authorizedTokens[authorizedTokens.length-1];
emit GasLog_Windmill_Trade_Deployer_Swap_Long(88, gasleft());
            authorizedTokens.pop();
emit GasLog_Windmill_Trade_Deployer_Swap_Long(89, gasleft());
        }
    }
    
    function getNbAuthorizenTokens() external returns (uint256){
emit GasLog_Windmill_Trade_Deployer_Swap_Long(93, gasleft());
        return authorizedTokens.length;
emit GasLog_Windmill_Trade_Deployer_Swap_Long(94, gasleft());
    }
    
	function getRoute(uint256 routeId) external returns (address[] memory){
emit GasLog_Windmill_Trade_Deployer_Swap_Long(97, gasleft());
        address[] storage route = routes[routeId];
emit GasLog_Windmill_Trade_Deployer_Swap_Long(98, gasleft());
        
        require(route.length > 0, "Windmill_Trade_Deployer_Swap_Long: Route id not found.");
emit GasLog_Windmill_Trade_Deployer_Swap_Long(100, gasleft());
        
        return route;
emit GasLog_Windmill_Trade_Deployer_Swap_Long(102, gasleft());
    }
    ////
    ////
    ////
    //////////////// Private functions ////////////////
    function _initTrade(I_Windmill_Trade_Abstract trade, address owner, address manager, address fund, address updater, address withdrawer) internal override{
emit GasLog_Windmill_Trade_Deployer_Swap_Long(108, gasleft());
        address tradeAddr = address(trade);
emit GasLog_Windmill_Trade_Deployer_Swap_Long(109, gasleft());
        grantRole(TRADE_ROLE, tradeAddr);
emit GasLog_Windmill_Trade_Deployer_Swap_Long(110, gasleft());
        
        I_Windmill_Trade_Swap_Long tradeDerived = I_Windmill_Trade_Swap_Long(tradeAddr);
emit GasLog_Windmill_Trade_Deployer_Swap_Long(112, gasleft());
        tradeDerived.setPancakeRouter(pancakeRouter);
emit GasLog_Windmill_Trade_Deployer_Swap_Long(113, gasleft());
        
        super._initTrade(trade, owner, manager, fund, updater, withdrawer);
emit GasLog_Windmill_Trade_Deployer_Swap_Long(115, gasleft());
    }
    
    function _unpackRoute(uint256 data, address token) internal returns (address[] memory){
emit GasLog_Windmill_Trade_Deployer_Swap_Long(118, gasleft());
        uint256 size = (data << (256-4)) >> (256-4);
emit GasLog_Windmill_Trade_Deployer_Swap_Long(119, gasleft());
        
        address[] memory route = new address[](size+2);
emit GasLog_Windmill_Trade_Deployer_Swap_Long(121, gasleft());
        route[0] = address(BUSDToken);
emit GasLog_Windmill_Trade_Deployer_Swap_Long(122, gasleft());
        
        for (uint i = 1; i<=size; i++){
emit GasLog_Windmill_Trade_Deployer_Swap_Long(124, gasleft());
            uint256 tokenId = (data << (256-4-i*14)) >> (256-14);
emit GasLog_Windmill_Trade_Deployer_Swap_Long(125, gasleft());
            require(tokenId < authorizedTokens.length, "Windmill_Trade_Deployer_Swap_Long: Route token id not found.");
emit GasLog_Windmill_Trade_Deployer_Swap_Long(126, gasleft());
            route[i] = address(authorizedTokens[tokenId].token);
emit GasLog_Windmill_Trade_Deployer_Swap_Long(127, gasleft());
        }
        
        route[size+1] = token;
emit GasLog_Windmill_Trade_Deployer_Swap_Long(130, gasleft());
        
        return route;
emit GasLog_Windmill_Trade_Deployer_Swap_Long(132, gasleft());
    }
}