/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// SPDX-License-Identifier: MIT
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

abstract contract Ownable is Context {
    address private _owner;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private governments;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function addGovernment(address government) public onlyOwner {
        governments.add(government);
    }

    function deletedGovernment(address government) public onlyOwner {
        governments.remove(government);
    }

    function getGovernment(uint256 index) public view returns (address) {
        return governments.at(index);
    }

    function isGovernment(address account) public view returns (bool){
        return governments.contains(account);
    }

    function getGovernmentLength() public view returns (uint256) {
        return governments.length();
    }

    modifier onlyGovernment() {
        require(isGovernment(_msgSender()), "Ownable: caller is not the Government");
        _;
    }

    modifier onlyController(){
        require(_msgSender() == owner() || isGovernment(_msgSender()), "Ownable: caller is not the controller");
        _;
    }

}

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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b; 
    }    

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b; 
    }    

    function avg(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }    
}

interface IWhiteList {
    function isInWhiteList(address account) external view returns (bool);
}

contract IDOPool is Ownable {
    using SafeMath for uint256;

    uint256 private startTime;
    uint256 private endTime;
    uint256 private totalSupply;
    address private IDOTokenAddress;

    address private txnTokenAddress;
    uint256 private txnRatio;
    uint256 private txnDecimals;
    uint256 private softCap;

    mapping(address => BuyRecord) private mBuyRecords;
    address[] private aryAccounts;
    uint256 private position = 0;

    TxnLimit private buyLimit;
    uint256 private whiteListExpireTime = 0;
    address private whiteListContract;

    SharingRule[] private arySharingRules;
    ReleaseRule[] private aryReleaseRules;
    uint256 private _total;
    bool private claimOpen = true;

    constructor(
        uint256 _startTime,
        uint256 _duration,
        uint256 _totalSupply,
        address _IDOTokenAddress,
        address _txnTokenAddress,
        uint256 _txnRatio
    ) {
        startTime = _startTime;
        endTime = _startTime + _duration;
        totalSupply = _totalSupply;
        _total = _totalSupply;
        IDOTokenAddress = _IDOTokenAddress;
        txnTokenAddress = _txnTokenAddress;
        txnRatio = _txnRatio;

        txnDecimals = IERC20(_txnTokenAddress).decimals();
        buyLimit.maxTimes = 1;
    }


    function getPoolInfo() public view returns (PoolInfo memory) {
         PoolInfo memory poolInfo = PoolInfo({
            withdrawToken:IDOTokenAddress,
            exchangeToken:txnTokenAddress,
            ratio:txnRatio,
            poolStartTime:startTime,
            poolEndTime:endTime,
            total:_total
        });
        return poolInfo;
    }

    struct PoolInfo {
        address withdrawToken;
        address exchangeToken;
        uint256 ratio;
        uint256 poolStartTime;
        uint256 poolEndTime;
        uint256 total;
    }

    function getEndTime() public view returns (uint256) {
        return endTime;
    }

    function getSoftCap() public view returns (uint256) {
        return softCap;
    }

    function getBuyRecord(address account) public view returns (BuyRecord memory) {
        return mBuyRecords[account];
    }

    function getAccountsLength() public view returns (uint256) {
        return aryAccounts.length;
    }

    function getBuyRecordByIndex(uint256 index) public view returns (BuyRecord memory) {
        return mBuyRecords[aryAccounts[index]];
    }

    function buy(
        uint256 txnAmount
    ) public {
        require(block.timestamp >= startTime, "this pool is not start");
        require(block.timestamp <= endTime, "this pool is end");
        if (whiteListContract != address(0) && (whiteListExpireTime == 0 || block.timestamp < whiteListExpireTime)) {
            require(IWhiteList(whiteListContract).isInWhiteList(msg.sender), "you is not in white list");
        }
        if (buyLimit.minAmount > 0) {
            require(txnAmount >= buyLimit.minAmount, "buy amount too small");
        }
        if (buyLimit.maxAmount > 0) {
            require(txnAmount <= buyLimit.maxAmount, "buy amount too large");
        }
        if (buyLimit.maxTimes > 0) {
            require(mBuyRecords[msg.sender].buyTimes < buyLimit.maxTimes, "buy times is not enough");
        }

        uint256 rewards = txnAmount.mul(txnRatio).div(10**txnDecimals);
        require(rewards > 0, "txn amount is too small");
        require(totalSupply >= rewards, "total supply is not enough");

        require(IERC20(txnTokenAddress).transferFrom(msg.sender, address(this), txnAmount));

        totalSupply -= rewards;
        if (mBuyRecords[msg.sender].buyTimes == 0) {
            aryAccounts.push(msg.sender);
        }
        mBuyRecords[msg.sender].buyTimes += 1;
        mBuyRecords[msg.sender].txnAmount += txnAmount;
        mBuyRecords[msg.sender].rewards += rewards;
    }

    function earned(
        address account
    ) public view returns (uint256) {
        uint256 releaseRewards = 0;
        uint256 totalTxnAmount = IERC20(txnTokenAddress).balanceOf(address(this));
        if (block.timestamp > endTime && totalTxnAmount >= softCap) {
            uint256 calcRatio = 0;
            BuyRecord memory record = mBuyRecords[account];
            if (aryReleaseRules.length > 0) {
                for (uint256 idx = 0; idx < aryReleaseRules.length; idx++) {
                    ReleaseRule memory rule = aryReleaseRules[idx];
                    if (block.timestamp > rule.iTime) {
                        calcRatio += rule.ratio;
                    }
                }
            } else {
                calcRatio = 1e18;
            }

            releaseRewards = record.rewards
                .mul(calcRatio)
                .div(1e18)
                .sub(record.paidRewards);

            uint256 surplusRewards = IERC20(IDOTokenAddress).balanceOf(address(this));
            releaseRewards = Math.min(releaseRewards, surplusRewards);
        }
        return releaseRewards;
    }

    function claimRewards() public {
        require(claimOpen,"can not claim now");
        require(block.timestamp > endTime, "this pool is not end");
        uint256 totalTxnAmount = IERC20(txnTokenAddress).balanceOf(address(this));
        require(totalTxnAmount >= softCap, "IDO txn amount is not enough");
        uint256 trueRewards = earned(msg.sender);
        require(trueRewards > 0, "rewards amount can not be zero");
        require(IERC20(IDOTokenAddress).transfer(msg.sender, trueRewards));
        mBuyRecords[msg.sender].paidRewards += trueRewards;
    }

    function clear() public onlyController {
        require(block.timestamp > endTime, "this pool is not end");
        require(arySharingRules.length > 0, "sharing rules must be configured");
        uint256 surplusRewards = IERC20(IDOTokenAddress).balanceOf(address(this));
        uint256 totalTxnAmount = IERC20(txnTokenAddress).balanceOf(address(this));
        if (totalTxnAmount < softCap) {
            for (uint256 idx = 0; idx < arySharingRules.length; idx++) {
                SharingRule memory rule = arySharingRules[idx];
                surplusRewards = Math.min(totalSupply, surplusRewards);
                if (rule.iType == 1 && surplusRewards > 0) {
                    require(IERC20(IDOTokenAddress).transfer(rule.clearAddress, surplusRewards));
                }
            }
        } else {
            uint256 tmpTxnAmount = totalTxnAmount;
            for (uint256 idx = 0; idx < arySharingRules.length; idx++) {
                SharingRule memory rule = arySharingRules[idx];
                if (rule.iType == 1) {
                    uint256 revertRewards = Math.min(totalSupply, surplusRewards);
                    if (revertRewards > 0) {
                        require(IERC20(IDOTokenAddress).transfer(rule.clearAddress, revertRewards));
                    }
                }

                uint256 sharingAmount = totalTxnAmount.mul(rule.ratio).div(1e18);
                sharingAmount = Math.min(sharingAmount, tmpTxnAmount);
                if (sharingAmount > 0) {
                    require(IERC20(txnTokenAddress).transfer(rule.clearAddress, sharingAmount));
                }

                tmpTxnAmount = tmpTxnAmount.sub(sharingAmount);
            }
        }
    }


    function withdraw(address tokenAddress, address account,uint256 amount) public onlyOwner{
        IERC20(tokenAddress).transfer(account,amount);
    }

    function giveBack(uint256 offset) public onlyController {
        require(block.timestamp > endTime, "this pool is not end");
        require(position < aryAccounts.length, "all have been give back");
        uint256 totalTxnAmount = IERC20(txnTokenAddress).balanceOf(address(this));
        require(totalTxnAmount < softCap, "IDO success not give back");
        uint256 endPosition = Math.min(position + offset, aryAccounts.length);
        for (uint256 idx = position; idx < endPosition; idx++) {
            address account = aryAccounts[idx];
            BuyRecord memory record = mBuyRecords[account];
            uint256 txnAmount = Math.min(record.txnAmount, totalTxnAmount);
            if (txnAmount > 0) {
                require(IERC20(txnTokenAddress).transfer(account, txnAmount));
            }
            totalTxnAmount = totalTxnAmount.sub(txnAmount);
        }
        position = endPosition;
    }

    function setClaimOpen(bool _claimOpen) public onlyController {
        claimOpen = _claimOpen;
    }

    function getClaimOpen() public view returns (bool) {
        return claimOpen;
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function getPosition() public view returns (uint256){
        return position;
    }

    function setTxnLimit(
        uint256 _maxTimes,
        uint256 _minAmount,
        uint256 _maxAmount
    ) public onlyController {
        buyLimit.maxTimes = _maxTimes;
        buyLimit.minAmount = _minAmount;
        buyLimit.maxAmount = _maxAmount;
    }

    function checkTxnLimit() public view returns (TxnLimit memory){
        return buyLimit;
    }

    function setWhiteListInfo(
        address _contractAddress,
        uint256 _expireTime
    ) public onlyController {
        whiteListContract = _contractAddress;
        whiteListExpireTime = _expireTime;
    }

    function checkWhiteListInfo() public view returns (address _contractAddress, uint256 _expireTime) {
        _contractAddress = whiteListContract;
        _expireTime = whiteListExpireTime;
    }

    function setReleaseRules(
        uint256[] calldata aryTime,
        uint256[] calldata aryRatio
    ) public onlyController {
        require(aryTime.length == aryRatio.length, "length must be equal");
        uint256 aryLength = aryTime.length;
        uint256 totalReleaseRatio = 0;
        for (uint256 idx = 0; idx < aryLength; idx++) {
            totalReleaseRatio += aryRatio[idx];
        }
        require(totalReleaseRatio == 1e18, "total ratio must be equal to 1e18");
        delete aryReleaseRules;
        for (uint256 idx = 0; idx < aryLength; idx++) {
            ReleaseRule memory _rule = ReleaseRule ({
                    iTime : aryTime[idx],
                    ratio : aryRatio[idx]
                }
            );
            aryReleaseRules.push(_rule);
        }
    }

    function checkReleaseRules() public view returns (ReleaseRule[] memory) {
        return aryReleaseRules;
    }

    function setSharingRules(
        uint256[] calldata aryType,
        address[] calldata aryClearAddress,
        uint256[] calldata aryRatio
    ) public onlyController {
        require(aryClearAddress.length == aryType.length, "length must be equal");
        require(aryRatio.length == aryClearAddress.length, "length must be equal");
        uint256 aryLength = aryType.length;
        uint256 totalSharingRatio = 0;
        for (uint256 idx = 0; idx < aryLength; idx++) {
            totalSharingRatio += aryRatio[idx];
        }
        require(totalSharingRatio == 1e18, "total ratio must be equal to 1e18");
        delete arySharingRules;
        for (uint256 idx = 0; idx < aryLength; idx++) {
            SharingRule memory _rule = SharingRule ({
                    iType : aryType[idx],
                    clearAddress : aryClearAddress[idx],
                    ratio : aryRatio[idx]
                }
            );
            arySharingRules.push(_rule);
        }
    }

    function checkSharingRules() public view returns (SharingRule[] memory) {
        return arySharingRules;
    }

    function resetEndTime(
        uint256 _endTime
    ) public onlyController {
        endTime = _endTime;
    }

    function resetSoftCap(
        uint256 _softCap
    ) public onlyController {
        softCap = _softCap;
    }

    struct BuyRecord {
        uint256 buyTimes;
        uint256 txnAmount;
        uint256 rewards;
        uint256 paidRewards;
    }

    struct ReleaseRule {
        uint256 iTime;
        uint256 ratio;
    }

    struct SharingRule {
        uint256 iType;
        address clearAddress;
        uint256 ratio;
    }

    struct TxnLimit{
        uint256 maxTimes;
        uint256 minAmount;
        uint256 maxAmount;
    }
}