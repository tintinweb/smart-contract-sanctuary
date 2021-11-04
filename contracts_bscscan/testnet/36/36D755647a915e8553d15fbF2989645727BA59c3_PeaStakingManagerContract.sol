// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PeaMinterContract is Ownable {

    mapping(address => bool) private _minters;

    function addMinter(address minter) public onlyOwner {
        _minters[minter] = true;
    }
    
    function removeMinter(address minter) public onlyOwner {
        delete _minters[minter];
    }
    
    function isMinter(address minter) public view returns(bool){
        return _minters[minter];
    }
    
    /**
     * @dev Throws if called by any account other than the setup minter.
     */
    modifier onlyMinter() {
        require(_minters[_msgSender()], "PeaMinterContract: caller is not the minter");
        _;
    }    
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library PeaStakingLibrary {
    enum StakingStatus {
        AVAILABLE,
        PENDING,
        CONCLUDED,
        CLOSED
    }

    struct PeaStakingPool {
        uint256 poolId;
        uint256 initPoolAmount;
        uint256 currentPoolAmount;
        uint256 currentStakingAmount;
        address poolTokenContract;

        address stakingTokenContract;
        uint256 stakingDecimal;
        uint256 feePercent;
        uint256 currentFeeAmount;
        uint256 vendorCommissionFeePercent;

        uint256 beginDate;
        uint256 endDate;

        address owner;
        
        StakingStatus status;
    }

    struct PeaVendor {
        uint256 poolId;
        uint256 totalOpenContracts;
        uint256 totalCommissionAmount;
        uint256 currentCommissionAmount;
    }

    struct PeaStakingPredefineContract {
        uint256 predefineContractId;
        uint256 poolId;
        uint256 durationInSeconds;
        uint256 tokenPerSeconds;
        uint256 apr;    
        uint256 minAmount;
        uint256 maxAmount;

        bool earlyTermination;

        StakingStatus status;
    }

    struct PeaStakingImplementContract {
        uint256 contractId;
        uint256 poolId;
        uint256 beginDate;
        uint256 recentPaidDate;        
        uint256 durationInSeconds;

        uint256 tokenPerSeconds;
        uint256 apr;
        uint256 stakingAmount;

        bool earlyTermination;
        address owner;
        address vendor;

        StakingStatus status;
    }

    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = SafeMath.add(a,m);
        uint256 d = SafeMath.sub(c,1);
        return SafeMath.mul(SafeMath.div(d,m),m);
    }   

    /**
     * Percent have to mul with 100
     * Example: 1% = 100, 0.1% = 10, 0.01% = 1
     */    
    function calculatePercent(uint256 _value, uint256 percent) internal pure returns (uint256)  {
        uint256 BASEPERCENT = 100;
        uint256 roundValue = ceil(_value, BASEPERCENT);
        uint256 mulRoundValue = SafeMath.mul(roundValue, BASEPERCENT);
        uint256 result = SafeMath.div(SafeMath.mul(mulRoundValue, percent), 1000000);
        return result;
    }    
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import { PeaStakingLibrary } from './PeaStakingLibrary.sol';
import './PeaMinterContract.sol';

contract PeaStakingManagerContract is PeaMinterContract {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;    

    Counters.Counter private _currentPoolId;
    Counters.Counter private _currentPredefineContractId;
    Counters.Counter private _currentContractId;

    mapping(uint256 => PeaStakingLibrary.PeaStakingPool) private _pools;
    EnumerableSet.UintSet private _poolList;

    mapping(uint256 => PeaStakingLibrary.PeaStakingPredefineContract) private _predefineContracts;
    mapping(uint256 => EnumerableSet.UintSet) private _poolPredefineContracts;
    
    mapping(uint256 => PeaStakingLibrary.PeaStakingImplementContract) private _implementContracts;    
    mapping(address => EnumerableSet.UintSet) private _userContracts;

    mapping(address => mapping(uint256 => PeaStakingLibrary.PeaVendor)) private _vendors;
    mapping(address => EnumerableSet.UintSet) private _vendorPools;

    event OpenPool(uint256 poolId, address owner);
    event FillPool(uint256 poolId, uint256 amount);
    event WithdrawPool(uint256 poolId, uint256 amount);
    event ClosePool(uint256 poolId);
    event StopPool(uint256 poolId);
    event StartPool(uint256 poolId);
    event EditPool(uint256 poolId);

    event AddPredefineContracts(uint256 poolId, uint256[] predefineContractIds);
    event StopPredefineContract(uint256 predefineContractId);
    event StartPredefineContract(uint256 predefineContractId);
    event EditPredefineContract(uint256 predefineContractId);    

    event OpenStakingContract(uint256 poolId, uint256 contractId, address owner);
    event HarvestProfit(uint256 poolId, uint256 contractId);
    event ConcludeContract(uint256 poolId, uint256 contractId);
    event CloseContract(uint256 poolId, uint256 contractId);

    event ClaimCommission(address vendor, uint256 poolId, uint256 commission);

    constructor() {
        addMinter(_msgSender());
    }

     /**
     * Open staking Pool
     * Only allowed minter can open a new pool
     * Emit event OpenPool
     */  
    function openPool(
        uint256 initPoolAmount,
        address poolTokenContract,
        address stakingTokenContract,
        uint256 stakingDecimal,
        uint256 feePercent,
        uint256 vendorCommissionFeePercent,

        uint256 beginDate,
        uint256 endDate,
        PeaStakingLibrary.PeaStakingPredefineContract[] memory predefineContracts
    ) public onlyMinter returns (uint256) {

        address owner = _msgSender();
        
        _currentPoolId.increment();
        uint256 newId = _currentPoolId.current();

        _pools[newId] = PeaStakingLibrary.PeaStakingPool({
            poolId: newId,
            initPoolAmount: initPoolAmount,
            currentPoolAmount: initPoolAmount,
            currentStakingAmount: 0,
            poolTokenContract: poolTokenContract,
            stakingTokenContract: stakingTokenContract,
            stakingDecimal: stakingDecimal,
            feePercent: feePercent,
            currentFeeAmount: 0,
            vendorCommissionFeePercent: vendorCommissionFeePercent,

            beginDate: beginDate,
            endDate: endDate,
            owner: owner,
            status: PeaStakingLibrary.StakingStatus.AVAILABLE
        });

        _poolList.add(newId);

        _addPredefineContracts(newId, predefineContracts);

        bool transferResult = _transferToContract(poolTokenContract, initPoolAmount, owner);
        require(transferResult, "PeaStakingManagerContract: transfer tokens to pool unsuccessfully");

        emit OpenPool(newId, owner);
        
        return newId;
    }

     /**
     * Fill more tokens to pool
     * Emit event FillPool
     */ 
    function fillPool(uint256 poolId, uint256 amount) public {
        require(_pools[poolId].owner == _msgSender(), "PeaStakingManagerContract: Caller is not the owner");        
        _pools[poolId].initPoolAmount += amount;
        _pools[poolId].currentPoolAmount += amount;

        bool transferResult = _transferToContract(_pools[poolId].poolTokenContract, amount, _pools[poolId].owner);
        require(transferResult, "PeaStakingManagerContract: transfer tokens to pool unsuccessfully");

        emit FillPool(poolId, amount);
    }
     /**
     * Withdraw tokens from pool
     * Emit event WithdrawPool
     */            
    function withdrawPool(uint256 poolId, uint256 amount) public {
        require(_pools[poolId].owner == _msgSender(), "PeaStakingManagerContract: Caller is not the owner");        
        _pools[poolId].initPoolAmount -= amount;
        _pools[poolId].currentPoolAmount -= amount;

        bool transferResult = _transferToReceiver(_pools[poolId].poolTokenContract, amount, _pools[poolId].owner);
        require(transferResult, "PeaStakingManagerContract: withdraw tokens from pool unsuccessfully");

        emit WithdrawPool(poolId, amount);
    }

     /**
     * Close an ongoing pool
     * Emit event ClosePool
     */  
    function closePool(uint256 poolId) public {
        require(_pools[poolId].owner == _msgSender(), "PeaStakingManagerContract: Caller is not the owner");        
        require(_pools[poolId].status == PeaStakingLibrary.StakingStatus.AVAILABLE, "PeaStakingManagerContract: This pool is not available");
        
        uint256 totalAmount = _pools[poolId].currentPoolAmount + _pools[poolId].currentFeeAmount;

        bool transferResult = _transferToReceiver(_pools[poolId].poolTokenContract, totalAmount, _pools[poolId].owner);
        require(transferResult, "PeaStakingManagerContract: withdraw tokens from pool unsuccessfully");
        _pools[poolId].status = PeaStakingLibrary.StakingStatus.CLOSED;

        emit ClosePool(poolId);
    }

     /**
     * Temporarily stop a pool
     * Emit event StopPool
     */  
    function stopPool(uint256 poolId) public {
        require(_pools[poolId].owner == _msgSender(), "PeaStakingManagerContract: Caller is not the owner");        
        require(_pools[poolId].status == PeaStakingLibrary.StakingStatus.AVAILABLE, "PeaStakingManagerContract: This pool is not available");

        _pools[poolId].status = PeaStakingLibrary.StakingStatus.PENDING;
        emit StopPool(poolId);
    }

     /**
     * start an ongoing pool
     * Emit event StartPool
     */ 
    function startPool(uint256 poolId) public {
        require(_pools[poolId].owner == _msgSender(), "PeaStakingManagerContract: Caller is not the owner");        
        require(_pools[poolId].status == PeaStakingLibrary.StakingStatus.PENDING, "PeaStakingManagerContract: This pool is not pending");

        _pools[poolId].status = PeaStakingLibrary.StakingStatus.AVAILABLE;
        emit StartPool(poolId);
    }

     /**
     * Adjust Pool information
     * Emit event EditPool
     */ 
    function editPool(uint256 poolId, uint256 beginDate, uint256 endDate, uint256 feePercent, uint256 vendorCommissionFeePercent) public {
        require(_pools[poolId].owner == _msgSender(), "PeaStakingManagerContract: Caller is not the owner");        
        require(_pools[poolId].status == PeaStakingLibrary.StakingStatus.AVAILABLE, "PeaStakingManagerContract: This pool is not available");

        _pools[poolId].beginDate = beginDate;
        _pools[poolId].endDate = endDate;
        _pools[poolId].feePercent = feePercent;
        _pools[poolId].vendorCommissionFeePercent = vendorCommissionFeePercent;                
        emit EditPool(poolId);
    }

     /**
     * Get all Pools
     */ 
    function getPools() public view returns (PeaStakingLibrary.PeaStakingPool[] memory){
        uint256 _total = _poolList.length();
        PeaStakingLibrary.PeaStakingPool[] memory _result = new PeaStakingLibrary.PeaStakingPool[](_total);
        for (uint256 i = 0; i < _total; i++) {
            uint256 id = _poolList.at(i);
            _result[i] = _pools[id];
        }
        return _result;
    }

    /**
     * Get current pool Id
     */ 
    function getCurrentPoolId() public view returns (uint256){              
        return _currentPoolId.current();
    }    

     /**
     * Get Pool By Id
     */ 
    function getPool(uint256 poolId) public view returns (PeaStakingLibrary.PeaStakingPool memory, PeaStakingLibrary.PeaStakingPredefineContract[] memory){
        uint256 _total = _poolPredefineContracts[poolId].length();
        PeaStakingLibrary.PeaStakingPredefineContract[] memory _result = new PeaStakingLibrary.PeaStakingPredefineContract[](_total);
        for (uint256 i = 0; i < _total; i++) {
            uint256 id = _poolPredefineContracts[poolId].at(i);
            _result[i] = _predefineContracts[id];
        }                
        return (_pools[poolId], _result);
    }    

     /**
     * Add predefine contract to a selected pool
     */ 
    function addPredefineContracts(uint256 poolId, PeaStakingLibrary.PeaStakingPredefineContract[] memory predefineContracts) public returns (uint256[] memory) {

        require(_pools[poolId].owner == _msgSender(), "PeaStakingManagerContract: Caller is not the owner");        
        require(_pools[poolId].status == PeaStakingLibrary.StakingStatus.AVAILABLE, "PeaStakingManagerContract: This pool is not available");

        uint256[] memory _results = _addPredefineContracts(poolId, predefineContracts);

        emit AddPredefineContracts(poolId, _results);

        return _results;
    }

     /**
     * Temporarily stop a predefine contract
     */ 
    function stopPredefineContract(uint256 poolId, uint256 predefineContractId) public {

        require(_pools[poolId].owner == _msgSender(), "PeaStakingManagerContract: Caller is not the owner");        
        require(_pools[poolId].status == PeaStakingLibrary.StakingStatus.AVAILABLE, "PeaStakingManagerContract: This pool is not available");

        _predefineContracts[predefineContractId].status = PeaStakingLibrary.StakingStatus.PENDING;

        emit StopPredefineContract(predefineContractId);
    }

     /**
     * Start a predefine contract
     */ 
    function startPredefineContract(uint256 poolId, uint256 predefineContractId) public {

        require(_pools[poolId].owner == _msgSender(), "PeaStakingManagerContract: Caller is not the owner");        
        require(_pools[poolId].status == PeaStakingLibrary.StakingStatus.PENDING, "PeaStakingManagerContract: This pool is not pending");

        _predefineContracts[predefineContractId].status = PeaStakingLibrary.StakingStatus.AVAILABLE;

        emit StartPredefineContract(predefineContractId);
    }

     /**
     * Adjust a predefine contract information
     */ 
    function editPredefineContract(uint256 poolId, uint256 predefineContractId, uint256 durationInSeconds, uint256 tokenPerSeconds, uint256 minAmount, uint256 maxAmount, bool earlyTermination, uint256 apr) public {

        require(_pools[poolId].owner == _msgSender(), "PeaStakingManagerContract: Caller is not the owner");        
        require(_pools[poolId].status == PeaStakingLibrary.StakingStatus.AVAILABLE, "PeaStakingManagerContract: This pool is not available");

        _predefineContracts[predefineContractId].durationInSeconds = durationInSeconds;
        _predefineContracts[predefineContractId].tokenPerSeconds = tokenPerSeconds;
        _predefineContracts[predefineContractId].apr = apr;
        _predefineContracts[predefineContractId].minAmount = minAmount;
        _predefineContracts[predefineContractId].maxAmount = maxAmount;
        _predefineContracts[predefineContractId].earlyTermination = earlyTermination;

        emit EditPredefineContract(predefineContractId);
    }

     /**
     * Get Predefine Contract by Id
     */ 
    function getPredefineContract(uint256 predefineContractId) public view returns(PeaStakingLibrary.PeaStakingPredefineContract memory predefineContract){
        return _predefineContracts[predefineContractId];
    }

     /**
     * Open staking contract from a user & pool
     * The contract could be limited life time or unlimited.
     */ 
    function openStakingContract(uint256 predefineContractId, uint256 stakingAmount, address vendor) public {
        address owner = _msgSender();
        uint256 poolId = _predefineContracts[predefineContractId].poolId;

        require( _pools[poolId].status == PeaStakingLibrary.StakingStatus.AVAILABLE, "PeaStakingManagerContract: This pool is not available");
        require( _pools[poolId].beginDate == 0 || block.timestamp >= _pools[poolId].beginDate, "PeaStakingManagerContract: This pool is opened yet");
        require( _pools[poolId].endDate == 0 || block.timestamp <= _pools[poolId].endDate, "PeaStakingManagerContract: This pool is closed");
        require(_predefineContracts[predefineContractId].status == PeaStakingLibrary.StakingStatus.AVAILABLE, "PeaStakingManagerContract: This predefine contract is not available");
        require(_predefineContracts[predefineContractId].minAmount == 0 || stakingAmount >= _predefineContracts[predefineContractId].minAmount, "PeaStakingManagerContract: Staking amount is too small");
        require(_predefineContracts[predefineContractId].maxAmount == 0 || stakingAmount <= _predefineContracts[predefineContractId].maxAmount, "PeaStakingManagerContract: Staking amount is too big");

        _currentContractId.increment();
        uint256 newId = _currentContractId.current();

        _implementContracts[newId] = PeaStakingLibrary.PeaStakingImplementContract({
            contractId: newId,
            poolId: poolId,
            beginDate: block.timestamp,
            recentPaidDate: block.timestamp,
            durationInSeconds: _predefineContracts[predefineContractId].durationInSeconds,
            tokenPerSeconds: _predefineContracts[predefineContractId].tokenPerSeconds,
            apr: _predefineContracts[predefineContractId].apr,
            stakingAmount: stakingAmount,
            earlyTermination: _predefineContracts[predefineContractId].earlyTermination,
            owner: owner,
            vendor: vendor,
            status: PeaStakingLibrary.StakingStatus.AVAILABLE
        });

        _userContracts[owner].add(newId);

        bool transferResult = _transferToContract( _pools[poolId].stakingTokenContract, stakingAmount, owner);
        require(transferResult, "PeaStakingManagerContract: Transfer to contract unsuccessfully");   
        
        _pools[poolId].currentStakingAmount += stakingAmount; 

        //VENDOR
        if(vendor != address(0) && vendor != owner){
            if(_vendorPools[vendor].contains(poolId)){
                _vendors[vendor][poolId].totalOpenContracts += 1;
            }else{
                _vendors[vendor][poolId] = PeaStakingLibrary.PeaVendor({
                    poolId: poolId,
                    totalOpenContracts: 1,
                    totalCommissionAmount: 0,
                    currentCommissionAmount: 0
                });
                _vendorPools[vendor].add(poolId);
            }
        }

        emit OpenStakingContract(poolId, newId, owner);   
    }

     /**
     * Harvest profit of an unlimited contract
     */ 
    function harvestProfit(uint256 contractId) public {
        uint256 poolId = _implementContracts[contractId].poolId;

        require(_implementContracts[contractId].status == PeaStakingLibrary.StakingStatus.AVAILABLE, "PeaStakingManagerContract: This contract is not available");
        require(_implementContracts[contractId].durationInSeconds == 0, "PeaStakingManagerContract: This contract is a limited contract");
        require(_pools[poolId].status == PeaStakingLibrary.StakingStatus.AVAILABLE, "PeaStakingManagerContract: This pool is not available");

        uint256 timeGap = block.timestamp - _implementContracts[contractId].recentPaidDate;

        uint256 profit = timeGap * _implementContracts[contractId].tokenPerSeconds * SafeMath.div(_implementContracts[contractId].stakingAmount, _pools[poolId].stakingDecimal);
        uint256 fee = PeaStakingLibrary.calculatePercent(profit, _pools[poolId].feePercent);
        uint256 actualProfit = profit - fee;

        bool transferResult = _transferToReceiver(_pools[poolId].poolTokenContract, actualProfit, _implementContracts[contractId].owner);
        require(transferResult, "PeaStakingManagerContract: transfer tokens to owner unsuccessfully");

        _pools[poolId].currentPoolAmount -= profit;

        address vendor = _implementContracts[contractId].vendor;

        if(vendor != address(0) && vendor != _implementContracts[contractId].owner){
            uint256 vendorCommission = PeaStakingLibrary.calculatePercent(fee, _pools[poolId].vendorCommissionFeePercent);
            _vendors[vendor][poolId].totalCommissionAmount += vendorCommission;
            _vendors[vendor][poolId].currentCommissionAmount += vendorCommission;

            _pools[poolId].currentFeeAmount += (fee - vendorCommission);
        }else{
            _pools[poolId].currentFeeAmount += fee;
        }

        _implementContracts[contractId].recentPaidDate = block.timestamp;   

        emit HarvestProfit(poolId, contractId);     
    }

     /**
     * Conclude a limited contract
     */ 
    function concludeContract(uint256 contractId) public {
        uint256 poolId = _implementContracts[contractId].poolId;

        require(_implementContracts[contractId].status == PeaStakingLibrary.StakingStatus.AVAILABLE, "PeaStakingManagerContract: This contract is not available");
        require(_implementContracts[contractId].durationInSeconds > 0, "PeaStakingManagerContract: This contract is an unlimited contract");
        require(_pools[poolId].status == PeaStakingLibrary.StakingStatus.AVAILABLE, "PeaStakingManagerContract: This pool is not available");        
        require(block.timestamp >= _implementContracts[contractId].beginDate + _implementContracts[contractId].durationInSeconds, "PeaStakingManagerContract: This contract hasn't ended yet");

        uint256 profit = _implementContracts[contractId].durationInSeconds * _implementContracts[contractId].tokenPerSeconds * SafeMath.div(_implementContracts[contractId].stakingAmount, _pools[poolId].stakingDecimal);
        uint256 fee = PeaStakingLibrary.calculatePercent(profit, _pools[poolId].feePercent);
        uint256 actualProfit = profit - fee;

        bool transferResult = _transferToReceiver(_pools[poolId].poolTokenContract, actualProfit, _implementContracts[contractId].owner);
        require(transferResult, "PeaStakingManagerContract: transfer tokens to owner unsuccessfully");

        _pools[poolId].currentPoolAmount -= profit;

        address vendor = _implementContracts[contractId].vendor;

        if(vendor != address(0) && vendor != _implementContracts[contractId].owner){
            uint256 vendorCommission = PeaStakingLibrary.calculatePercent(fee, _pools[poolId].vendorCommissionFeePercent);
            _vendors[vendor][poolId].totalCommissionAmount += vendorCommission;
            _vendors[vendor][poolId].currentCommissionAmount += vendorCommission;

            _pools[poolId].currentFeeAmount += (fee - vendorCommission);
        }else{
            _pools[poolId].currentFeeAmount += fee;
        }              

        _implementContracts[contractId].recentPaidDate = block.timestamp;

        bool transferStakingTokenResult = _transferToReceiver(_pools[poolId].stakingTokenContract, _implementContracts[contractId].stakingAmount, _implementContracts[contractId].owner);
        require(transferStakingTokenResult, "PeaStakingManagerContract:  transfer staking tokens to owner unsuccessfully");
        _pools[poolId].currentStakingAmount -= _implementContracts[contractId].stakingAmount;

        _implementContracts[contractId].status = PeaStakingLibrary.StakingStatus.CONCLUDED;

        emit ConcludeContract(poolId, contractId);             
    }
       
     /**
     * Terminate contract without getting any profit
     */        
    function closeContract(uint256 contractId) public {
        uint256 poolId = _implementContracts[contractId].poolId;

        require(_implementContracts[contractId].owner == _msgSender(), "PeaStakingManagerContract: Caller is not the owner");        
        require(_implementContracts[contractId].status == PeaStakingLibrary.StakingStatus.AVAILABLE, "PeaStakingManagerContract: This contract is not available");

        bool transferStakingTokenResult = _transferToReceiver(_pools[poolId].stakingTokenContract, _implementContracts[contractId].stakingAmount, _implementContracts[contractId].owner);
        require(transferStakingTokenResult, "PeaStakingManagerContract:  transfer staking tokens to owner unsuccessfully");

        _pools[poolId].currentStakingAmount -= _implementContracts[contractId].stakingAmount;

        _implementContracts[contractId].status = PeaStakingLibrary.StakingStatus.CLOSED;

        emit CloseContract(poolId, contractId);        
    }

    /**
     * Get User Staking Contracts
     */ 
    function getUserStakingContracts(address owner) public view returns (PeaStakingLibrary.PeaStakingImplementContract[] memory){
        uint256 _total = _userContracts[owner].length();
        PeaStakingLibrary.PeaStakingImplementContract[] memory _result = new PeaStakingLibrary.PeaStakingImplementContract[](_total);
        for (uint256 i = 0; i < _total; i++) {
            uint256 id = _userContracts[owner].at(i);
            _result[i] = _implementContracts[id];
        }                
        return _result;
    }

    /**
     * Get User Staking ContractIds
     */ 
    function getUserStakingContractIds(address owner) public view returns (uint256[] memory){
        uint256 _total = _userContracts[owner].length();
        uint256[] memory _result = new uint256[](_total);
        for (uint256 i = 0; i < _total; i++) {
            uint256 id = _userContracts[owner].at(i);
            _result[i] = id;
        }                
        return _result;
    }

    /**
     * Get Staking Contract by Id
    */  
    function getStakingContract(uint256 contractId) public view returns (PeaStakingLibrary.PeaStakingImplementContract memory){
        return _implementContracts[contractId];
    }       

    /**
    * Get vendor commissions
    */
    function getVendorCommissions(address vendor) public view returns(PeaStakingLibrary.PeaVendor[] memory comissions){
        uint256 _total = _vendorPools[vendor].length();
        PeaStakingLibrary.PeaVendor[] memory _result = new PeaStakingLibrary.PeaVendor[](_total);
        for (uint256 i = 0; i < _total; i++) {
            uint256 id = _vendorPools[vendor].at(i);
            _result[i] = _vendors[vendor][id];
        }                
        return _result;
    }

    /**
    * Claim vendor commissions
    */
    function claimVendorCommission(uint256 poolId) public {
        address vendor = _msgSender();
        
        uint256 commission = _vendors[vendor][poolId].currentCommissionAmount;

        require(commission > 0, "PeaStakingManagerContract: This vendor does not have commission");

        bool transferResult = _transferToReceiver( _pools[poolId].poolTokenContract, commission, vendor);
        require(transferResult, "PeaStakingManagerContract: transfer commission tokens to vendor unsuccessfully");

        _vendors[vendor][poolId].currentCommissionAmount = 0;

        emit ClaimCommission(vendor, poolId, commission);
    }

    function _addPredefineContracts(uint256 poolId, PeaStakingLibrary.PeaStakingPredefineContract[] memory predefineContracts) private returns (uint256[] memory) {
        uint256 total = predefineContracts.length;

        uint256[] memory _results = new uint256[](total);

        for (uint256 i = 0; i < total; i++) {
            _currentPredefineContractId.increment();
            uint256 newId = _currentPredefineContractId.current();
            
            _predefineContracts[newId] = PeaStakingLibrary.PeaStakingPredefineContract({
                predefineContractId: newId,
                poolId: poolId,
                durationInSeconds: predefineContracts[i].durationInSeconds,
                tokenPerSeconds: predefineContracts[i].tokenPerSeconds,
                apr: predefineContracts[i].apr,
                minAmount: predefineContracts[i].minAmount,
                maxAmount: predefineContracts[i].maxAmount,
                earlyTermination: predefineContracts[i].earlyTermination,
                status: PeaStakingLibrary.StakingStatus.AVAILABLE
            });
            
            _poolPredefineContracts[poolId].add(newId);
            _results[i] = newId;
        } 

        return _results;
    }

    function _transferToContract(address currency, uint256 amount, address owner) private returns (bool) {
        if(amount == 0) return false;
        
        IERC20 _contract = IERC20(currency);
        uint256 totalAllowance = _contract.allowance(owner, address(this));
        if(totalAllowance < amount) {
            return false;
        }
        
        return _contract.transferFrom(owner, address(this), amount);
    }
    
    function _transferToReceiver(address currency, uint256 amount, address receiver) private returns (bool) {
        if(amount == 0) return false;
        
        IERC20 _contract = IERC20(currency);
        
        return _contract.transfer(receiver, amount);
    }    
}