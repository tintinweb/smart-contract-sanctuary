// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
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

    function toString(bytes32 value) internal pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && value[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && value[i] != 0; i++) {
            bytesArray[i] = value[i];
        }
        return string(bytesArray);
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
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via _msgSender() and msg.data, they should not be accessed in such a direct
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
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
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
 * @dev Interface of a contract containing identifier for Default Admin role.
 */
interface IRoleContainerDefaultAdmin {
    /**
    * @dev Returns Default Admin role identifier.
    */
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
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
 *     require(hasRole(MY_ROLE, _msgSender()));
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
abstract contract AccessControl is Context, ERC165Storage, IAccessControl, IRoleContainerDefaultAdmin {
    /**
    * @dev Default Admin role identifier.
    */
    bytes32 public constant DEFAULT_ADMIN_ROLE = "Admin";

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    constructor() {
        _registerInterface(type(IAccessControl).interfaceId);
    }

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toString(role)
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
}



/**
 * @dev Interface for contract which allows to pause and unpause the contract.
 */
interface IPausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);
    
    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() external view returns (bool);

    /**
    * @dev Pauses the contract.
    */
    function pause() external;

    /**
    * @dev Unpauses the contract.
    */
    function unpause() external;
}



/**
 * @dev Interface of a contract containing identifier for Pauser role.
 */
interface IRoleContainerPauser {
    /**
    * @dev Returns Pauser role identifier.
    */
    function PAUSER_ROLE() external view returns (bytes32);
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
contract Pausable is AccessControl, IPausable, IRoleContainerPauser {
    /**
    * @dev Pauser role identifier.
    */
    bytes32 public constant PAUSER_ROLE = "Pauser";

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _registerInterface(type(IPausable).interfaceId);
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
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
   
    /**
    * @dev This function is called before pausing the contract.
    * Override to add custom pausing conditions or actions.
    */
    function _beforePause() internal virtual {
    }

    /**
    * @dev This function is called before unpausing the contract.
    * Override to add custom unpausing conditions or actions.
    */
    function _beforeUnpause() internal virtual {
    }

    /**
    * @dev Pauses the contract.
    * Requirements:
    * - Caller must have 'PAUSER_ROLE';
    * - Contract must be unpaused.
    */
    function pause() external onlyRole(PAUSER_ROLE) whenNotPaused {
        _beforePause();
        _pause();
    }

    /**
    * @dev Unpauses the contract.
    * Requirements:
    * - Caller must have 'PAUSER_ROLE';
    * - Contract must be unpaused;
    */
    function unpause() external onlyRole(PAUSER_ROLE) whenPaused {
        _beforeUnpause();
        _unpause();
    }
}



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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
}


/**
 * @dev Contract module which allows to perform basic checks on arguments.
 */
abstract contract RequirementsChecker {
    uint256 internal constant inf = type(uint256).max;

    function _requireNonZeroAddress(address _address, string memory paramName) internal pure {
        require(_address != address(0), string(abi.encodePacked(paramName, ": cannot use zero address")));
    }

    function _requireArrayData(address[] memory _array, string memory paramName) internal pure {
        require(_array.length != 0, string(abi.encodePacked(paramName, ": cannot be empty")));
    }

    function _requireArrayData(uint256[] memory _array, string memory paramName) internal pure {
        require(_array.length != 0, string(abi.encodePacked(paramName, ": cannot be empty")));
    }

    function _requireStringData(string memory _string, string memory paramName) internal pure {
        require(bytes(_string).length != 0, string(abi.encodePacked(paramName, ": cannot be empty")));
    }

    function _requireSameLengthArrays(address[] memory _array1, uint256[] memory _array2, string memory paramName1, string memory paramName2) internal pure {
        require(_array1.length == _array2.length, string(abi.encodePacked(paramName1, ", ", paramName2, ": lengths must be equal")));
    }

    function _requireInRange(uint256 value, uint256 minValue, uint256 maxValue, string memory paramName) internal pure {
        string memory maxValueString = maxValue == inf ? "inf" : Strings.toString(maxValue);
        require(minValue <= value && (maxValue == inf || value <= maxValue), string(abi.encodePacked(paramName, ": must be in [", Strings.toString(minValue), "..", maxValueString, "] range")));
    }
}



/**
 * @dev Interface of a contract module which allows authorized account to withdraw assets in case of emergency.
 */
interface IEmergencyWithdrawer {
    /**
     * @dev Emitted when emergency withdrawal occurs.
     */
    event EmergencyWithdrawn(address asset, uint256[] ids, address to, string reason);

    /**
    * @dev Withdraws all balance of certain asset.
    * Emits a {EmergencyWithdrawn} event.
    */
    function emergencyWithdrawal(address asset, uint256[] calldata ids, address to, string calldata reason) external;
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


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transfered from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}


/**
 * @dev Contract module which allows authorized account to withdraw assets in case of emergency.
 */
abstract contract EmergencyWithdrawer is AccessControl, RequirementsChecker, IEmergencyWithdrawer {

    constructor () {
        _registerInterface(type(IEmergencyWithdrawer).interfaceId);
    }

    /**
    * @dev Withdraws all balance of certain asset.
    * @param asset Address of asset to withdraw.
    * @param ids Array of NFT ids to withdraw - if it is empty, withdrawing asset is considered to be IERC20, otherwise - IERC1155.
    * @param to Address where to transfer specified asset.
    * Requirements:
    * - Caller must have 'DEFAULT_ADMIN_ROLE';
    * - 'asset' address must be non-zero;
    * - 'to' address must be non-zero;
    * - 'reason' must be provided.
    * Emits {EmergencyWithdrawn} event.
    */
    function emergencyWithdrawal(address asset, uint256[] calldata ids, address to, string calldata reason) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _requireNonZeroAddress(asset, "asset");
        _requireNonZeroAddress(to, "to");
        _requireStringData(reason, "reason");

        if (ids.length == 0) {
            IERC20 token = IERC20(asset);
            token.transfer(to, token.balanceOf(address(this)));
        }
        else {
            IERC1155 token = IERC1155(asset);

            address[] memory addresses = new address[](ids.length);
            for(uint256 i = 0; i < ids.length; i++)
                addresses[i] = address(this); // actually only this one, but multiple times to call balanceOfBatch

            uint256[] memory balances = token.balanceOfBatch(addresses, ids);
            token.safeBatchTransferFrom(address(this), to, ids, balances, "");
        }

        emit EmergencyWithdrawn(asset, ids, to, reason);
    }
}


/**
 * @dev Interface of extension of {IERC165} that allows to handle receipts on receiving {IERC1155} assets.
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. _msgSender())
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
        @param operator The address which initiated the batch transfer (i.e. _msgSender())
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


/**
 * @dev Extension of {ERC165} that allows to handle receipts on receiving {ERC1155} assets.
 */
abstract contract ERC1155Receiver is ERC165Storage, IERC1155Receiver {

    constructor() {
        _registerInterface(type(IERC1155Receiver).interfaceId);
    }
}


/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}


/**
 * @dev Extension of {IERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 */
interface IERC1155Burnable is IERC1155 {
    function burn(address account, uint256 id, uint256 value) external;
    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;
}


/**
 * @dev Contract implementing staking/unstaking functions for Fear PlayToEarn mode.
 */
contract FearPlayToEarn is AccessControl, Pausable, ReentrancyGuard, EmergencyWithdrawer, ERC1155Holder {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    /**
     * @dev Emitted when player's stake is changed by staking or unstaking.
     */
    event StakeUpdated(address indexed account, uint256 indexed milestoneId, uint256 stake);
    /**
     * @dev Emitted when the stake lock period is changed.
     */
    event StakeLockPeriodChanged(uint16 newStakeLockPeriod);
    
    IERC20 private fearToken;
    IERC1155Burnable private fearNftToken;

    bool private initialDataImportIsPossible = true;
    uint256 private stakeLockPeriod = 14 days;

    struct Milestone {
        uint256 id;
        bool enabled;
        uint256 stakeCap;
        uint256[] tokenIds;
    }

    struct Token {
        uint256 id;
        uint256 milestoneId;
        uint256 stakeEquivalent;
        bool burnOnStake;
    }

    EnumerableSet.AddressSet private fearStakers;

    // address => lock release date
    mapping (address => uint) private stakeLockExpiration;

    // milestone id => milestone
    mapping(uint256 => Milestone) private milestones;

    // milestone id => token id => token
    mapping(uint256 => mapping(uint256 => Token)) private tokens;

    // address => milestone id => stake
    mapping(address => mapping(uint256 => uint256)) public playerStakes;

    // address => milestone => token => amount
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public playerTokens;
    
    constructor(address fearTokenAddress, address fearNftTokenAddress) {
        fearToken = IERC20(fearTokenAddress);
        fearNftToken = IERC1155Burnable(fearNftTokenAddress);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

        // contract is paused at deployment time
        _pause();
    }

    function checkMilestoneAndTokenSetup(uint256 milestoneId, uint256 tokenId) private view {
        require(milestones[milestoneId].id != 0, "Milestone has not been setup");
        require(tokenId == 0 || tokens[milestoneId][tokenId].id != 0, "Token has not been setup");
    }

    function _beforeUnpause() internal virtual override {
        initialDataImportIsPossible = false; // once the contract is unpaused, data import is not possible anymore EVER!
    }

    /**
    * @dev Returns the total count of FEAR and token stakers along all milestones.
    */
    function getStakersCount() external view returns (uint256) {
        return fearStakers.length();
    }

    /**
    * @dev Returns player's FEAR stake within specified milestone.
    * @param player Player's address.
    * @param milestoneId Milestone id.
    * @return Player's FEAR stake amount in FEAR denomination (18 decimals).
    */
    function getPlayerFearStake(address player, uint256 milestoneId) external view returns (uint256) {
        return playerStakes[player][milestoneId];
    }

    /**
    * @dev Returns player's specified token stake within specified milestone.
    * @param player Player's address.
    * @param milestoneId Milestone id.
    * @param tokenId Token id.
    * @return Player's token stake amount in token denomination (1, 2, 3...).
    */
    function getPlayerTokenStake(address player, uint256 milestoneId, uint256 tokenId) external view returns (uint256) {
        return playerTokens[player][milestoneId][tokenId];
    }

    /**
    * @dev Returns player's total stake including both FEAR and tokens within specified milestone.
    * @param player Player's address.
    * @param milestoneId Milestone id.
    * @return Player's total stake in FEAR denomination.
    */
    function getPlayerTotalStake(address player, uint256 milestoneId) public view returns (uint256) {
        uint256 stake = playerStakes[player][milestoneId];
        for (uint i = 0; i < milestones[milestoneId].tokenIds.length; i++) {
            uint256 tokenId = milestones[milestoneId].tokenIds[i];

            if (playerTokens[player][milestoneId][tokenId] > 0)
                stake = playerTokens[player][milestoneId][tokenId].mul(tokens[milestoneId][tokenId].stakeEquivalent).add(stake);
        }

        return stake;
    }

    /**
    * @dev Returns player's stake lock expiration date.
    * @param player Player's address.
    * @return Timestamp of players's stake lock expiration.
    */
    function getStakeLockExpiration(address player) external view returns (uint256) {
        return stakeLockExpiration[player];
    }

    /**
    * @dev Returns all FEAR stakes within specified milestone.
    * @param milestoneId Milestone id.
    * @return Corresponding arrays of stakers' addresses and FEAR stakes.
    * Requirements:
    * - Milestone must be setup.
    */
    function getAllFearStakes(uint256 milestoneId) external view returns (address[] memory, uint256[] memory) {
        checkMilestoneAndTokenSetup(milestoneId, 0);

        address[] memory stakers = new address[](fearStakers.length());
        uint256[] memory amounts = new uint256[](fearStakers.length());

        for (uint i = 0; i < fearStakers.length(); i++) {
            stakers[i] = fearStakers.at(i);
            amounts[i] = playerStakes[fearStakers.at(i)][milestoneId];
        }

        return (stakers, amounts);
    }

    /**
    * @dev Returns all specified token stakes within specified milestone.
    * @param milestoneId Milestone id.
    * @param tokenId Token id.
    * @return Corresponding arrays of stakers' addresses and token stakes.
    * Requirements:
    * - Milestone and token must be setup.
    */
    function getAllTokenStakes(uint256 milestoneId, uint256 tokenId) external view returns (address[] memory, uint256[] memory) {
        checkMilestoneAndTokenSetup(milestoneId, tokenId);
        
        address[] memory stakers = new address[](fearStakers.length());
        uint256[] memory amounts = new uint256[](fearStakers.length());

        for (uint i = 0; i < fearStakers.length(); i++) {
            stakers[i] = fearStakers.at(i);
            amounts[i] = playerTokens[fearStakers.at(i)][milestoneId][tokenId];
        }

        return (stakers, amounts);
    }

    /**
    * @dev Returns specified milestone staking cap.
    * @param milestoneId Milestone id.
    * @return Milestone staking cap in FEAR denomination.
    */
    function getMilestoneStakeCap(uint256 milestoneId) external view returns (uint256) {
        return milestones[milestoneId].stakeCap;
    }

    /**
    * @dev Allows to check if player can stake specified amount of FEAR within specified milestone considering existing stake.
    * @param player Player's address.
    * @param milestoneId Milestone id.
    * @param stakeAmount Amount of FEAR to stake.
    * @return Total stake amount after player's possible staking, 0 if player cannot stake within specified parameters.
    * Requirements:
    * - Milestone must be setup.
    */
    function canStakeFear(address player, uint256 milestoneId, uint256 stakeAmount) public view returns (uint256) {
        checkMilestoneAndTokenSetup(milestoneId, 0);

        uint256 stakeBefore = getPlayerTotalStake(player, milestoneId);
        uint256 updatedStake = stakeBefore.add(stakeAmount);
        
        if (updatedStake <= milestones[milestoneId].stakeCap)
            return updatedStake;

        return 0;
    }

    /**
    * @dev Allows to check if player can stake specified amount of tokens within specified milestone considering existing stake.
    * @param player Player's address.
    * @param milestoneId Milestone id.
    * @param tokenId Token id.
    * @param stakeAmount Amount of tokens to stake.
    * @return Total stake amount after player's possible staking, 0 if player cannot stake within specified parameters.
    * Requirements:
    * - Milestone and token must be setup.
    */
    function canStakeToken(address player, uint256 milestoneId, uint256 tokenId, uint256 stakeAmount) public view returns (uint256) {
        checkMilestoneAndTokenSetup(milestoneId, tokenId);

        uint256 stakeBefore = getPlayerTotalStake(player, milestoneId);
        uint256 updatedStake = stakeBefore.add(tokens[milestoneId][tokenId].stakeEquivalent.mul(stakeAmount));
        
        if (updatedStake <= milestones[milestoneId].stakeCap)
            return updatedStake;

        return 0;
    }

    /**
    * @dev Returns player's remaining FEAR amount available to stake within specified milestone considering existing stake.
    * @param player Player's address.
    * @param milestoneId Milestone id.
    * @return FEAR amount available to stake in FEAR denomination.
    * Requirements:
    * - Milestone must be setup.
    */
    function fearAllowanceRemaining(address player, uint256 milestoneId) external view returns (uint256) {
        checkMilestoneAndTokenSetup(milestoneId, 0);

        uint256 stakedAmount = getPlayerTotalStake(player, milestoneId);
        uint256 remainingAllowance = milestones[milestoneId].stakeCap.sub(stakedAmount);

        return remainingAllowance;
    }

    /**
    * @dev Returns player's remaining token amount available to stake within specified milestone considering existing stake.
    * @param player Player's address.
    * @param milestoneId Milestone id.
    * @param tokenId Token id.
    * @return Token amount available to stake in token denomination.
    * Requirements:
    * - Milestone and token must be setup.
    */
    function fearTokenAllowanceRemaining(address player, uint256 milestoneId, uint256 tokenId) external view returns (uint256) {
        checkMilestoneAndTokenSetup(milestoneId, tokenId);

        uint256 stakedAmount = getPlayerTotalStake(player, milestoneId);
        uint256 remainingAllowance = milestones[milestoneId].stakeCap.sub(stakedAmount);
        
        return remainingAllowance.div(tokens[milestoneId][tokenId].stakeEquivalent);
    }

    /**
    * @dev Allows caller to stake FEAR for activating PlayToEarn mode.
    * @param milestoneId Milestone id.
    * @param stakeAmount Amount of FEAR to stake.
    * Requirements:
    * - Contract must not be paused;
    * - Milestone must be setup;
    * - Milestone must be enabled;
    * - Stake amount must be greater than zero;
    * - Caller's FEAR balance must be greater or equal to stake amount;
    * - Contract must be allowed to transfer caller's FEAR greater or equal to stake amount;
    * - Caller must be able to stake specified amount of FEAR within specified milestone.
    * Emits {StakeUpdated} event on success.
    */
    function playToEarnWithFear(uint256 milestoneId, uint256 stakeAmount) external whenNotPaused nonReentrant {
        checkMilestoneAndTokenSetup(milestoneId, 0);
        require(milestones[milestoneId].enabled, "Milestone has not been enabled");

        require(stakeAmount > 0, "You need to deposit more than zero FEAR");
        require(fearToken.balanceOf(_msgSender()) >= stakeAmount, "You do not have enough FEAR in your wallet to stake");
        
        uint256 allowance = fearToken.allowance(_msgSender(), address(this));       
        require(allowance >= stakeAmount, "Contract allowance is less than stake amount");

        uint256 canStake = canStakeFear(_msgSender(), milestoneId, stakeAmount);
        require(canStake != 0, "Total stake amount has to be lower than the stake cap");
        
        playerStakes[_msgSender()][milestoneId] = playerStakes[_msgSender()][milestoneId].add(stakeAmount);
        fearStakers.add(_msgSender());

        stakeLockExpiration[_msgSender()] = block.timestamp + stakeLockPeriod;

        require(fearToken.transferFrom(_msgSender(), address(this), stakeAmount), "Failed to transfer FEAR from your wallet");

        emit StakeUpdated(_msgSender(), milestoneId, getPlayerTotalStake(_msgSender(), milestoneId));
    }

    /**
    * @dev Allows caller to stake token for activating PlayToEarn mode.
    * @param milestoneId Milestone id.
    * @param tokenId Token id.
    * @param stakeAmount Amount of FEAR to stake.
    * Requirements:
    * - Contract must not be paused;
    * - Milestone must be setup;
    * - Milestone must be enabled;
    * - Token must be setup for specified milestone;
    * - Stake amount must be greater than zero;
    * - Caller's token balance must be greater or equal to stake amount;
    * - Contract must be allowed to transfer caller's tokens;
    * - Caller must be able to stake specified amount of tokens within specified milestone.
    * Emits {StakeUpdated} event on success.
    */
    function playToEarnWithToken(uint256 milestoneId, uint256 tokenId, uint256 stakeAmount) external whenNotPaused nonReentrant {
        checkMilestoneAndTokenSetup(milestoneId, tokenId);
        require(milestones[milestoneId].enabled, "Milestone has not been enabled");
        
        require(stakeAmount >= 1, "You need to deposit at least one token");
        require(fearNftToken.balanceOf(_msgSender(), tokenId) >= stakeAmount, "You do not have enough tokens in your wallet to stake");
        require(fearNftToken.isApprovedForAll(_msgSender(), address(this)), "Contract requires approval");
        
        uint256 canStake = canStakeToken(_msgSender(), milestoneId, tokenId, stakeAmount);
        require(canStake != 0, "Total stake amount has to be lower than the stake cap");

        playerTokens[_msgSender()][milestoneId][tokenId] = playerTokens[_msgSender()][milestoneId][tokenId].add(stakeAmount);
        fearStakers.add(_msgSender());

        if (tokens[milestoneId][tokenId].burnOnStake) {
            fearNftToken.burn(_msgSender(), tokenId, stakeAmount);
        }
        else {
            stakeLockExpiration[_msgSender()] = block.timestamp + stakeLockPeriod;
            fearNftToken.safeTransferFrom(_msgSender(), address(this), tokenId, stakeAmount, "");
        }

        emit StakeUpdated(_msgSender(), milestoneId, getPlayerTotalStake(_msgSender(), milestoneId));
    }

    /**
    * @dev Allows caller to unstake FEAR.
    * @param milestoneId Milestone id.
    * @param unstakeAmount Amount of FEAR to unstake.
    * Requirements:
    * - Milestone must be setup;
    * - Staking lock period must pass after the caller's last staking;
    * - Unstaking amount must be less or equal of caller's staked FEAR amount;
    * Emits {StakeUpdated} event on success.
    */
    function unstakeFear(uint256 milestoneId, uint256 unstakeAmount) external nonReentrant {
        checkMilestoneAndTokenSetup(milestoneId, 0);

        require(block.timestamp > stakeLockExpiration[_msgSender()], "You recently staked, please wait before withdrawing.");

        uint256 currentStake = playerStakes[_msgSender()][milestoneId];
        
        require(unstakeAmount <= currentStake, "Unstake amount exceeds staked amount");
        playerStakes[_msgSender()][milestoneId] = currentStake.sub(unstakeAmount);
        uint256 updatedStake = getPlayerTotalStake(_msgSender(), milestoneId);

        if (updatedStake == 0)
            fearStakers.remove(_msgSender());

        fearToken.transfer(_msgSender(), unstakeAmount);
        emit StakeUpdated(_msgSender(), milestoneId, updatedStake);
    }

    /**
    * @dev Allows caller to unstake tokens.
    * @param milestoneId Milestone id.
    * @param tokenId Token id.
    * @param unstakeAmount Amount of FEAR to unstake.
    * Requirements:
    * - Milestone must be setup;
    * - Token must be setup for specified milestone;
    * - Token must not be flagged as burnOnStake;
    * - Staking lock period must pass after the caller's last staking;
    * - Unstaking amount must be less or equal of caller's staked tokens amount;
    * Emits {StakeUpdated} event on success.
    */
    function unstakeToken(uint256 milestoneId, uint256 tokenId, uint256 unstakeAmount) external nonReentrant {
        checkMilestoneAndTokenSetup(milestoneId, tokenId);

        require(!tokens[milestoneId][tokenId].burnOnStake, "Token was flagged as burnOnStake");
        require(block.timestamp > stakeLockExpiration[_msgSender()], "You recently staked, please wait before withdrawing.");

        uint256 currentStake = playerTokens[_msgSender()][milestoneId][tokenId];

        require(unstakeAmount <= currentStake, "Unstake amount exceeds staked amount");
        playerTokens[_msgSender()][milestoneId][tokenId] = currentStake.sub(unstakeAmount);
        uint256 updatedStake = getPlayerTotalStake(_msgSender(), milestoneId);

        if (updatedStake == 0)
            fearStakers.remove(_msgSender());

        fearNftToken.safeTransferFrom(address(this), _msgSender(), tokenId, unstakeAmount, "");
        emit StakeUpdated(_msgSender(), milestoneId, updatedStake);
    }


    function setupMilestone(uint256 milestoneId, bool enabled, uint256 stakeCap, uint256[] calldata tokenIds) external onlyRole(DEFAULT_ADMIN_ROLE) {
        milestones[milestoneId] = Milestone(milestoneId, enabled, stakeCap, tokenIds);
    }

    function setupToken(uint256 tokenId, uint256 milestoneId, uint256 stakeEquivalent, bool burn) external onlyRole(DEFAULT_ADMIN_ROLE) {
        checkMilestoneAndTokenSetup(milestoneId, 0);
        tokens[milestoneId][tokenId] = Token(tokenId, milestoneId, stakeEquivalent, burn);
    }

    function setStakeLockPeriod(uint16 _days) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakeLockPeriod = _days * (1 days);
        emit StakeLockPeriodChanged(_days);
    }

    function releaseAllLocks() external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < fearStakers.length(); i++)
            stakeLockExpiration[fearStakers.at(i)] = block.timestamp - 1;
    }

    function importData(address player, uint256 milestoneId, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(initialDataImportIsPossible, "Data import is impossible");
        checkMilestoneAndTokenSetup(milestoneId, 0);
        playerStakes[player][milestoneId] = amount;
    }

    function importData(address player, uint256 milestoneId, uint256 tokenId, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(initialDataImportIsPossible, "Data import is impossible");
        checkMilestoneAndTokenSetup(milestoneId, tokenId);
        playerTokens[player][milestoneId][tokenId] = amount;
    }
}