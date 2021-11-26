// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/Context.sol";
import "../lib/EnumerableSet.sol";
import "../lib/SafeMath.sol";

contract RETHSubscription is Context {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    // solhint-disable-next-line var-name-mixedcase, this is structure on javascript side
    bytes32 private immutable _SUBSCRIPTION_TYPEHASH = keccak256("Subscription(address parent,address child,uint256 totalLimit,uint256 cycle,uint256 limitPerCycle,address startTime,address endTime)");
    uint256 private immutable _ONE_DAY_IN_SECONDS = 86400;
    uint256 private immutable _ONE_WEEK_IN_SECONDS = 604800;
    /**
        parent allows child totalLimit, limit per cycle, from startTime, to endTime
        After endTime, child will not be able to use parent's reth balance
    */
    struct Subscription {
        address parent;
        address child;
        uint256 totalLimit;
        uint256 weeklyLimit;
        uint256 dailyLimit;
        uint256 transactionLimit;
        uint256 startTime;
        uint256 endTime;
    }

    struct SubscriptionStatus {
        bool isDisabled;
        uint256 totalSpent;
        uint256 weeklySpent;
        uint256 dailySpent;
        uint256 lastSpentTime;
    }

    struct SubscriptionInfo {
        Subscription subscription;
        SubscriptionStatus status;
    }

    // Enumerable keys for subscription
    EnumerableSet.Bytes32Set private _allSubscriptions;

    // Storage for hash(parent+child) => Subscription
    mapping (bytes32 => Subscription) private _subscriptions;

    mapping (bytes32 => SubscriptionStatus) private _subscriptionStatus;

    // Enumerable keys for parent address => [child address]
    mapping (address => EnumerableSet.AddressSet) private _childs;

    // Enumerable keys for child address => [parent address]
    mapping (address => EnumerableSet.AddressSet) private _parents;

    constructor() {

    }

    /**
       @dev Adds or remove subscription
    */
    function addSubscription(Subscription memory subscription_) external{
        require(!_allSubscriptions.contains(hashKey(_msgSender(), subscription_.child)), "RETHSubscription: Already has subscription");
        updateSubscription(subscription_);
    }

    function removeSubscription(address child_) public{
        bytes32 key = hashKey(_msgSender(), child_);
        require(_allSubscriptions.contains(key), "RETHSubscription: No subscription");

        // Remove all
        address parent = _msgSender();
        _allSubscriptions.remove(key);
        _childs[parent].remove(child_);
        _parents[child_].remove(parent);

        delete _subscriptionStatus[key];
        delete _subscriptions[key];
    }

    function updateSubscription(Subscription memory subscription_) public {
        address parent = _msgSender();
        address child = subscription_.child;
        require(child != address(0), "RETHSubscription: Child should not be zero address");
        require(parent != child, "RETHSubscription: Can't allow the same address");
        bytes32 key = hashKey(parent, child);

        uint256 maxInt = ~uint256(0);

        subscription_.parent = parent;

        // Set default values;
        if (subscription_.startTime == 0) {
            subscription_.startTime = block.timestamp;
        }

        if (subscription_.endTime == 0) {
            subscription_.endTime = maxInt;
        }

        if (subscription_.transactionLimit == 0) {
            subscription_.transactionLimit = maxInt;
        }

        if (subscription_.totalLimit == 0) {
            subscription_.totalLimit = maxInt;
        }

        if (subscription_.weeklyLimit == 0) {
            subscription_.weeklyLimit = maxInt;
        }

        if (subscription_.dailyLimit == 0) {
            subscription_.dailyLimit = maxInt;
        }

        // Assign subscription
        _subscriptions[key] = subscription_;

        // Add address
        _allSubscriptions.add(key);
        _childs[parent].add(child);
        _parents[child].add(parent);

        // Clear data for fresh start
        delete _subscriptionStatus[key];
    }

    function hashKey(address parent, address child) public pure returns (bytes32) {
        return keccak256(abi.encode(parent, child));
    }

    /**
       @dev check whether child can spend parent's amount now
    */
    function isSpendable(address child_, address parent_, uint256 amount_) public view returns (bool, string memory){
        bytes32 key = hashKey(parent_, child_);
        if (!_allSubscriptions.contains(key)) {
            return (false, "RETHSubscription: No subscription");
        }

        uint256 now = block.timestamp;
        Subscription memory subscription = _subscriptions[key];
        SubscriptionStatus memory status = _subscriptionStatus[key];

        if (status.isDisabled) {
            return (false, "RETHSubscription: Subscription is disabled");
        }

        if (subscription.endTime < now) {
            return (false, "RETHSubscription: Subscription expired");
        }

        if (subscription.startTime > now) {
            return (false, "RETHSubscription: Subscription did not start");
        }

        if (status.totalSpent.add(amount_) > subscription.totalLimit) {
            return (false, "RETHSubscription: Exceeds total spend limit");
        }

        if (amount_ > subscription.weeklyLimit) {
            return (false, "RETHSubscription: Exceeds weekly limit on a single transaction");
        }

        if (amount_ > subscription.dailyLimit) {
            return (false, "RETHSubscription: Exceeds daily limit on a single transaction");
        }

        if (amount_ > subscription.transactionLimit) {
            return (false, "RETHSubscription: Exceeds per transaction limit");
        }

        // Check weekly spent
        if (isWithInSamePeriod(subscription.startTime, _ONE_WEEK_IN_SECONDS, status.lastSpentTime, block.timestamp)){
            if (status.weeklySpent.add(amount_) > subscription.weeklyLimit) {
                return (false, "RETHSubscription: Exceeds weekly spend");
            }
            if (isWithInSamePeriod(subscription.startTime, _ONE_DAY_IN_SECONDS, status.lastSpentTime, block.timestamp)) {
                if (status.dailySpent.add(amount_) > subscription.dailyLimit) {
                    return (false, "RETHSubscription: Exceeds daily spend");
                }
            }
        }

        return (true, "");
    }

    /**
       @dev spend parent's asset
    */
    function spend(address parent_, uint256 amount) public returns (bool){
        address child = _msgSender();

        (bool allowed, string memory reason) = isSpendable(child, parent_, amount);

        // Reject if not spendable
        require(allowed, reason);

        bytes32 key = hashKey(parent_, child);
        require(_allSubscriptions.contains(key), "RETHSubscription: No subscription");

        SubscriptionStatus storage status = _subscriptionStatus[key];
        uint256 startTime = _subscriptions[key].startTime;
        uint256 lastSpent = status.lastSpentTime;
        uint256 now = block.timestamp;

        status.totalSpent += amount;
        if (isWithInSamePeriod(startTime, _ONE_WEEK_IN_SECONDS, lastSpent, now)) {
            status.weeklySpent += amount;
            if (isWithInSamePeriod(startTime, _ONE_DAY_IN_SECONDS, lastSpent, now)) {
                status.dailySpent += amount;
            } else {
                status.dailySpent = amount;
            }
        } else {
            status.weeklySpent = amount;
            status.dailySpent = amount;
        }
        // Assign last spent time
        status.lastSpentTime = block.timestamp;
        return true;
    }

    function isSubscriptionEnabled(address child_, address parent_) public view returns (bool){
        return !_subscriptionStatus[hashKey(parent_, child_)].isDisabled;
    }

    function disableSubscription(address child_) external {
        bytes32 key = hashKey(_msgSender(), child_);
        require(!_subscriptionStatus[key].isDisabled, "RETHSubscription: Already disabled");
        _subscriptionStatus[key].isDisabled = true;
    }

    function enableSubscription(address child_) external {
        bytes32 key = hashKey(_msgSender(), child_);
        require(_subscriptionStatus[key].isDisabled, "RETHSubscription: Already enabled");
        _subscriptionStatus[key].isDisabled = false;
    }

    /**
       @dev Check if a_ and _b are in the same time frame based on start_ and period_
    */
    function isWithInSamePeriod(uint256 start_, uint256 period_, uint256 a_, uint256 b_) public pure returns (bool) {
        uint abDiff = b_ - a_;
        // if difference between two timeframe is greater than period_, no need to check.
        if (abDiff > period_) {
            return false;
        }

        // Calculate nearest from start_
        uint aOffset = a_.sub(start_).mod(period_);

        // If within same timeframe, return true
        return (abDiff + aOffset) <= period_;
    }


    /**
       @dev return subscription information for child & parent
    */
    function subscriptionInfo(address child_, address parent_) public view returns (SubscriptionInfo memory) {
        bytes32 key = hashKey(parent_, child_);
        SubscriptionInfo memory info;
        info.subscription = _subscriptions[key];
        info.status = _subscriptionStatus[key];
        return info;
    }

    /**
       @dev return child addresses
    */
    function childAddresses(address parent_) public view returns (address[] memory) {
        uint256 count =  _childs[parent_].length();
        address[] memory result = new address[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = _childs[parent_].at(i);
        }
        return result;
    }

    /**
       @dev return parent addresses
    */
    function parentAddresses(address child_) public view returns (address[] memory) {
        uint256 count =  _parents[child_].length();
        address[] memory result = new address[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = _parents[child_].at(i);
        }
        return result;
    }

    /**
       @dev Get subscriptions for user
    */
    function subscriptions(address user_) public view returns (SubscriptionInfo[] memory) {
        uint256 count =  _childs[user_].length();
        uint256 count1 =  _parents[user_].length();
        SubscriptionInfo[] memory result = new SubscriptionInfo[](count + count1);
        for (uint i = 0; i < count; i++) {
            address child_ = _childs[user_].at(i);
            bytes32 key = hashKey(user_, child_);
            result[i].subscription = _subscriptions[key];
            result[i].status = _subscriptionStatus[key];
        }

        for (uint i = 0; i < count1; i++) {
            address parent_ = _parents[user_].at(i);
            bytes32 key = hashKey(parent_, user_);
            result[i + count].subscription = _subscriptions[key];
            result[i + count].status = _subscriptionStatus[key];
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}