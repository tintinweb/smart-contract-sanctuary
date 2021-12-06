/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

pragma solidity ^0.8.0;


// 
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

// 
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

// 
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

// 
library LedgerTypes {
    struct OrderInfo {
        uint256 id;
        address askAsset;
        address offerAsset;
        address owner;
    }
}

library SlidingWindowLedgerLibrary {
    using EnumerableOrderInfoMap for EnumerableOrderInfoMap.UintToLedgerInfo;

    struct SlidingWindow {
        // Contains mapping from fulfillment time into orders.
        mapping(uint256 => EnumerableOrderInfoMap.UintToLedgerInfo) orders;

        // Contains mapping from window into the order (to find order in 'orders' map).
        mapping(uint256 => uint256) orderWindow;
    }

    function add(SlidingWindow storage sw, LedgerTypes.OrderInfo memory orderInfo, uint256 window) external returns(bool) {
        sw.orderWindow[orderInfo.id] = window;

        return sw.orders[window].set(orderInfo.id, orderInfo);
    }

    function get(SlidingWindow storage sw, uint256 orderId) internal view returns (LedgerTypes.OrderInfo memory) {
        return sw.orders[sw.orderWindow[orderId]].get(orderId);
    }

    function getAt(SlidingWindow storage sw, uint256 window, uint256 index) internal view returns (uint256, LedgerTypes.OrderInfo memory) {
        return sw.orders[window].at(index);
    }

    function count(SlidingWindow storage sw, uint256 window) internal view returns (uint256) {
        return sw.orders[window].length();
    }

    function getEndTime(SlidingWindow storage sw, uint256 orderId) external view returns(uint256) {
        return sw.orderWindow[orderId];
    }

    function ownerOf(SlidingWindow storage sw, uint256 orderId) external view returns(address) {
        uint256 window = sw.orderWindow[orderId];
        require(window != 0, "Order doesn't exist");
        return sw.orders[window].get(orderId).owner;
    }

    function remove(SlidingWindow storage sw, uint256 orderId) external returns(bool) {
        (bool success, LedgerTypes.OrderInfo memory order) = sw.orders[sw.orderWindow[orderId]].tryGet(orderId);
        require(success, "Order doesn't exist");
        require(order.owner == msg.sender, "Not order owner");
        bool removed = sw.orders[sw.orderWindow[orderId]].remove(orderId);
        delete sw.orderWindow[orderId];

        return removed;
    }
}

// 
/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToLedgerInfo;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToLedgerInfo private myMap;
 * }
 * ```
 *
 */
library EnumerableOrderInfoMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    
    struct Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => LedgerTypes.OrderInfo) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        bytes32 key,
        LedgerTypes.OrderInfo memory value
    ) private returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index) private view returns (bytes32, LedgerTypes.OrderInfo memory) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, LedgerTypes.OrderInfo memory) {
        LedgerTypes.OrderInfo memory value = map._values[key];
        if (value.id == 0) {
            return (false, value);
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (LedgerTypes.OrderInfo memory) {
        LedgerTypes.OrderInfo memory value = map._values[key];
        require(value.id != 0 || _contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(
        Map storage map,
        bytes32 key,
        string memory errorMessage
    ) private view returns (LedgerTypes.OrderInfo memory) {
        LedgerTypes.OrderInfo memory value = map._values[key];
        require(value.id != 0 || _contains(map, key), errorMessage);
        return value;
    }

    // UintToLedgerInfo map

    struct UintToLedgerInfo {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToLedgerInfo storage map,
        uint256 key,
        LedgerTypes.OrderInfo memory value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToLedgerInfo storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToLedgerInfo storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToLedgerInfo storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToLedgerInfo storage map, uint256 index) internal view returns (uint256, LedgerTypes.OrderInfo memory) {
        (bytes32 key, LedgerTypes.OrderInfo memory value) = _at(map._inner, index);
        return (uint256(key), value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToLedgerInfo storage map, uint256 key) internal view returns (bool, LedgerTypes.OrderInfo memory) {
        (bool success, LedgerTypes.OrderInfo memory value) = _tryGet(map._inner, bytes32(key));
        return (success, value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToLedgerInfo storage map, uint256 key) internal view returns (LedgerTypes.OrderInfo memory) {
        return _get(map._inner, bytes32(key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToLedgerInfo storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (LedgerTypes.OrderInfo memory) {
        return _get(map._inner, bytes32(key), errorMessage);
    }
}

// 
contract SlidingWindowLedger is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;
    using SlidingWindowLedgerLibrary for SlidingWindowLedgerLibrary.SlidingWindow;

    event OrderAdded(uint256 indexed orderId, address askAsset, address offerAsset, uint256 amount, address owner);
    event OrderRemoved(uint256 indexed orderId);

    // Contains currently known fulfillment windows.
    EnumerableSet.UintSet internal windows;
    // Contains available orders lengths.
    EnumerableSet.UintSet internal availableOrderLengths;

    // Order library
    SlidingWindowLedgerLibrary.SlidingWindow internal orders;

    // Fulfilment configuration
    uint256 public fulfilmentPrecision;
    uint256 public fulfilmentShift;

    // Id of the last created order
    uint256 internal orderId;

    constructor (uint256 fulfilmentPrecision_, uint256 fulfilmentShift_, uint256[] memory orderLengths_) {
        fulfilmentPrecision = fulfilmentPrecision_;
        fulfilmentShift = fulfilmentShift_;
        for (uint256 i = 0; i < orderLengths_.length; i++) {
            // slither-disable-next-line unused-return
            availableOrderLengths.add(orderLengths_[i]);
        }
    }

    function setFulfillmentConfig(uint256 fulfilmentPrecision_, uint256 fulfilmentShift_) external onlyOwner {
        // solhint-disable-next-line reason-string
        require(fulfilmentPrecision_ > fulfilmentShift_, "Precision must be greater than shift");
        fulfilmentPrecision = fulfilmentPrecision_;
        fulfilmentShift = fulfilmentShift_;
    }

    function addOrderLengths(uint256[] memory orderLengths) external onlyOwner {
        for (uint256 i = 0; i < orderLengths.length; i++) {
            require(availableOrderLengths.add(orderLengths[i]), "Order length already added");
        }
    }

    function removeOrderLengths(uint256[] memory orderLengths) external onlyOwner {
        for (uint256 i = 0; i < orderLengths.length; i++) {
            require(availableOrderLengths.remove(orderLengths[i]), "Order length not available");
        }
    }

    function getOrderLengths() external view returns(uint256[] memory) {
        return availableOrderLengths.values();
    }

    function _calculateWindow(uint256 endsInSec) internal view returns(uint256) {
        // solhint-disable-next-line not-rely-on-time
        uint256 time = block.timestamp + endsInSec;
        uint256 value = ((time / fulfilmentPrecision) + 1) * fulfilmentPrecision;

        return  value + fulfilmentShift;
    }

    function ownerOfOrder(uint256 orderId_) external view returns(address) {
        return orders.ownerOf(orderId_);
    }

    function addOrder(LedgerTypes.OrderInfo memory orderInfo, uint256 endsInSec) external returns(uint256) {
        require(availableOrderLengths.contains(endsInSec), "Order length is not supported.");

        uint256 window = _calculateWindow(endsInSec);

        orderId += 1;
        orderInfo.id = orderId;
        orderInfo.owner = msg.sender;
        // slither-disable-next-line unused-return
        windows.add(window);

        // slither-disable-next-line unused-return
        orders.add(orderInfo, window);

        emit OrderAdded(orderId, orderInfo.askAsset, orderInfo.offerAsset, 0, msg.sender);
        return orderId;
    }

    function removeOrder(uint256 orderId_) external returns(bool) {
        emit OrderRemoved(orderId_);
        return orders.remove(orderId_);
    }

    function getOrder(uint256 orderId_) external view returns(LedgerTypes.OrderInfo memory) {
        return orders.get(orderId_);
    }

    function getOrderEndTime(uint256 orderId_) external view returns(uint256) {
        return orders.getEndTime(orderId_);
    }

    function getPossibleWindows() external view returns(uint256[] memory) {
        return windows.values();
    }

    function getOrdersPerWindow(uint256 window) external view returns(LedgerTypes.OrderInfo[] memory) {
        uint256 len = orders.count(window);
        LedgerTypes.OrderInfo[] memory windowOrders = new LedgerTypes.OrderInfo[](len);

        for (uint256 i = 0; i < len; i++) {
            (uint256 key, LedgerTypes.OrderInfo memory value) = orders.getAt(window, i);
            assert(key != 0);
            windowOrders[i] = value;
        }

        return windowOrders;
    }

}