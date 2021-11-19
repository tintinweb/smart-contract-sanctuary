/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

pragma solidity 0.6.11;

// SPDX-License-Identifier: BSD-3-Clause

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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface IUniswapV2Router {
    
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
    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Pair {
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function token0() external view returns (address);
  function token1() external view returns (address);
  
  function sync() external;
}


interface StakingContract {
    function depositByContract(address account, uint amount, uint _amountOutMin_stakingReferralFee, uint deadline) external;
}


/**
 * @dev Staking Smart Contract
 * 
 *  - Users stake Uniswap LP Tokens to receive WETH and DYP Tokens as Rewards
 * 
 *  - Reward Tokens (DYP) are added to contract balance upon deployment by deployer
 * 
 *  - After Adding the DYP rewards, admin is supposed to transfer ownership to Governance contract
 * 
 *  - Users deposit Set (Predecided) Uniswap LP Tokens and get a share of the farm
 * 
 *  - The smart contract disburses `disburseAmount` DYP as rewards over `disburseDuration`
 * 
 *  - A swap is attempted periodically at atleast a set delay from last swap
 * 
 *  - The swap is attempted according to SWAP_PATH for difference deployments of this contract
 * 
 *  - For 4 different deployments of this contract, the SWAP_PATH will be:
 *      - DYP-WETH
 *      - DYP-WBTC-WETH (assumes appropriate liquidity is available in WBTC-WETH pair)
 *      - DYP-USDT-WETH (assumes appropriate liquidity is available in USDT-WETH pair)
 *      - DYP-USDC-WETH (assumes appropriate liquidity is available in USDC-WETH pair)
 * 
 *  - Any swap may not have a price impact on DYP price of more than approx ~2.49% for the related DYP pair
 *      DYP-WETH swap may not have a price impact of more than ~2.49% on DYP price in DYP-WETH pair
 *      DYP-WBTC-WETH swap may not have a price impact of more than ~2.49% on DYP price in DYP-WBTC pair
 *      DYP-USDT-WETH swap may not have a price impact of more than ~2.49% on DYP price in DYP-USDT pair
 *      DYP-USDC-WETH swap may not have a price impact of more than ~2.49% on DYP price in DYP-USDC pair
 * 
 *  - After the swap,converted WETH is distributed to stakers at pro-rata basis, according to their share of the staking pool
 *    on the moment when the WETH distribution is done. And remaining DYP is added to the amount to be distributed or burnt.
 *    The remaining DYP are also attempted to be swapped to WETH in the next swap if the price impact is ~2.49% or less
 * 
 *  - At a set delay from last execution, Governance contract (owner) may execute disburse or burn features
 * 
 *  - Burn feature should send the DYP tokens to set BURN_ADDRESS
 * 
 *  - Disburse feature should disburse the DYP 
 *    (which would have a max price impact ~2.49% if it were to be swapped, at disburse time 
 *    - remaining DYP are sent to BURN_ADDRESS) 
 *    to stakers at pro-rata basis according to their share of
 *    the staking pool at the moment the disburse is done
 * 
 *  - Users may claim their pending WETH and DYP anytime
 * 
 *  - Pending rewards are auto-claimed on any deposit or withdraw
 * 
 *  - Users need to wait `cliffTime` duration since their last deposit before withdrawing any LP Tokens
 * 
 *  - Owner may not transfer out LP Tokens from this contract anytime
 * 
 *  - Owner may transfer out WETH and DYP Tokens from this contract once `adminClaimableTime` is reached
 * 
 *  - CONTRACT VARIABLES must be changed to appropriate values before live deployment
 */
contract FarmProRata is Ownable {
    using SafeMath for uint;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;
    using SafeERC20 for IERC20;

    event RewardsTransferred(address holder, uint amount);
    event EthRewardsTransferred(address holder, uint amount);
    
    event RewardsDisbursed(uint amount);
    event EthRewardsDisbursed(uint amount);
    event EmergencyDeclared(address owner);

    event UniswapV2RouterChanged(address router);
    event StakingFeeChanged(uint fee);
    event UnstakingFeeChanged(uint fee);
    event MagicNumberChanged(uint newMagicNumber);
    event LockupTimeChanged(uint lockupTime);
    event FeeRecipientAddressChanged(address newAddress);
    
    // ============ SMART CONTRACT VARIABLES ==========================
    // Must be changed to appropriate configuration before live deployment

    // deposit token contract address and reward token contract address
    // these contracts (and uniswap pair & router) are "trusted" 
    // and checked to not contain re-entrancy pattern
    // to safely avoid checks-effects-interactions where needed to simplify logic
    address public constant trustedDepositTokenAddress = 0x1bC61d08A300892e784eD37b2d0E63C85D1d57fb; // uniswap pair address
    
    // token used for rewards - this must be one of the tokens in uniswap pair.
    address public constant trustedRewardTokenAddress = 0xBD100d061E120b2c67A24453CF6368E63f1Be056;

    address public constant trustedStakingContractAddress = 0x23609B1f5274160564e4afC5eB9329A8Bf81c744;

    
    // the main token which is normally claimed as reward
    address public constant trustedPlatformTokenAddress = 0x961C8c0B1aaD0c0b10a51FeF6a867E3091BCef17;
    
    // the other token in the uniswap pair used
    address public constant trustedBaseTokenAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    
    // Make sure to double-check BURN_ADDRESS
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    // cliffTime - withdraw is not possible within cliffTime of deposit
    uint public cliffTime = 3 days;

    // Amount of tokens
    uint public constant disburseAmount = 83000e18;
    // To be disbursed continuously over this duration
    uint public constant disburseDuration = 365 days;
    
    // If there are any undistributed or unclaimed tokens left in contract after this time
    // Admin can claim them
    uint public constant adminCanClaimAfter = 395 days;
    
    // delays between attempted swaps
    uint public constant swapAttemptPeriod = 1 days;
    // delays between attempted burns or token disbursement
    uint public constant burnOrDisburseTokensPeriod = 7 days;

    // do not change this => disburse 100% rewards over `disburseDuration`
    uint public constant disbursePercentX100 = 100e2;
    
    uint public constant EMERGENCY_WAIT_TIME = 3 days;
    
    uint public STAKING_FEE_RATE_X_100 = 0;
    uint public UNSTAKING_FEE_RATE_X_100 = 0;
    
    uint public MAGIC_NUMBER = 5025125628140614;
   
    
    //  ============ END CONTRACT VARIABLES ==========================
    
    event ClaimableTokenAdded(address indexed tokenAddress);
    event ClaimableTokenRemoved(address indexed tokenAddress);
    mapping (address => bool) public trustedClaimableTokens;
    function addTrustedClaimableToken(address trustedClaimableTokenAddress) external onlyOwner {
        trustedClaimableTokens[trustedClaimableTokenAddress] = true;
        emit ClaimableTokenAdded(trustedClaimableTokenAddress);
    }
    function removeTrustedClaimableToken(address trustedClaimableTokenAddress) external onlyOwner {
        trustedClaimableTokens[trustedClaimableTokenAddress] = false;
        emit ClaimableTokenRemoved(trustedClaimableTokenAddress);
    }

    uint public contractDeployTime;
    uint public adminClaimableTime;
    uint public lastDisburseTime;
    uint public lastSwapExecutionTime;
    uint public lastBurnOrTokenDistributeTime;

    bool public isEmergency = false;
    
    IUniswapV2Router public uniswapRouterV2;
    IUniswapV2Pair public uniswapV2Pair;
    address[] public SWAP_PATH;
    
    address public feeRecipientAddress;
    
    
    constructor(address[] memory swapPath, address _uniswapV2RouterAddress, address _feeRecipientAddress) public {
        contractDeployTime = now;
        adminClaimableTime = contractDeployTime.add(adminCanClaimAfter);
        lastDisburseTime = contractDeployTime;
        lastSwapExecutionTime = lastDisburseTime;
        lastBurnOrTokenDistributeTime = lastDisburseTime;
        
        setUniswapV2Router(IUniswapV2Router(_uniswapV2RouterAddress));
        setFeeRecipientAddress(_feeRecipientAddress);
        
        uniswapV2Pair = IUniswapV2Pair(trustedDepositTokenAddress);
        SWAP_PATH = swapPath;
    }
    
    function setFeeRecipientAddress(address newFeeRecipientAddress) public onlyOwner {
        require(newFeeRecipientAddress != address(0), "Invalid address!");
        feeRecipientAddress = newFeeRecipientAddress;
        emit FeeRecipientAddressChanged(feeRecipientAddress);
    }

    // Contracts are not allowed to deposit, claim or withdraw
    modifier noContractsAllowed() {
        require(!(address(msg.sender).isContract()) && tx.origin == msg.sender, "No Contracts Allowed!");
        _;
    }

    modifier notDuringEmergency() {
        require(!isEmergency, "Cannot execute during emergency!");
        _;
    }
    
    function declareEmergency() external onlyOwner notDuringEmergency {
        isEmergency = true;
        adminClaimableTime = now.add(EMERGENCY_WAIT_TIME);
        cliffTime = 0;
        
        emit EmergencyDeclared(owner);
    }

    uint public totalClaimedRewards = 0;
    uint public totalClaimedRewardsEth = 0;

    EnumerableSet.AddressSet private holders;

    mapping (address => uint) public depositedTokens;
    mapping (address => uint) public depositTime;
    mapping (address => uint) public lastClaimedTime;
    mapping (address => uint) public totalEarnedTokens;
    mapping (address => uint) public totalEarnedEth;
    mapping (address => uint) public lastDivPoints;
    mapping (address => uint) public lastEthDivPoints;

    uint public contractBalance = 0;

    uint public totalDivPoints = 0;
    uint public totalEthDivPoints = 0;
    uint public totalTokens = 0;
    
    uint public tokensToBeDisbursedOrBurnt = 0;
    uint public tokensToBeSwapped = 0;

    uint internal constant pointMultiplier = 1e18;

    function setUniswapV2Router(IUniswapV2Router router) public onlyOwner {
        require(address(router) != address(0), "Invalid router address!");
        uniswapRouterV2 = router;
        emit UniswapV2RouterChanged(address(uniswapRouterV2));
    }
    function setStakingFeeRateX100(uint newStakingFeeRateX100) public onlyOwner {
        require(newStakingFeeRateX100 < 100e2, "Invalid fee!");
        STAKING_FEE_RATE_X_100 = newStakingFeeRateX100;
        emit StakingFeeChanged(STAKING_FEE_RATE_X_100);
    }
    function setUnstakingFeeRateX100(uint newUnstakingFeeRateX100) public onlyOwner {
        require(newUnstakingFeeRateX100 < 100e2, "Invalid fee!");
        UNSTAKING_FEE_RATE_X_100 = newUnstakingFeeRateX100;
        emit UnstakingFeeChanged(UNSTAKING_FEE_RATE_X_100);
    }
    function setMagicNumber(uint newMagicNumber) public onlyOwner {
        MAGIC_NUMBER = newMagicNumber;
        emit MagicNumberChanged(MAGIC_NUMBER);
    }
    function setLockupTime(uint _newLockupTime) public onlyOwner {
        require(_newLockupTime <= 90 days, "Lockup time too long!");
        cliffTime = _newLockupTime;
        emit LockupTimeChanged(cliffTime);
    }

    function setContractVariables(
        uint newMagicNumber, 
        uint lockupTime,
        uint stakingFeeRateX100,
        uint unstakingFeeRateX100,
        address _uniswapV2RouterAddress,
        address newFeeRecipientAddress
    ) external onlyOwner {
        setMagicNumber(newMagicNumber);
        setLockupTime(lockupTime);
        setStakingFeeRateX100(stakingFeeRateX100);
        setUnstakingFeeRateX100(unstakingFeeRateX100);
        setUniswapV2Router(IUniswapV2Router(_uniswapV2RouterAddress));
        setFeeRecipientAddress(newFeeRecipientAddress);
    }

    // To be executed by admin after deployment to add DYP to contract
    function addContractBalance(uint amount) public onlyOwner {
        IERC20(trustedRewardTokenAddress).safeTransferFrom(msg.sender, address(this), amount);
        contractBalance = contractBalance.add(amount);
    }
    
    function doSwap(address fromToken, address toToken, uint fromTokenAmount, uint amountOutMin, uint deadline) 
        private returns (uint _toTokenReceived) {
            
        if (fromToken == toToken) {
            return fromTokenAmount;
        }
            
        IERC20(fromToken).safeApprove(address(uniswapRouterV2), 0);
        IERC20(fromToken).safeApprove(address(uniswapRouterV2), fromTokenAmount);
        
        uint oldToTokenBalance = IERC20(toToken).balanceOf(address(this));
        
        address[] memory path;
        
        if (fromToken == uniswapRouterV2.WETH() || toToken == uniswapRouterV2.WETH()) {
            path = new address[](2);
            path[0] = fromToken;
            path[1] = toToken;
        } else {
            path = new address[](3);
            path[0] = fromToken;
            path[1] = uniswapRouterV2.WETH();
            path[2] = toToken;
        }
        
        uniswapRouterV2.swapExactTokensForTokens(fromTokenAmount, amountOutMin, path, address(this), deadline);
        
        uint newToTokenBalance = IERC20(toToken).balanceOf(address(this));
        uint toTokenReceived = newToTokenBalance.sub(oldToTokenBalance);
        return toTokenReceived;
    }
    
    // Private function to update account information and auto-claim pending rewards
    function updateAccount(
        address account, 
        address claimAsToken, 
        uint _amountOutMin_claimAsToken_weth, 
        uint _amountOutMin_claimAsToken_dyp, 
        uint _amountOutMin_attemptSwap, 
        uint _deadline
    ) private {
        disburseTokens();
        attemptSwap(_amountOutMin_attemptSwap, _deadline);
        uint pendingDivs = getPendingDivs(account);
        if (pendingDivs > 0) {
            
            uint amountToTransfer;
            address tokenToTransfer;
            
            if (claimAsToken == address(0) || claimAsToken == trustedPlatformTokenAddress) {
                tokenToTransfer = trustedPlatformTokenAddress;
                amountToTransfer = doSwap(trustedRewardTokenAddress, trustedPlatformTokenAddress, pendingDivs, _amountOutMin_claimAsToken_dyp, _deadline);
            } else {
                tokenToTransfer = claimAsToken;
                amountToTransfer = doSwap(trustedRewardTokenAddress, claimAsToken, pendingDivs, _amountOutMin_claimAsToken_dyp, _deadline);
            }
            
            IERC20(tokenToTransfer).safeTransfer(account, amountToTransfer);
        
            totalEarnedTokens[account] = totalEarnedTokens[account].add(pendingDivs);
            totalClaimedRewards = totalClaimedRewards.add(pendingDivs);
            emit RewardsTransferred(account, pendingDivs);
        }
        
        uint pendingDivsEth = getPendingDivsEth(account);
        if (pendingDivsEth > 0) {
            
            if (claimAsToken == address(0) || claimAsToken == uniswapRouterV2.WETH()) {
                IERC20(uniswapRouterV2.WETH()).safeTransfer(account, pendingDivsEth);
            } else {
                require(trustedClaimableTokens[claimAsToken], "cannot claim as this token!");
                
                IERC20(uniswapRouterV2.WETH()).safeApprove(address(uniswapRouterV2), 0);
                IERC20(uniswapRouterV2.WETH()).safeApprove(address(uniswapRouterV2), pendingDivsEth);
                address[] memory path = new address[](2);
                path[0] = uniswapRouterV2.WETH();
                path[1] = claimAsToken;
                
                uniswapRouterV2.swapExactTokensForTokens(pendingDivsEth, _amountOutMin_claimAsToken_weth, path, account, _deadline);
            }
            
            totalEarnedEth[account] = totalEarnedEth[account].add(pendingDivsEth);
            totalClaimedRewardsEth = totalClaimedRewardsEth.add(pendingDivsEth);
            emit EthRewardsTransferred(account, pendingDivsEth);
        }
        
        lastClaimedTime[account] = now;
        lastDivPoints[account] = totalDivPoints;
        lastEthDivPoints[account] = totalEthDivPoints;
    }
    
    function updateAccount(address account, uint _amountOutMin_claimAsToken_dyp, uint _amountOutMin_attemptSwap, uint _deadline) private {
        updateAccount(account, address(0), 0, _amountOutMin_claimAsToken_dyp, _amountOutMin_attemptSwap, _deadline);
    }

    // view function to check last updated DYP pending rewards
    function getPendingDivs(address _holder) public view returns (uint) {
        if (!holders.contains(_holder)) return 0;
        if (depositedTokens[_holder] == 0) return 0;

        uint newDivPoints = totalDivPoints.sub(lastDivPoints[_holder]);

        uint depositedAmount = depositedTokens[_holder];

        uint pendingDivs = depositedAmount.mul(newDivPoints).div(pointMultiplier);

        return pendingDivs;
    }
    
    // view function to check last updated WETH pending rewards
    function getPendingDivsEth(address _holder) public view returns (uint) {
        if (!holders.contains(_holder)) return 0;
        if (depositedTokens[_holder] == 0) return 0;

        uint newDivPoints = totalEthDivPoints.sub(lastEthDivPoints[_holder]);

        uint depositedAmount = depositedTokens[_holder];

        uint pendingDivs = depositedAmount.mul(newDivPoints).div(pointMultiplier);

        return pendingDivs;
    }
    
    // view functon to get number of stakers
    function getNumberOfHolders() public view returns (uint) {
        return holders.length();
    }

    // deposit function to stake LP Tokens
    function deposit(
        address depositToken, 
        uint amountToStake, 
        uint[] memory minAmounts,
        // uint _amountOutMin_25Percent, // 0
        // uint _amountOutMin_stakingReferralFee, // 1
        // uint amountLiquidityMin_rewardTokenReceived, // 2
        // uint amountLiquidityMin_baseTokenReceived, // 3
        // uint _amountOutMin_rewardTokenReceived, // 4
        // uint _amountOutMin_baseTokenReceived, // 5
        // uint _amountOutMin_claimAsToken_dyp, // 6
        // uint _amountOutMin_attemptSwap, // 7
        uint _deadline
    ) public noContractsAllowed notDuringEmergency {
        require(minAmounts.length == 8, "Invalid minAmounts length!");
        
        require(trustedClaimableTokens[depositToken], "Invalid deposit token!");

        // can deposit reward token directly
        // require(depositToken != trustedRewardTokenAddress, "Cannot deposit reward token!");
        
        require(depositToken != trustedDepositTokenAddress, "Cannot deposit LP directly!");
        require(depositToken != address(0), "Deposit token cannot be 0!");

        require(amountToStake > 0, "Invalid amount to Stake!");

        IERC20(depositToken).safeTransferFrom(msg.sender, address(this), amountToStake);

        uint fee = amountToStake.mul(STAKING_FEE_RATE_X_100).div(100e2);
        uint amountAfterFee = amountToStake.sub(fee);
        if (fee > 0) {
            IERC20(depositToken).safeTransfer(feeRecipientAddress, fee);
        }

        uint _75Percent = amountAfterFee.mul(75e2).div(100e2);
        uint _25Percent = amountAfterFee.sub(_75Percent);

        uint amountToDepositByContract = doSwap(depositToken, trustedPlatformTokenAddress, _25Percent, /*_amountOutMin_25Percent*/minAmounts[0], _deadline);

        IERC20(trustedPlatformTokenAddress).safeApprove(address(trustedStakingContractAddress), 0);
        IERC20(trustedPlatformTokenAddress).safeApprove(address(trustedStakingContractAddress), amountToDepositByContract);

        StakingContract(trustedStakingContractAddress).depositByContract(msg.sender, amountToDepositByContract, /*_amountOutMin_stakingReferralFee*/minAmounts[1], _deadline);

        uint half = _75Percent.div(2);
        uint otherHalf = _75Percent.sub(half);

        uint _rewardTokenReceived = doSwap(depositToken, trustedRewardTokenAddress, half, /*_amountOutMin_rewardTokenReceived*/minAmounts[4], _deadline);
        uint _baseTokenReceived = doSwap(depositToken, trustedBaseTokenAddress, otherHalf, /*_amountOutMin_baseTokenReceived*/minAmounts[5], _deadline);

        uint amountToDeposit = addLiquidityAndGetAmountToDeposit(
            _rewardTokenReceived, 
            _baseTokenReceived,
            minAmounts,
            _deadline
        );

        require(amountToDeposit > 0, "Cannot deposit 0 Tokens");

        updateAccount(msg.sender, /*_amountOutMin_claimAsToken_dyp*/minAmounts[6], /*_amountOutMin_attemptSwap*/minAmounts[7], _deadline);
        
        depositedTokens[msg.sender] = depositedTokens[msg.sender].add(amountToDeposit);
        totalTokens = totalTokens.add(amountToDeposit);

        holders.add(msg.sender);
        depositTime[msg.sender] = now;
    }
    
    function addLiquidityAndGetAmountToDeposit(
        uint _rewardTokenReceived, 
        uint _baseTokenReceived, 
        uint[] memory minAmounts,
        uint _deadline
    ) private returns (uint) {
        require(_rewardTokenReceived >= minAmounts[2], "Reward Token Received lower than expected!");
        require(_baseTokenReceived >= minAmounts[3], "Base Token Received lower than expected!");

        uint oldLpBalance = IERC20(trustedDepositTokenAddress).balanceOf(address(this));

        IERC20(trustedRewardTokenAddress).safeApprove(address(uniswapRouterV2), 0);
        IERC20(trustedRewardTokenAddress).safeApprove(address(uniswapRouterV2), _rewardTokenReceived);

        IERC20(trustedBaseTokenAddress).safeApprove(address(uniswapRouterV2), 0);
        IERC20(trustedBaseTokenAddress).safeApprove(address(uniswapRouterV2), _baseTokenReceived);

        uniswapRouterV2.addLiquidity(
            trustedRewardTokenAddress,
            trustedBaseTokenAddress,
            _rewardTokenReceived,
            _baseTokenReceived,
            /*amountLiquidityMin_rewardTokenReceived*/minAmounts[2],
            /*amountLiquidityMin_baseTokenReceived*/minAmounts[3],
            address(this),
            _deadline
        );

        uint newLpBalance = IERC20(trustedDepositTokenAddress).balanceOf(address(this));
        uint lpTokensReceived = newLpBalance.sub(oldLpBalance);

        return lpTokensReceived;
    }

    // withdraw function to unstake LP Tokens
    function withdraw(
        address withdrawAsToken,  
        uint amountToWithdraw, 
        uint[] memory minAmounts,
        // uint _amountLiquidityMin_rewardToken, // 0
        // uint _amountLiquidityMin_baseToken, // 1
        // uint _amountOutMin_withdrawAsToken_rewardTokenReceived, // 2
        // uint _amountOutMin_withdrawAsToken_baseTokenReceived, // 3
        // uint _amountOutMin_claimAsToken_dyp,  // 4
        // uint _amountOutMin_attemptSwap, // 5
        uint _deadline
    ) public noContractsAllowed {
        require(minAmounts.length == 6, "Invalid minAmounts!");
        require(withdrawAsToken != address(0), "Invalid withdraw token!");
        require(trustedClaimableTokens[withdrawAsToken], "Withdraw token not trusted!");
        require(amountToWithdraw > 0, "Cannot withdraw 0 Tokens!");

        require(depositedTokens[msg.sender] >= amountToWithdraw, "Invalid amount to withdraw");
        require(now.sub(depositTime[msg.sender]) > cliffTime, "You recently deposited, please wait before withdrawing.");
        
        updateAccount(msg.sender, /*_amountOutMin_claimAsToken_dyp*/ minAmounts[4] , /*_amountOutMin_attemptSwap*/ minAmounts[5], _deadline);
        
        uint fee = amountToWithdraw.mul(UNSTAKING_FEE_RATE_X_100).div(100e2);
        uint amountAfterFee = amountToWithdraw.sub(fee);
        if (fee > 0) {
            IERC20(trustedDepositTokenAddress).safeTransfer(feeRecipientAddress, fee);
        }

        uint withdrawTokenReceived = removeLiquidityAndGetWithdrawTokenReceived(withdrawAsToken, amountAfterFee, minAmounts, _deadline);

        IERC20(withdrawAsToken).safeTransfer(msg.sender, withdrawTokenReceived);

        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(amountToWithdraw);
        totalTokens = totalTokens.sub(amountToWithdraw);

        if (holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }
    
    function removeLiquidityAndGetWithdrawTokenReceived(
        address withdrawAsToken, 
        uint amountAfterFee, 
        uint[] memory minAmounts,
        uint _deadline
    ) private returns (uint) {
        
        IERC20(trustedDepositTokenAddress).safeApprove(address(uniswapRouterV2), 0);
        IERC20(trustedDepositTokenAddress).safeApprove(address(uniswapRouterV2), amountAfterFee);

        uint _oldRewardTokenBalance = IERC20(trustedRewardTokenAddress).balanceOf(address(this));
        uint _oldBaseTokenBalance = IERC20(trustedBaseTokenAddress).balanceOf(address(this));

        uniswapRouterV2.removeLiquidity(
            trustedRewardTokenAddress,
            trustedBaseTokenAddress,
            amountAfterFee,
            /*_amountLiquidityMin_rewardToken*/ minAmounts[0],
            /*_amountLiquidityMin_baseToken*/minAmounts[1],
            address(this),
            _deadline
        );

        uint _newRewardTokenBalance = IERC20(trustedRewardTokenAddress).balanceOf(address(this));
        uint _newBaseTokenBalance = IERC20(trustedBaseTokenAddress).balanceOf(address(this));

        uint _rewardTokenReceivedAfterRemovingLiquidity = _newRewardTokenBalance.sub(_oldRewardTokenBalance);
        uint _baseTokenReceivedAfterRemovingLiquidity = _newBaseTokenBalance.sub(_oldBaseTokenBalance);

        uint withdrawTokenReceived1 = doSwap(trustedRewardTokenAddress, withdrawAsToken, _rewardTokenReceivedAfterRemovingLiquidity, /*_amountOutMin_withdrawAsToken_rewardTokenReceived*/minAmounts[2], _deadline);
        uint withdrawTokenReceived2 = doSwap(trustedBaseTokenAddress, withdrawAsToken, _baseTokenReceivedAfterRemovingLiquidity, /*_amountOutMin_withdrawAsToken_baseTokenReceived*/minAmounts[3], _deadline);

        uint tokensReceived = withdrawTokenReceived1.add(withdrawTokenReceived2);
        
        return tokensReceived;
    }
    
    // claim function to claim pending rewards
    function claim(uint _amountOutMin_claimAsToken_dyp, uint _amountOutMin_attemptSwap, uint _deadline) public noContractsAllowed notDuringEmergency {
        updateAccount(msg.sender, _amountOutMin_claimAsToken_dyp, _amountOutMin_attemptSwap, _deadline);
    }
    
    function claimAs(address claimAsToken, uint _amountOutMin_claimAsToken_weth, uint _amountOutMin_claimAsToken_dyp, uint _amountOutMin_attemptSwap, uint _deadline) public noContractsAllowed notDuringEmergency {
        require(trustedClaimableTokens[claimAsToken], "cannot claim as this token!");
        updateAccount(msg.sender, claimAsToken, _amountOutMin_claimAsToken_weth, _amountOutMin_claimAsToken_dyp, _amountOutMin_attemptSwap, _deadline);
    }
    
    // private function to distribute DYP rewards
    function distributeDivs(uint amount) private {
        require(amount > 0 && totalTokens > 0, "distributeDivs failed!");
        totalDivPoints = totalDivPoints.add(amount.mul(pointMultiplier).div(totalTokens));
        emit RewardsDisbursed(amount);
    }
    
    // private function to distribute WETH rewards
    function distributeDivsEth(uint amount) private {
        require(amount > 0 && totalTokens > 0, "distributeDivsEth failed!");
        totalEthDivPoints = totalEthDivPoints.add(amount.mul(pointMultiplier).div(totalTokens));
        emit EthRewardsDisbursed(amount);
    }

    // private function to allocate DYP to be disbursed calculated according to time passed
    function disburseTokens() private {
        uint amount = getPendingDisbursement();

        if (contractBalance < amount) {
            amount = contractBalance;
        }
        if (amount == 0 || totalTokens == 0) return;

        tokensToBeSwapped = tokensToBeSwapped.add(amount);        

        contractBalance = contractBalance.sub(amount);
        lastDisburseTime = now;
    }
    
    function attemptSwap(uint _amountOutMin_attemptSwap, uint _deadline) private {
        // do not attemptSwap if no one has staked
        if (totalTokens == 0) {
            return;
        }
        
        // Cannot execute swap so quickly
        if (now.sub(lastSwapExecutionTime) < swapAttemptPeriod) {
            return;
        }
    
        // force reserves to match balances
        uniswapV2Pair.sync();
    
        uint _tokensToBeSwapped = tokensToBeSwapped.add(tokensToBeDisbursedOrBurnt);
        
        uint maxSwappableAmount = getMaxSwappableAmount();
        
        // don't proceed if no liquidity
        if (maxSwappableAmount == 0) return;
    
        if (maxSwappableAmount < tokensToBeSwapped) {
            
            uint diff = tokensToBeSwapped.sub(maxSwappableAmount);
            _tokensToBeSwapped = tokensToBeSwapped.sub(diff);
            tokensToBeDisbursedOrBurnt = tokensToBeDisbursedOrBurnt.add(diff);
            tokensToBeSwapped = 0;
    
        } else if (maxSwappableAmount < _tokensToBeSwapped) {
    
            uint diff = _tokensToBeSwapped.sub(maxSwappableAmount);
            _tokensToBeSwapped = _tokensToBeSwapped.sub(diff);
            tokensToBeDisbursedOrBurnt = diff;
            tokensToBeSwapped = 0;
    
        } else {
            tokensToBeSwapped = 0;
            tokensToBeDisbursedOrBurnt = 0;
        }
    
        // don't execute 0 swap tokens
        if (_tokensToBeSwapped == 0) {
            return;
        }
    
        // cannot execute swap at insufficient balance
        if (IERC20(trustedRewardTokenAddress).balanceOf(address(this)) < _tokensToBeSwapped) {
            return;
        }
    
        IERC20(trustedRewardTokenAddress).safeApprove(address(uniswapRouterV2), 0);
        IERC20(trustedRewardTokenAddress).safeApprove(address(uniswapRouterV2), _tokensToBeSwapped);
    
        uint oldWethBalance = IERC20(uniswapRouterV2.WETH()).balanceOf(address(this));
        
        uniswapRouterV2.swapExactTokensForTokens(_tokensToBeSwapped, _amountOutMin_attemptSwap, SWAP_PATH, address(this), _deadline);
    
        uint newWethBalance = IERC20(uniswapRouterV2.WETH()).balanceOf(address(this));
        uint wethReceived = newWethBalance.sub(oldWethBalance);
        
        if (wethReceived > 0) {
            distributeDivsEth(wethReceived);    
        }

        lastSwapExecutionTime = now;
    }
    
    // Owner is supposed to be a Governance Contract
    function disburseRewardTokens() public onlyOwner {
        require(now.sub(lastBurnOrTokenDistributeTime) > burnOrDisburseTokensPeriod, "Recently executed, Please wait!");
        
        // force reserves to match balances
        uniswapV2Pair.sync();
        
        uint maxSwappableAmount = getMaxSwappableAmount();
        
        uint _tokensToBeDisbursed = tokensToBeDisbursedOrBurnt;
        uint _tokensToBeBurnt;
        
        if (maxSwappableAmount < _tokensToBeDisbursed) {
            _tokensToBeBurnt = _tokensToBeDisbursed.sub(maxSwappableAmount);
            _tokensToBeDisbursed = maxSwappableAmount;
        }
        
        distributeDivs(_tokensToBeDisbursed);
        if (_tokensToBeBurnt > 0) {
            IERC20(trustedRewardTokenAddress).safeTransfer(BURN_ADDRESS, _tokensToBeBurnt);
        }
        tokensToBeDisbursedOrBurnt = 0;
        lastBurnOrTokenDistributeTime = now;
    }
    
    // Owner is suposed to be a Governance Contract
    function burnRewardTokens() public onlyOwner {
        require(now.sub(lastBurnOrTokenDistributeTime) > burnOrDisburseTokensPeriod, "Recently executed, Please wait!");
        IERC20(trustedRewardTokenAddress).safeTransfer(BURN_ADDRESS, tokensToBeDisbursedOrBurnt);
        tokensToBeDisbursedOrBurnt = 0;
        lastBurnOrTokenDistributeTime = now;
    }
    
    // get token amount which has a max price impact according to MAGIC_NUMBER for sells
    // !!IMPORTANT!! => Any functions using return value from this
    // MUST call `sync` on the pair before calling this function!
    function getMaxSwappableAmount() public view returns (uint) {
        uint tokensAvailable = IERC20(trustedRewardTokenAddress).balanceOf(trustedDepositTokenAddress);
        uint maxSwappableAmount = tokensAvailable.mul(MAGIC_NUMBER).div(1e18);
        return maxSwappableAmount;
    }

    // view function to calculate amount of DYP pending to be allocated since `lastDisburseTime` 
    function getPendingDisbursement() public view returns (uint) {
        uint timeDiff;
        uint _now = now;
        uint _stakingEndTime = contractDeployTime.add(disburseDuration);
        if (_now > _stakingEndTime) {
            _now = _stakingEndTime;
        }
        if (lastDisburseTime >= _now) {
            timeDiff = 0;
        } else {
            timeDiff = _now.sub(lastDisburseTime);
        }

        uint pendingDisburse = disburseAmount
                                    .mul(disbursePercentX100)
                                    .mul(timeDiff)
                                    .div(disburseDuration)
                                    .div(10000);
        return pendingDisburse;
    }

    // view function to get depositors list
    function getDepositorsList(uint startIndex, uint endIndex)
        public
        view
        returns (address[] memory stakers,
            uint[] memory stakingTimestamps,
            uint[] memory lastClaimedTimeStamps,
            uint[] memory stakedTokens) {
        require (startIndex < endIndex);

        uint length = endIndex.sub(startIndex);
        address[] memory _stakers = new address[](length);
        uint[] memory _stakingTimestamps = new uint[](length);
        uint[] memory _lastClaimedTimeStamps = new uint[](length);
        uint[] memory _stakedTokens = new uint[](length);

        for (uint i = startIndex; i < endIndex; i = i.add(1)) {
            address staker = holders.at(i);
            uint listIndex = i.sub(startIndex);
            _stakers[listIndex] = staker;
            _stakingTimestamps[listIndex] = depositTime[staker];
            _lastClaimedTimeStamps[listIndex] = lastClaimedTime[staker];
            _stakedTokens[listIndex] = depositedTokens[staker];
        }

        return (_stakers, _stakingTimestamps, _lastClaimedTimeStamps, _stakedTokens);
    }


    // admin can claim any tokens left in the contract after it expires or during emergency
    function claimAnyToken(address token, address recipient, uint amount) external onlyOwner {
        require(recipient != address(0), "Invalid Recipient");
        require(now > adminClaimableTime, "Contract not expired yet!");
        if (token == address(0)) {
            address payable _recipient = payable(recipient);
            _recipient.transfer(amount);
            return;
        }
        IERC20(token).safeTransfer(recipient, amount);
    }
}