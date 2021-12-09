/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

// File: CacaLendMarket/StructuredLinkedList.sol


pragma solidity 0.8.10;

interface  IStructureInterface {
    function getValue(uint256 _id) external view returns (uint256);
}

/**
 * @title StructuredLinkedList
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev An utility library for using sorted linked list data structures in your Solidity project.
 */
library StructuredLinkedList {

    uint256 private constant _NULL = 0;
    uint256 private constant _HEAD = 0;

    bool private constant _PREV = false;
    bool private constant _NEXT = true;

    struct List {
        uint256 size;
        mapping(uint256 => mapping(bool => uint256)) list;
    }

    /**
     * @dev Checks if the list exists
     * @param self stored linked list from contract
     * @return bool true if list exists, false otherwise
     */
    function listExists(List storage self) internal view returns (bool) {
        // if the head nodes previous or next pointers both point to itself, then there are no items in the list
        if (self.list[_HEAD][_PREV] != _HEAD || self.list[_HEAD][_NEXT] != _HEAD) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Checks if the node exists
     * @param self stored linked list from contract
     * @param _node a node to search for
     * @return bool true if node exists, false otherwise
     */
    function nodeExists(List storage self, uint256 _node) internal view returns (bool) {
        if (self.list[_node][_PREV] == _HEAD && self.list[_node][_NEXT] == _HEAD) {
            if (self.list[_HEAD][_NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Returns the number of elements in the list
     * @param self stored linked list from contract
     * @return uint256
     */
    function sizeOf(List storage self) internal view returns (uint256) {
        return self.size;
    }

    /**
     * @dev Returns the links of a node as a tuple
     * @param self stored linked list from contract
     * @param _node id of the node to get
     * @return bool, uint256, uint256 true if node exists or false otherwise, previous node, next node
     */
    function getNode(List storage self, uint256 _node) internal view returns (bool, uint256, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0, 0);
        } else {
            return (true, self.list[_node][_PREV], self.list[_node][_NEXT]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @param _direction direction to step in
     * @return bool, uint256 true if node exists or false otherwise, node in _direction
     */
    function getAdjacent(List storage self, uint256 _node, bool _direction) internal view returns (bool, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0);
        } else {
            return (true, self.list[_node][_direction]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_NEXT`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, next node
     */
    function getNextNode(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return getAdjacent(self, _node, _NEXT);
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_PREV`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, previous node
     */
    function getPreviousNode(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return getAdjacent(self, _node, _PREV);
    }

    /**
     * @dev Can be used before `insert` to build an ordered list.
     * @dev Get the node and then `insertBefore` or `insertAfter` basing on your list order.
     * @dev If you want to order basing on other than `structure.getValue()` override this function
     * @param self stored linked list from contract
     * @param _structure the structure instance
     * @param _value value to seek
     * @return uint256 next node with a value less than _value
     */
    function getSortedSpot(List storage self, address _structure, uint256 _value) internal view returns (uint256) {
        if (sizeOf(self) == 0) {
            return 0;
        }

        uint256 next;
        (, next) = getAdjacent(self, _HEAD, _NEXT);
        while ((next != 0) && (_value <= IStructureInterface(_structure).getValue(next))) {
            next = self.list[next][_NEXT];
        }
        return next;
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_NEXT`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function insertAfter(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return _insert(self, _node, _new, _NEXT);
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_PREV`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function insertBefore(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return _insert(self, _node, _new, _PREV);
    }

    /**
     * @dev Removes an entry from the linked list
     * @param self stored linked list from contract
     * @param _node node to remove from the list
     * @return uint256 the removed node
     */
    function remove(List storage self, uint256 _node) internal returns (uint256) {
        if ((_node == _NULL) || (!nodeExists(self, _node))) {
            return 0;
        }
        _createLink(self, self.list[_node][_PREV], self.list[_node][_NEXT], _NEXT);
        delete self.list[_node][_PREV];
        delete self.list[_node][_NEXT];

        self.size -= 1; // NOT: SafeMath library should be used here to decrement.

        return _node;
    }

    /**
     * @dev Pushes an entry to the head of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the head
     * @return bool true if success, false otherwise
     */
    function pushFront(List storage self, uint256 _node) internal returns (bool) {
        return _push(self, _node, _NEXT);
    }

    /**
     * @dev Pushes an entry to the tail of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the tail
     * @return bool true if success, false otherwise
     */
    function pushBack(List storage self, uint256 _node) internal returns (bool) {
        return _push(self, _node, _PREV);
    }

    /**
     * @dev Pops the first entry from the head of the linked list
     * @param self stored linked list from contract
     * @return uint256 the removed node
     */
    function popFront(List storage self) internal returns (uint256) {
        return _pop(self, _NEXT);
    }

    /**
     * @dev Pops the first entry from the tail of the linked list
     * @param self stored linked list from contract
     * @return uint256 the removed node
     */
    function popBack(List storage self) internal returns (uint256) {
        return _pop(self, _PREV);
    }

    /**
     * @dev Pushes an entry to the head of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the head
     * @param _direction push to the head (_NEXT) or tail (_PREV)
     * @return bool true if success, false otherwise
     */
    function _push(List storage self, uint256 _node, bool _direction) private returns (bool) {
        return _insert(self, _HEAD, _node, _direction);
    }

    /**
     * @dev Pops the first entry from the linked list
     * @param self stored linked list from contract
     * @param _direction pop from the head (_NEXT) or the tail (_PREV)
     * @return uint256 the removed node
     */
    function _pop(List storage self, bool _direction) private returns (uint256) {
        uint256 adj;
        (, adj) = getAdjacent(self, _HEAD, _direction);
        return remove(self, adj);
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @param _direction direction to insert node in
     * @return bool true if success, false otherwise
     */
    function _insert(List storage self, uint256 _node, uint256 _new, bool _direction) private returns (bool) {
        if (!nodeExists(self, _new) && nodeExists(self, _node)) {
            uint256 c = self.list[_node][_direction];
            _createLink(self, _node, _new, _direction);
            _createLink(self, _new, c, _direction);

            self.size += 1; // NOT: SafeMath library should be used here to increment.

            return true;
        }

        return false;
    }

    /**
     * @dev Creates a bidirectional link between two nodes on direction `_direction`
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _link node to link to in the _direction
     * @param _direction direction to insert node in
     */
    function _createLink(List storage self, uint256 _node, uint256 _link, bool _direction) private {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }
}
// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

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

// File: CacaLendMarket/LendingMarket.sol


pragma solidity 0.8.10;










interface ITradeMarket {
    function tokenOrderMap(uint256 tokenId) view external returns(uint256, address, address, uint256, uint256, uint256);
}


interface ITreasury {
    function stakedWantTokens(address _tokenAddr, address _user) external view returns (uint256);
    function deposit(address _tokenAddr, address _userAddr, uint256 _wantAmt) external;
    function withdraw(address _tokenAddr, address _userAddr, uint256 _wantAmt) external;
}

contract TimeListInterface is IStructureInterface {
    ITradeMarket public tradeMarket;
    
    constructor(address _tradeMarket) {
        tradeMarket = (ITradeMarket)(_tradeMarket);
    }
    
    function getValue(uint256 _tokenId) view public override returns(uint256) {
        (,,,,uint256 hangTime,) = tradeMarket.tokenOrderMap(_tokenId);
        return hangTime;
    }
}

contract LendingMarket is Ownable, IStructureInterface {
    using SafeMath for uint256;
    using StructuredLinkedList for StructuredLinkedList.List;
    using EnumerableSet for EnumerableSet.UintSet;
    
    // Offline: 未挂单或者用户取消挂单时的状态
    // InHanging: 挂单中
    // InFreezingTime: 已出租，但处于最小租期内
    // Lending: 已出租，可归还
    // OverTime: 已出租，但已超过最长租期，出租者可随时没收押金，如果承租者在超时后归还，超时之后的费用收取自动加倍
    // Finish: 订单已完结
    enum OrderStatus {Offline, InHanging, InFreezingTime, Lending, OverTime, Finished}

    struct OrderInfo {
        uint256 id;
        address seller;         // 出租人
        address buyer;          // 承租人
        uint256 depositAmount;  // 需要的押金，最后租金从押金里面扣除
        uint256 feePerSecond;          // 每区块需要支付的租金
        uint256 claimedAmount;  // 已提取的租金数量
        uint256 minLendSpanTime;  // 最小租赁时长, 在此时间内，不可归还
        uint256 maxLendSpanTime;  // 最大租赁时长, 超过此时间，出租方可以没收押金，出租方面临的风险是当元兽暴涨的时候，借入方不再归还元兽，于是只能没收押金
        uint256 hangTime;       // 挂单时间
        uint256 dealTime;       // 下单时间
        uint256 returnTime;     // 归还时间，0：表示未归还，>0:已归还
        bool    bAutoHanged;     // 承租人归还后是否自动重新挂单
    }

    uint256 public ProfitPercent = 10;
    uint256 constant public BasePercent = 100;
    address public platform;
    uint256 public platformClaimedAmount;
    uint256 public platformTotalAmount;
    
    mapping(address => EnumerableSet.UintSet) private ownerUnRentedOrdersMap;  // 出租人当前有效的所有未出租的订单，可以取消
    mapping(address => EnumerableSet.UintSet) private ownerRentedOrdersMap;    // 出租人和承租人当前有效的所有正在出租的订单，此类订单在正在租赁期间不可取消，只有超时或归还后才能取消
    OrderInfo[] public finishedOrders;   // 已经完全终结所有的订单
    
    StructuredLinkedList.List private orderListByTime;           // 根据挂单时间排序
    StructuredLinkedList.List private orderListByPrice;          // 根据租金价格排序
    mapping(uint256 => OrderInfo) public tokenOrderMap;          // 每个订单的信息
    
    mapping(address => uint256[]) public sellerOrdersMap;        // 每个出租人已经终结的所有订单，注意，当出租人在超时后主动终结的订单，也需要添加到buyerOrdersMap里
    mapping(address => uint256[]) public buyerOrdersMap;         // 每个承租人已经终结的所有订单
    
    IERC721 public nft;
    IERC20 public erc20;
    TimeListInterface public timeListInterface;

    ITreasury public treasury;   // 会对用户押金进行理财的金库
    
    modifier onlySeller(uint256 _tokenId) {
        require(tokenOrderMap[_tokenId].seller == msg.sender, "TradeMarket: only seller has the authority.");
        _;
    }

    modifier onlyBuyer(uint256 _tokenId) {
        require(tokenOrderMap[_tokenId].buyer == msg.sender, "TradeMarket: only seller has the authority.");
        _;
    }

    event OrderAdded(address indexed sellder, uint256 indexed tokenId, uint256 depositAmount, uint256 feePerSecond);
    event OrderCanceled(address indexed sellder, uint256 indexed tokenId);
    event OrderTaked(address indexed sellder, address indexed buyer, uint256 indexed tokenId);
    event OrderReturned(address indexed buyer, uint256 indexed tokenId);
    event OrderForcedReturned(address indexed sellder, uint256 indexed tokenId);
    
    constructor(address _nft, address _erc20, address _platform, address _treasury) {
        nft = (IERC721)(_nft);
        erc20 = (IERC20)(_erc20);
        timeListInterface = new TimeListInterface(address(this));
        platform = _platform;
        treasury = ITreasury(_treasury);
    }
    
    // 根据tokenID获得下单价格
    function getValue(uint256 _tokenId) view public override returns(uint256) {
        return tokenOrderMap[_tokenId].feePerSecond;
    }

    // 添加订单，会按价格和时间进行排序，方便前端提取数据
    function addOrder(uint256 _tokenId, uint256 _depositAmount, uint256 _feePerSecond, uint256 _minLendSpanTime, uint256 _maxLendSpanTime, bool _bAutoHanged) public {
        require(msg.sender == tx.origin, "TradeMarket: Only EOA");
        nft.transferFrom(msg.sender, address(this), _tokenId);  // approve firstly
        addOrderInner(msg.sender, _tokenId, _depositAmount, _feePerSecond, _minLendSpanTime, _maxLendSpanTime, _bAutoHanged);        
    }

    function addOrderInner(address _seller, uint256 _tokenId, uint256 _depositAmount, uint256 _feePerSecond, 
                           uint256 _minLendSpanTime, uint256 _maxLendSpanTime, bool _bAutoHanged) private {
        tokenOrderMap[_tokenId] = OrderInfo({id: _tokenId, 
                                             seller: _seller, 
                                             buyer: address(0), 
                                             depositAmount: _depositAmount,
                                             feePerSecond: _feePerSecond, 
                                             claimedAmount: 0,
                                             minLendSpanTime: _minLendSpanTime,
                                             maxLendSpanTime: _maxLendSpanTime,
                                             hangTime: block.timestamp, 
                                             dealTime: 0,
                                             returnTime: 0,
                                             bAutoHanged: _bAutoHanged});
        
        uint256 nextIndexByPrice = orderListByPrice.getSortedSpot(address(this), _feePerSecond);  // price descending order
        orderListByPrice.insertBefore(nextIndexByPrice, _tokenId);
        
        uint256 nextIndexByTime = orderListByTime.getSortedSpot(address(timeListInterface), block.timestamp);  // time descending order
        orderListByTime.insertBefore(nextIndexByTime, _tokenId);
        
        ownerUnRentedOrdersMap[_seller].add(_tokenId);

        emit OrderAdded(_seller, _tokenId, _depositAmount, _feePerSecond);                       
    }

    // 用户取消挂单
    function cancelOrder(uint256 _tokenId) public onlySeller(_tokenId) {
        require(msg.sender == tx.origin, "TradeMarket: Only EOA");
        require(getOrderStatus(_tokenId) == OrderStatus.InHanging, "TradeMarket: order is NOT in hanging status.");
        OrderInfo memory orderInfo = tokenOrderMap[_tokenId];
        
        nft.transferFrom(address(this), orderInfo.seller, _tokenId);
        orderListByPrice.remove(_tokenId);
        orderListByTime.remove(_tokenId);
        delete tokenOrderMap[_tokenId];
        ownerUnRentedOrdersMap[msg.sender].remove(_tokenId);

        emit OrderCanceled(orderInfo.seller, _tokenId);
    }

    // 用户下单
    function takeOrder(uint256 _tokenId) external {
        require(msg.sender == tx.origin, "TradeMarket: Only EOA");
        require(orderListByPrice.nodeExists(_tokenId), "TradeMarket: order is NOT exist in order list.");
        require(getOrderStatus(_tokenId) == OrderStatus.InHanging, "TradeMarket: order is NOT in hanging status.");
        
        OrderInfo storage orderInfo = tokenOrderMap[_tokenId];
        require(msg.sender != orderInfo.seller, "TradeMarket: seller can't be buyer.");

        nft.transferFrom(address(this), msg.sender, _tokenId);
        orderInfo.buyer = msg.sender;
        orderInfo.dealTime = block.timestamp;
        orderListByPrice.remove(_tokenId);
        orderListByTime.remove(_tokenId);
        
        ownerUnRentedOrdersMap[orderInfo.seller].remove(_tokenId);
        ownerRentedOrdersMap[orderInfo.seller].add(_tokenId);
        ownerRentedOrdersMap[orderInfo.buyer].add(_tokenId);
        delete tokenOrderMap[_tokenId];

        erc20.transferFrom(msg.sender, address(this), tokenOrderMap[_tokenId].depositAmount);
        
        if (address(treasury) != address(0)) {
            erc20.approve(address(treasury), tokenOrderMap[_tokenId].depositAmount);
            treasury.deposit(address(erc20), msg.sender, tokenOrderMap[_tokenId].depositAmount);
        }

        emit OrderTaked(orderInfo.seller, orderInfo.buyer, _tokenId);
    }

    function returnNFT(uint256 _tokenId) external onlyBuyer(_tokenId) {
        require(msg.sender == tx.origin, "TradeMarket: Only EOA");
        OrderStatus orderStatus = getOrderStatus(_tokenId);
        require(orderStatus == OrderStatus.Lending || orderStatus == OrderStatus.OverTime, "TradeMarket: order is NOT Lending or OverTime status.");

        OrderInfo memory orderInfo = tokenOrderMap[_tokenId];

        nft.transferFrom(msg.sender, orderInfo.seller, _tokenId);  // 将NFT转给Seller

        uint256 leftRentAmount = getClaimFee(_tokenId);

        uint256 returnedDepositAmount = orderInfo.depositAmount.sub(leftRentAmount.add(orderInfo.claimedAmount));
        if (address(treasury) != address(0)) {
            treasury.withdraw(address(erc20), msg.sender, returnedDepositAmount);
        }
        erc20.transfer(msg.sender, returnedDepositAmount);  // 将剩余押金(扣除了租金)还给buyer，租金部分需要Seller自己去提取
        
        processFinishedOrder(_tokenId);
        
        emit OrderReturned(orderInfo.buyer, _tokenId);
        
        if (orderInfo.bAutoHanged) {
            addOrderInner(orderInfo.seller, _tokenId, orderInfo.depositAmount, orderInfo.feePerSecond, 
                          orderInfo.minLendSpanTime, orderInfo.maxLendSpanTime, orderInfo.bAutoHanged); 
        }
    }

    // 出租人发起清算
    function liquidateOrder(uint256 _tokenId) external onlySeller(_tokenId) {
        require(msg.sender == tx.origin, "TradeMarket: Only EOA");
        OrderStatus orderStatus = getOrderStatus(_tokenId);
        require(orderStatus == OrderStatus.OverTime, "TradeMarket: order is NOT OverTime status.");

        claimLendFee(_tokenId);

        OrderInfo memory orderInfo = tokenOrderMap[_tokenId];
        uint256 leftAmount4Seller = orderInfo.depositAmount.sub(orderInfo.claimedAmount);
        if (address(treasury) != address(0)) {
            treasury.withdraw(address(erc20), orderInfo.buyer, leftAmount4Seller);
        }
        erc20.transfer(orderInfo.seller, leftAmount4Seller);

        processFinishedOrder(_tokenId);
    }

    function setAutoHanged(uint256 _tokenId, bool _bAutoHanged) external onlySeller(_tokenId) {
        require(msg.sender == tx.origin, "TradeMarket: Only EOA");
        OrderInfo storage orderInfo = tokenOrderMap[_tokenId];
        orderInfo.bAutoHanged = _bAutoHanged;
    }

    function claimLendFee(uint256 _tokenId) public onlySeller(_tokenId) {
        OrderStatus orderStatus = getOrderStatus(_tokenId);
        require(orderStatus != OrderStatus.InHanging, "TradeMarket: order is InHanging status.");

        uint256 leftRentAmount = getClaimFee(_tokenId);
        if (address(treasury) != address(0)) {
            treasury.withdraw(address(erc20), tokenOrderMap[_tokenId].buyer, leftRentAmount);
        }
        transferRentFee(msg.sender, leftRentAmount);

        tokenOrderMap[_tokenId].claimedAmount = tokenOrderMap[_tokenId].claimedAmount.add(leftRentAmount);
    }

    function getClaimFee(uint256 _tokenId) view public returns(uint256) {
        OrderStatus orderStatus = getOrderStatus(_tokenId);
        if(orderStatus == OrderStatus.Offline || orderStatus == OrderStatus.InHanging) return 0;

        OrderInfo memory orderInfo = tokenOrderMap[_tokenId];
        uint256 totalRentAmount = 0;
        if (orderStatus == OrderStatus.Finished || orderStatus == OrderStatus.OverTime) {
            uint256 endTime = (orderStatus == OrderStatus.Finished) ? tokenOrderMap[_tokenId].returnTime : block.timestamp;
            totalRentAmount = orderInfo.feePerSecond.mul(orderInfo.maxLendSpanTime);
            totalRentAmount = totalRentAmount.add(orderInfo.feePerSecond.mul(2).mul(endTime - orderInfo.dealTime - orderInfo.maxLendSpanTime));
        } else if (orderStatus == OrderStatus.OverTime) {
            totalRentAmount = orderInfo.feePerSecond.mul(block.timestamp - orderInfo.dealTime);
        }

        uint256 leftRentAmount = totalRentAmount.sub(orderInfo.claimedAmount);
        return leftRentAmount;
    }

    function getTreasuryInterest(address _buyer) view public returns(uint256) {
        if (address(treasury) == address(0)) return 0;

        uint256 leftAmount = treasury.stakedWantTokens(address(erc20), _buyer);
        
        uint256 length = ownerRentedOrdersMap[_buyer].length();
        
        // 获取用户占有的want token数量，此数量+已经提走的租金-抵押的押金 = 产生的理财利息
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = ownerRentedOrdersMap[_buyer].at(i);
            leftAmount = leftAmount.add(tokenOrderMap[tokenId].claimedAmount).sub(tokenOrderMap[tokenId].depositAmount);
        }

        return leftAmount;
    }

    function claimTreasuryInterest(address _buyer) external {
        require((address(treasury) != address(0)), "LendingMarket: treasury hasn't been set.");
        uint256 claimableAmount = getTreasuryInterest(_buyer);
        treasury.withdraw(address(erc20), _buyer, claimableAmount);
        erc20.transfer(_buyer, claimableAmount);
    } 
    
    function processFinishedOrder(uint256 _tokenId) private {
        finishedOrders.push(tokenOrderMap[_tokenId]);
        uint256 length = finishedOrders.length;
        sellerOrdersMap[tokenOrderMap[_tokenId].seller].push(length - 1);
        buyerOrdersMap[tokenOrderMap[_tokenId].buyer].push(length - 1);

        ownerRentedOrdersMap[tokenOrderMap[_tokenId].seller].remove(_tokenId);
        ownerRentedOrdersMap[tokenOrderMap[_tokenId].buyer].remove(_tokenId);

        tokenOrderMap[_tokenId].returnTime = block.timestamp;
    }

    function getOrderStatus(uint256 _tokenId) view public returns(OrderStatus) {
        if (tokenOrderMap[_tokenId].id == 0) return OrderStatus.Offline;

        if (tokenOrderMap[_tokenId].returnTime > 0) return OrderStatus.Finished;

        if (tokenOrderMap[_tokenId].dealTime > 0) {
            if (block.timestamp > tokenOrderMap[_tokenId].dealTime.add(tokenOrderMap[_tokenId].maxLendSpanTime)) return OrderStatus.OverTime;
            if (block.timestamp < tokenOrderMap[_tokenId].dealTime.add(tokenOrderMap[_tokenId].minLendSpanTime)) return OrderStatus.InFreezingTime;
            return OrderStatus.Lending;
        }
        
        return OrderStatus.InHanging;
    }
    
    function getOrderCount() view public returns(uint256) {
        return orderListByPrice.sizeOf();
    }
    
    // 通过价格获取订单
    // _startNodeId：起始节点ID，值为0的时候，表示根元素，不保存实际的订单ID
    function getOrdersByPrice(uint256 _startNodeId, uint256 _length, bool descending) view public returns(OrderInfo[] memory orderInfos) {
        orderInfos = new OrderInfo[](_length);
        uint256 index = 0;
        (bool exist, uint256 orderId) = descending ? orderListByPrice.getNextNode(_startNodeId) : orderListByPrice.getPreviousNode(_startNodeId);
        while(exist) {
            orderInfos[index++] = tokenOrderMap[orderId];
            if (index == _length) break;
            
            (exist, orderId) = descending ? orderListByPrice.getNextNode(orderId) : orderListByPrice.getPreviousNode(orderId);
        }
    }
    
    // 得到当前最小出租价格的订单
    function getMinPriceOrder() view public returns(OrderInfo memory orderInfo) {
         (, uint256 orderId) = orderListByPrice.getNextNode(0);
         return tokenOrderMap[orderId];
    }
    
    // 得到当前最大出租价格的订单
    function getMaxPriceOrder() view public returns(OrderInfo memory orderInfo) {
        (, uint256 orderId) = orderListByPrice.getPreviousNode(0);
         return tokenOrderMap[orderId];
    }
    
    // 得到离指定价格最近的节点ID，通过此ID，结合getOrderIdsByPrice便可遍历出大于或小于指定价格的订单信息
    function getSpotPriceId(uint256 _spotPrice) view public returns(uint256) {
        uint256 nextIndex = orderListByPrice.getSortedSpot(address(this), _spotPrice);
        return nextIndex;
    }
    
    // 通过挂单时间获取订单
    // _startNodeId：起始节点ID，值为0的时候，表示根元素，不保存实际的订单ID
    function getOrdersByTime(uint256 _startNodeId, uint256 _length, bool descending) view public returns(OrderInfo[] memory orderInfos) {
        orderInfos = new OrderInfo[](_length);
        uint256 index = 0;
        (bool exist, uint256 orderId) = descending ? orderListByTime.getNextNode(_startNodeId) : orderListByTime.getPreviousNode(_startNodeId);
        while(exist) {
            orderInfos[index++] = tokenOrderMap[orderId];
            if (index == _length) break;
            
            (exist, orderId) = descending ? orderListByTime.getNextNode(orderId) : orderListByTime.getPreviousNode(orderId);
        }
    }
    
    // 获得最近下单的订单（尚未出租出去的订单）
    function getMinTimeOrder() view public returns(OrderInfo memory orderInfo) {
         (, uint256 orderId) = orderListByTime.getNextNode(0);
         return tokenOrderMap[orderId];
    }
    
    // 获得最早下单的订单（尚未出租出去的订单）
    function getMaxTimeOrder() view public returns(OrderInfo memory orderInfo) {
        (, uint256 orderId) = orderListByTime.getPreviousNode(0);
         return tokenOrderMap[orderId];
    }
    
    // 获得离指定时间最近的订单所在的节点ID，通过此ID, 结合getOrderIdsByTime，便可按指定时间对订单进行遍历
    function getSpotTimeId(uint256 _spotTime) view public returns(uint256) {
        uint256 nextIndex = orderListByTime.getSortedSpot(address(timeListInterface), _spotTime);
        return nextIndex;
    }

    // 获取已经结束的订单数量
    function getDealedOrderNumber() view public returns(uint256) {
        return finishedOrders.length;
    }

    // 获取每个出租人已经结束的订单数量
    function getOrderNumOfSeller(address _seller)  view public returns(uint256) {
        return sellerOrdersMap[_seller].length;
    }
    
    // 获取每个承租人已经结束的订单数量
    function getOrderNumOfBuyer(address _buyer)  view public returns(uint256) {
        return buyerOrdersMap[_buyer].length;
    }
    
    // 获取每个出租人正在挂单的订单数量
    function unRentedOrdersNumber(address _owner) view public returns(uint256) {
        return ownerUnRentedOrdersMap[_owner].length();
    }
    
    function getUnRentedOrders(address _owner, uint256 _fromId, uint256 _toId) view public returns(OrderInfo[] memory orderInfos) {
        uint256 length = ownerUnRentedOrdersMap[_owner].length();
        if (_toId > length) _toId = length;
        require(_fromId < _toId, "TradeMarket: index out of range!");
        
        orderInfos = new OrderInfo[](_toId - _fromId);
        uint256 count = 0;
        for (uint256 i = _fromId; i < _toId; i++) {
            uint256 tokenId = ownerUnRentedOrdersMap[_owner].at(i);
            orderInfos[count++] = tokenOrderMap[tokenId];
        }
    }


    // 获取每个出租人和承租人正在租借状态中的订单数量
    function rentedOrdersNumber(address _owner) view public returns(uint256) {
        return ownerRentedOrdersMap[_owner].length();
    }
    
    function getRentedOrders(address _owner, uint256 _fromId, uint256 _toId) view public returns(OrderInfo[] memory orderInfos) {
        uint256 length = ownerRentedOrdersMap[_owner].length();
        if (_toId > length) _toId = length;
        require(_fromId < _toId, "TradeMarket: index out of range!");
        
        orderInfos = new OrderInfo[](_toId - _fromId);
        uint256 count = 0;
        for (uint256 i = _fromId; i < _toId; i++) {
            uint256 tokenId = ownerRentedOrdersMap[_owner].at(i);
            orderInfos[count++] = tokenOrderMap[tokenId];
        }
    }
    
    function setProfitPercent(uint256 _profitPercent) public onlyOwner {
        ProfitPercent = _profitPercent;
    }

    function setPlatform(address _platform) public onlyOwner {
        platform = _platform;
    }

    function transferRentFee(address _seller, uint256 _rentFee) private {
        uint256 platformFee = _rentFee.mul(ProfitPercent).div(BasePercent);
        erc20.transfer(_seller, _rentFee.sub(platformFee));
        platformTotalAmount = platformTotalAmount.add(platformFee);
    }

    function withdrawPlatformFee() external onlyOwner {
        erc20.transfer(platform, platformTotalAmount.sub(platformClaimedAmount));
        platformClaimedAmount = platformTotalAmount;
    }
}