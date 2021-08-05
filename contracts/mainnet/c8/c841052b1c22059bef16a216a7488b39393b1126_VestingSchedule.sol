/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma experimental ABIEncoderV2;

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: @openzeppelin/contracts/GSN/Context.sol


pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
}

// File: @openzeppelin/contracts/utils/EnumerableSet.sol


pragma solidity >=0.6.0 <0.8.0;

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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
}

// File: contracts/WhitelistGuard.sol

pragma solidity ^0.6.0;



abstract contract WhitelistGuard is Ownable
{
	using EnumerableSet for EnumerableSet.AddressSet;

	EnumerableSet.AddressSet private whitelist;

	modifier onlyEOAorWhitelist()
	{
		address _from = _msgSender();
		require(tx.origin == _from || whitelist.contains(_from), "access denied");
		_;
	}

	modifier onlyWhitelist()
	{
		address _from = _msgSender();
		require(whitelist.contains(_from), "access denied");
		_;
	}

	function addToWhitelist(address _address) external onlyOwner
	{
		require(whitelist.add(_address), "already listed");
	}

	function removeFromWhitelist(address _address) external onlyOwner
	{
		require(whitelist.remove(_address), "not listed");
	}
}

// File: @openzeppelin/contracts/math/SafeMath.sol


pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/utils/Address.sol


pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


pragma solidity >=0.6.0 <0.8.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/TimeLockedAccounts.sol

pragma solidity ^0.6.0;



abstract contract TimeLockedAccounts
{
	using SafeERC20 for IERC20;

	struct PeriodInfo {
		uint256 periodDuration;
		uint256 periodCount;
		uint256 ratePerPeriod;
	}

	struct PlanInfo {
		string description;
		PeriodInfo[] periods;
		bool enabled;
	}

	struct AccountInfo {
		uint256 planId;
		uint256 initialBalance;
		uint256 currentBalance;
		uint256 baseTime;
		uint256 basePeriodIndex;
		uint256 basePeriodCount;
	}

	address public immutable token;

	uint256 private planCount_;
	mapping (uint256 => PlanInfo) private planInfo_;

	mapping (address => AccountInfo) public accountInfo;

	constructor (address _token) public
	{
		token = _token;
	}

	function planInfo(uint256 _planId) external view returns (string memory _description, bool _enabled)
	{
		PlanInfo memory _plan = planInfo_[_planId];
		return (_plan.description, _plan.enabled);
	}

	function periodInfo(uint256 _planId, uint256 _i) external view returns (uint256 periodDuration, uint256 periodCount, uint256 ratePerPeriod)
	{
		PlanInfo memory _plan = planInfo_[_planId];
		PeriodInfo memory _period = _plan.periods[_i];
		return (_period.periodDuration, _period.periodCount, _period.ratePerPeriod);
	}

	function available(address _receiver) external view returns (uint256 _amount)
	{
		uint256 _when = now;
		(,,,,_amount) = _available(_receiver, _when);
		return _amount;
	}

	function available(address _receiver, uint256 _when) external view returns (uint256 _amount)
	{
		(,,,,_amount) = _available(_receiver, _when);
		return _amount;
	}

	function deposit(address _receiver, uint256 _amount, uint256 _planId) public virtual
	{
		address _sender = msg.sender;
		uint256 _baseTime = now;
		_deposit(_receiver, _amount, _planId, _baseTime);
		IERC20(token).safeTransferFrom(_sender, address(this), _amount);
	}

	function depositBatch(address _sender, address[] memory _receivers, uint256[] memory _amounts, uint256 _planId, uint256 _baseTime) public virtual
	{
		require(_receivers.length == _amounts.length, "length mismatch");
		uint256 _totalAmount = 0;
		for (uint256 _i = 0; _i < _receivers.length; _i++) {
			address _receiver = _receivers[_i];
			uint256 _amount = _amounts[_i];
			_deposit(_receiver, _amount, _planId, _baseTime);
			uint256 _prevTotalAmount = _totalAmount;
			_totalAmount += _amount;
			require(_totalAmount >= _prevTotalAmount, "excessive amount");
		}
		IERC20(token).safeTransferFrom(_sender, address(this), _totalAmount);
	}

	function withdraw() public virtual
	{
		address _receiver = msg.sender;
		_withdraw(_receiver);
	}

	function withdrawBatch(address[] memory _receivers) public virtual
	{
		for (uint256 _i = 0; _i < _receivers.length; _i++) {
			_withdraw(_receivers[_i]);
		}
	}

	function _available(address _receiver, uint256 _when) private view returns (uint256 _newCurrentBalance, uint256 _newBaseTime, uint256 _newBasePeriodIndex, uint256 _newBasePeriodCount, uint256 _amount)
	{
		AccountInfo memory _account = accountInfo[_receiver];
		uint256 _planId = _account.planId;
		uint256 _initialBalance = _account.initialBalance;
		_newCurrentBalance = _account.currentBalance;
		_newBaseTime = _account.baseTime;
		_newBasePeriodIndex = _account.basePeriodIndex;
		_newBasePeriodCount = _account.basePeriodCount;
		require(_planId > 0, "nonexistent");
		require(_when >= _newBaseTime, "unavailable");
		PlanInfo memory _plan = planInfo_[_planId];
		PeriodInfo[] memory _periods = _plan.periods;
		for (; _newBasePeriodIndex < _periods.length; _newBasePeriodIndex++) {
			PeriodInfo memory _period = _periods[_newBasePeriodIndex];
			uint256 _periodDuration = _period.periodDuration;
			uint256 _periodCount = (_when - _newBaseTime) / _periodDuration;
			if (_periodCount == 0) break;
			if (_newBasePeriodCount == 0) _newBasePeriodCount = _period.periodCount;
			if (_periodCount > _newBasePeriodCount) _periodCount = _newBasePeriodCount;
			uint256 _ratePerPeriod = _period.ratePerPeriod;
			uint256 _amountPerPeriod = (_initialBalance * _ratePerPeriod) / 1e12;
			_newCurrentBalance -= _periodCount * _amountPerPeriod;
			_newBaseTime += _periodCount * _periodDuration;
			_newBasePeriodCount -= _periodCount;
			if (_newBasePeriodCount > 0) break;
		}
		_amount = _account.currentBalance - _newCurrentBalance;
		return (_newCurrentBalance, _newBaseTime, _newBasePeriodIndex, _newBasePeriodCount, _amount);
	}

	function _deposit(address _receiver, uint256 _amount, uint256 _planId, uint256 _baseTime) private
	{
		require(1 <= _amount && _amount <= uint256(-1) / 1e12, "invalid amount");
		require(1 <= _planId && _planId <= planCount_, "invalid plan");
		PlanInfo memory _plan = planInfo_[_planId];
		require(_plan.enabled, "unavailable");
		PeriodInfo[] memory _periods = _plan.periods;
		uint256 _sumAmount = 0;
		for (uint256 _i = 0; _i < _periods.length; _i++) {
			PeriodInfo memory _period = _periods[_i];
			uint256 _periodCount = _period.periodCount;
			uint256 _ratePerPeriod = _period.ratePerPeriod;
			uint256 _amountPerPeriod = (_amount * _ratePerPeriod) / 1e12;
			_sumAmount += _periodCount * _amountPerPeriod;
		}
		require(_sumAmount == _amount, "invalid amount");
		AccountInfo storage _account = accountInfo[_receiver];
		require(_account.planId == 0, "already exists");
		_account.planId = _planId;
		_account.initialBalance = _amount;
		_account.currentBalance = _amount;
		_account.baseTime = _baseTime;
		_account.basePeriodIndex = 0;
		_account.basePeriodCount = 0;
	}

	function _withdraw(address _receiver) private
	{
		uint256 _when = now;
		(uint256 _newCurrentBalance, uint256 _newBaseTime, uint256 _newBasePeriodIndex, uint256 _newBasePeriodCount, uint256 _amount) = _available(_receiver, _when);
		require(_amount > 0, "unavailable");
		AccountInfo storage _account = accountInfo[_receiver];
		_account.currentBalance = _newCurrentBalance;
		_account.baseTime = _newBaseTime;
		_account.basePeriodIndex = _newBasePeriodIndex;
		_account.basePeriodCount = _newBasePeriodCount;
		IERC20(token).safeTransfer(_receiver, _amount);
	}

	function _createPlan(string memory _description) internal returns (uint256 _planId)
	{
		_planId = ++planCount_;
		PlanInfo storage _plan = planInfo_[_planId];
		_plan.description = _description;
		_plan.enabled = false;
		return _planId;
	}

	function _addPlanPeriod(uint256 _planId, uint256 _periodDuration, uint256 _periodCount, uint256 _ratePerPeriod) internal
	{
		require(1 <= _planId && _planId <= planCount_, "invalid plan");
		require(_periodDuration > 0, "invalid duration");
		require(_ratePerPeriod <= 1e12, "invalid rate");
		uint256 _maxPeriodCount = _ratePerPeriod == 0 ? 1 : 1e12 / _ratePerPeriod;
		require(1 <= _periodCount && _periodCount <= _maxPeriodCount, "invalid count");
		PlanInfo storage _plan = planInfo_[_planId];
		require(!_plan.enabled, "unavailable");
		_plan.periods.push(PeriodInfo({
			periodDuration: _periodDuration,
			periodCount: _periodCount,
			ratePerPeriod: _ratePerPeriod
		}));
	}

	function _enablePlan(uint256 _planId) internal
	{
		require(1 <= _planId && _planId <= planCount_, "invalid plan");
		PlanInfo storage _plan = planInfo_[_planId];
		require(!_plan.enabled, "unavailable");
		PeriodInfo[] memory _periods = _plan.periods;
		uint256 _sumRate = 0;
		for (uint256 _i = 0; _i < _periods.length; _i++) {
			uint256 _periodCount = _periods[_i].periodCount;
			uint256 _ratePerPeriod = _periods[_i].ratePerPeriod;
			_sumRate += _periodCount * _ratePerPeriod;
		}
		require(_sumRate == 1e12, "invalid rate sum");
		_plan.enabled = true;
	}
}

// File: contracts/ManagedTimeLockedAccounts.sol

pragma solidity ^0.6.0;




contract ManagedTimeLockedAccounts is WhitelistGuard, TimeLockedAccounts
{
	address public treasury;

	uint256 public totalBalance;
	bool public allowFullRecovery = true;

	constructor (address _token, address _treasury) TimeLockedAccounts(_token) public
	{
		treasury = _treasury;
	}

	function deposit(address _receiver, uint256 _amount, uint256 _planId) public override onlyOwner
	{
		uint256 _balanceBefore = IERC20(token).balanceOf(address(this));
		TimeLockedAccounts.deposit(_receiver, _amount, _planId);
		uint256 _balanceAfter = IERC20(token).balanceOf(address(this));
		totalBalance += _balanceAfter - _balanceBefore;
	}

	function depositBatch(address _sender, address[] memory _receivers, uint256[] memory _amounts, uint256 _planId, uint256 _baseTime) public override onlyOwner
	{
		uint256 _balanceBefore = IERC20(token).balanceOf(address(this));
		TimeLockedAccounts.depositBatch(_sender, _receivers, _amounts, _planId, _baseTime);
		uint256 _balanceAfter = IERC20(token).balanceOf(address(this));
		totalBalance += _balanceAfter - _balanceBefore;
	}

	function withdraw() public override onlyEOAorWhitelist
	{
		uint256 _balanceBefore = IERC20(token).balanceOf(address(this));
		TimeLockedAccounts.withdraw();
		uint256 _balanceAfter = IERC20(token).balanceOf(address(this));
		totalBalance -= _balanceBefore - _balanceAfter;
	}

	function withdrawBatch(address[] memory _receivers) public override onlyOwner
	{
		uint256 _balanceBefore = IERC20(token).balanceOf(address(this));
		TimeLockedAccounts.withdrawBatch(_receivers);
		uint256 _balanceAfter = IERC20(token).balanceOf(address(this));
		totalBalance -= _balanceBefore - _balanceAfter;
	}

	function createPlan(string memory _description) external onlyOwner returns (uint256 _planId)
	{
		return _createPlan(_description);
	}

	function addPlanPeriod(uint256 _planId, uint256 _periodDuration, uint256 _periodCount, uint256 _ratePerPeriod) external onlyOwner
	{
		_addPlanPeriod(_planId, _periodDuration, _periodCount, _ratePerPeriod);
	}

	function enablePlan(uint256 _planId) external onlyOwner
	{
		_enablePlan(_planId);
	}

	function disableFullRecovery() external onlyOwner
	{
		allowFullRecovery = false;
	}

	function recoverLostFunds(address _token) external onlyOwner
	{
		uint256 _balance = IERC20(_token).balanceOf(address(this));
		if (_token == token && !allowFullRecovery) {
			_balance -= totalBalance;
		}
		IERC20(_token).safeTransfer(treasury, _balance);
	}

	function setTreasury(address _newTreasury) external onlyOwner
	{
		require(_newTreasury != address(0), "invalid address");
		address _oldTreasury = treasury;
		treasury = _newTreasury;
		emit ChangeTreasury(_oldTreasury, _newTreasury);
	}

	event ChangeTreasury(address _oldTreasury, address _newTreasury);
}

contract VestingSchedule is ManagedTimeLockedAccounts
{
	constructor (address _token, address _treasury) ManagedTimeLockedAccounts(_token, _treasury) public
	{
		uint256[] memory _rates = new uint256[](6);
		_rates[0] = 24e10; // 1st year 24%
		_rates[1] = 22e10; // 2st year 22%
		_rates[2] = 18e10; // 3st year 18%
		_rates[3] = 16e10; // 4st year 16%
		_rates[4] = 12e10; // 5st year 12%
		_rates[5] = 8e10;  // 6st year 8%
		_createVestingPlan("Vesting", 7 days, 52, _rates); // 52 weeks / year
	}

	function _createVestingPlan(string memory _description, uint256 _periodDuration, uint256 _periodCount, uint256[] memory _rates) internal returns (uint256 _planId)
	{
		_planId = _createPlan(_description);
		uint256 _remRate = 0;
		for (uint256 _i = 0; _i < _rates.length; _i++) {
			uint256 _rate = _rates[_i];
			uint256 _ratePerPeriod = _rate / _periodCount;
			_addPlanPeriod(_planId, _periodDuration, _periodCount, _ratePerPeriod);
			_remRate += _rate - _periodCount * _ratePerPeriod;
		}
		if (_remRate > 0) {
			_addPlanPeriod(_planId, 1, 1, _remRate);
		}
		_enablePlan(_planId);
		return _planId;
	}
}

contract SalesASchedule is ManagedTimeLockedAccounts
{
	constructor (address _token, address _treasury) ManagedTimeLockedAccounts(_token, _treasury) public
	{
		uint256 _planId = _createPlan("Sales A");
		_addPlanPeriod(_planId, 30 days, 1, 8e10);   // 1 x 8% (30d)
		_addPlanPeriod(_planId, 30 days, 16, 575e8); // 16 x 5.75% (30d)
		_enablePlan(_planId);
	}
}

contract SalesSSchedule is ManagedTimeLockedAccounts
{
	constructor (address _token, address _treasury) ManagedTimeLockedAccounts(_token, _treasury) public
	{
		uint256 _planId = _createPlan("Sales S");
		_addPlanPeriod(_planId, 30 days, 1, 10e10); // 1 x 10% (30d)
		_addPlanPeriod(_planId, 30 days, 12, 75e9); // 12 x 7.5% (30d)
		_enablePlan(_planId);
	}
}

contract SalesPSchedule is ManagedTimeLockedAccounts
{
	constructor (address _token, address _treasury) ManagedTimeLockedAccounts(_token, _treasury) public
	{
		uint256 _planId = _createPlan("Sales P");
		_addPlanPeriod(_planId, 1 seconds, 1, 12e10); // 1 x 12%
		_addPlanPeriod(_planId, 30 days, 8, 11e10);   // 8 x 11% (30d)
		_enablePlan(_planId);
	}
}

contract AirdropSchedule is ManagedTimeLockedAccounts
{
	constructor (address _token, address _treasury) ManagedTimeLockedAccounts(_token, _treasury) public
	{
		uint256 _planId = _createPlan("Airdrop");
		_addPlanPeriod(_planId, 1 seconds, 1, 1e12); // 100%
		_enablePlan(_planId);
	}
}