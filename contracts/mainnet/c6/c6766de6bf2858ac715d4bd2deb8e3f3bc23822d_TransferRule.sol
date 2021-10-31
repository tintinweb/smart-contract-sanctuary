/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

// SPDX-License-Identifier: AGPL
// File: contracts/interfaces/IITR.sol


pragma solidity ^0.8.0;

interface IITR {
	function claim(address to) external;
}
// File: contracts/interfaces/ISRC20.sol


pragma solidity ^0.8.0;

interface ISRC20 {

	event RestrictionsAndRulesUpdated(address restrictions, address rules);

	function transferToken(address to, uint256 value, uint256 nonce, uint256 expirationTime,
		bytes32 msgHash, bytes calldata signature) external returns (bool);
	function transferTokenFrom(address from, address to, uint256 value, uint256 nonce,
		uint256 expirationTime, bytes32 hash, bytes calldata signature) external returns (bool);
	function getTransferNonce() external view returns (uint256);
	function getTransferNonce(address account) external view returns (uint256);
	function executeTransfer(address from, address to, uint256 value) external returns (bool);
	function updateRestrictionsAndRules(address restrictions, address rules) external returns (bool);

	// ERC20 part-like interface
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	function totalSupply() external view returns (uint256);
	function balanceOf(address who) external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 value) external returns (bool);
	function transfer(address to, uint256 value) external returns (bool);
	function transferFrom(address from, address to, uint256 value) external returns (bool);

	function increaseAllowance(address spender, uint256 value) external returns (bool);
	function decreaseAllowance(address spender, uint256 value) external returns (bool);
}
// File: contracts/interfaces/ITransferRules.sol


pragma solidity ^0.8.0;

interface ITransferRules {
	function setSRC(address src20) external returns (bool);
	
	function doTransfer(address from, address to, uint256 value) external returns (bool);
}


// File: contracts/interfaces/IChain.sol


pragma solidity ^0.8.0;

interface IChain {
	function doValidate(address from, address to, uint256 value) external returns (address, address, uint256, bool, string memory);
}

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: contracts/restrictions/ChainRuleBase.sol


pragma solidity ^0.8.0;



abstract contract ChainRuleBase is Ownable {
	address public _chainRuleAddr;
	
	function clearChain() public onlyOwner() {
		_setChain(address(0));
	}
	
	function setChain(address chainAddr) public onlyOwner() {
		_setChain(chainAddr);
	}
	
	//---------------------------------------------------------------------------------
	// internal  section
	//---------------------------------------------------------------------------------

	function _doValidate(
		address from, 
		address to, 
		uint256 value
	) 
		internal
		returns (
			address _from, 
			address _to, 
			uint256 _value,
			bool _success,
			string memory _msg
		) 
	{
		(_from, _to, _value, _success, _msg) = _validate(from, to, value);
		if (isChainExists() && _success) {
			(_from, _to, _value, _success, _msg) = IChain(_chainRuleAddr).doValidate(msg.sender, to, value);
		}
		
	}
	
	function isChainExists() internal view returns(bool) {
		return (_chainRuleAddr != address(0) ? true : false);
	}
	
	function _setChain(address chainAddr) internal {
		_chainRuleAddr = chainAddr;
	}
	
	function _validate(address from, address to, uint256 value) internal virtual returns (address, address, uint256, bool, string memory);

}
	
// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol



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
 *	 // Add the library methods
 *	 using EnumerableSet for EnumerableSet.AddressSet;
 *
 *	 // Declare a set state variable
 *	 EnumerableSet.AddressSet private mySet;
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

// File: contracts/restrictions/TransferRule.sol


pragma solidity ^0.8.0;








contract TransferRule is Ownable, ITransferRules, ChainRuleBase {
	using SafeMath for uint256;
	using EnumerableSet for EnumerableSet.AddressSet;
	
	address public _src20;
	address public _doTransferCaller;

	uint256 internal constant MULTIPLIER = 100000;
	
	address public _tradedToken;
	uint256 public _lockupDuration;
	uint256 public _lockupFraction;
	
	struct Item {
		uint256 untilTime;
		uint256 lockedAmount;
		
	}
	mapping(address => Item) restrictions;
	
	EnumerableSet.AddressSet _exchangeDepositAddresses;
	
	modifier onlyDoTransferCaller {
		require(msg.sender == address(_doTransferCaller));
		_;
	}
	
	//---------------------------------------------------------------------------------
	// public  section
	//---------------------------------------------------------------------------------
	/**
	 * @param tradedToken tradedToken
	 * @param lockupDuration duration in sec 
	 * @param lockupFraction fraction in percent to lock. multiplied by MULTIPLIER
	 */
	constructor(
		address tradedToken,
		uint256 lockupDuration,
		uint256 lockupFraction
	) 
	{
		_tradedToken = tradedToken;
		_lockupDuration = lockupDuration;
		_lockupFraction = lockupFraction;
		
	}
	
	function cleanSRC() public onlyOwner() {
		_src20 = address(0);
		_doTransferCaller = address(0);
		//_setChain(address(0));
	}
	
	
	function addExchangeAddress(address addr) public onlyOwner() {
		_exchangeDepositAddresses.add(addr);
	}
	
	function removeExchangeAddress(address addr) public onlyOwner() {
		_exchangeDepositAddresses.remove(addr);
	}
	
	function viewExchangeAddresses() public view returns(address[] memory) {
		uint256 len = _exchangeDepositAddresses.length();
		
		address[] memory ret = new address[](len);
		for (uint256 i =0; i < len; i++) {
			ret[i] = _exchangeDepositAddresses.at(i);
		}
		return ret;
		
	}
	
	function addRestrictions(
		address[] memory addressArray, 
		uint256[] memory amountArray, 
		uint256[] memory untilArray
	) public onlyOwner {
		uint l=addressArray.length;
		for (uint i=0; i<l; i++) {
			restrictions[ addressArray[i] ] = Item({
				lockedAmount: amountArray[i],
				untilTime: untilArray[i]
			});
		}
	}
	
	//---------------------------------------------------------------------------------
	// external  section
	//---------------------------------------------------------------------------------
	/**
	* @dev Set for what contract this rules are.
	*
	* @param src20 - Address of src20 contract.
	*/
	function setSRC(address src20) override external returns (bool) {
		require(_doTransferCaller == address(0), "external contract already set");
		require(address(_src20) == address(0), "external contract already set");
		require(src20 != address(0), "src20 can not be zero");
		_doTransferCaller = _msgSender();
		_src20 = src20;
		return true;
	}
	 /**
	* @dev Do transfer and checks where funds should go.
	* before executeTransfer contract will call chainValidate on chain if exists
	*
	* @param from The address to transfer from.
	* @param to The address to send tokens to.
	* @param value The amount of tokens to send.
	*/
	function doTransfer(address from, address to, uint256 value) override external onlyDoTransferCaller returns (bool) {
		bool success;
		string memory errmsg;
		
		(from, to, value, success, errmsg) = _doValidate(from, to, value);
		
		
		
		require(success, (bytes(errmsg).length == 0) ? "chain validation failed" : errmsg);
		
		// todo: need to check params after chains validation??
		
		require(ISRC20(_src20).executeTransfer(from, to, value), "SRC20 transfer failed");
		
		
		if (
			success && (to == _tradedToken)
		) {
			
			IITR(_tradedToken).claim(from);
			
		}
		
		
		return true;
	}
	//---------------------------------------------------------------------------------
	// internal  section
	//---------------------------------------------------------------------------------
	function _validate(address from, address to, uint256 value) internal virtual override returns (address _from, address _to, uint256 _value, bool _success, string memory _errmsg) {
		
		(_from, _to, _value, _success, _errmsg) = (from, to, value, true, "");

		require(
			_exchangeDepositAddresses.contains(to) == false, 
			string(abi.encodePacked("Don't deposit directly to this exchange. Send to the address ITR.ETH first, to obtain the correct token in your wallet."))
		);
		
		uint256 balanceFrom = ISRC20(_src20).balanceOf(from);
		
		if (restrictions[from].untilTime > block.timestamp) {
			if (to == _tradedToken) {
				_success = false;
				_errmsg = "you recently claimed new tokens, please wait until duration has elapsed to claim again";
			} else if ((restrictions[from].lockedAmount).add(value) > balanceFrom) {
				_success = false;
				_errmsg = "you recently claimed new tokens, please wait until duration has elapsed to transfer this many tokens";
			}
		}
		
		if (
			_success && 
			(to == _tradedToken) &&
			(restrictions[from].untilTime > block.timestamp)
		) {
			
			restrictions[from].untilTime = (block.timestamp).add(_lockupDuration);
			restrictions[from].lockedAmount = (balanceFrom.sub(value)).mul(_lockupFraction).div(MULTIPLIER);
		
		}
		
	}
	
	//---------------------------------------------------------------------------------
	// private  section
	//---------------------------------------------------------------------------------
}