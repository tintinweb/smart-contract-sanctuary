/*

                                                                          
   osssssssssssso+-         +sssssssssssso+-       -ssss+          `sssso` 
   mMMMMMMMMMMMMMMMNy.      hMMMMMMMMMMMMMMMNs`     :mMMMh`       :mMMMy`  
   mMMMy//////+oymMMMN:     hMMMy///////+yNMMMd      .hMMMm:     oNMMN+    
   mMMMo         `hMMMm     hMMMo         :MMMM-       +NMMNo  .hNMMd-     
   mMMMo          /MMMM`    hMMMo         /MMMm`        -dMMNh/mMMNs`      
   mMMMo         .hMMMh     hMMMy///////ohNMNh-          `yNMMNMMm/        
   mMMMh+++++++ohmMMNh.     hMMMNNNNNNNMMMMNy:`           `yMMMMN:         
   mMMMMMMMMMMMMMNmy/`      hMMMhooooooosyhNMNd/         `sNMMMMMm/        
   mMMMdsssssmMMMd-         hMMMo         `-mMMN:       -dMMNy+mMMNs`      
   mMMMo     -hNMMd:        hMMMo          `dMMMs     `+mMMNo` -dMMMd-     
   mMMMo      `oNMMNo`      hMMMs........-/yNMMN:    .yNMMd:    `sNMMm+    
   mMMMo        :mMMMh.     hMMMNmmmmmmNNNMMMNd/    :mMMNy.       /mMMNy`  
   hmmm+         .hmmmd-    ymmmmmmmmmmmmmdyo:`    +mmmm+          -dmmmh. 



                                presents...


    ____             __        __     ____                 
   / __ \____  _____/ /_____  / /_   / __ \_________  ____ 
  / /_/ / __ \/ ___/ //_/ _ \/ __/  / / / / ___/ __ \/ __ \
 / _, _/ /_/ / /__/ ,< /  __/ /_   / /_/ / /  / /_/ / /_/ /
/_/ |_|\____/\___/_/|_|\___/\__/  /_____/_/   \____/ .___/ 
                                                  /_/      

ROCKET DROP: the only farming solution that let's you create pools
to stake *any* kind of token for *any* kind of yield. Now an exclusive
RBX-Carbon product!

If you have any questions, feel free to join our tg group listed here. Anyone can
help answer questions, or just @ and admin they will get back to
you.

web: https://rbx.ae
tg: @rbxtoken

*/


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT



pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol



pragma solidity ^0.6.0;

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



pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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



pragma solidity ^0.6.0;




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

// File: @openzeppelin/contracts/utils/EnumerableSet.sol



pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/GSN/Context.sol



pragma solidity ^0.6.0;

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



pragma solidity ^0.6.0;

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
contract Ownable is Context {
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

// File: contracts/VendingMachine.sol


pragma solidity 0.6.12;


contract RocketDropV1point5 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 depositStamp;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;             // Address of LP token contract.
        uint256 lastRewardBlock;    // Last block number that ERC20s distribution occurs.
        uint256 accERC20PerShare;   // Accumulated ERC20s per share, times 1e36.
        IERC20 rewardToken;         // pool specific reward token.
        uint256 startBlock;         // pool specific block number when rewards start
        uint256 endBlock;           // pool specific block number when rewards end
        uint256 rewardPerBlock;     // pool specific reward per block
        uint256 paidOut;            // total paid out by pool
        uint256 tokensStaked;       // allows the same token to be staked across different pools
        uint256 gasAmount;          // eth fee charged on deposits and withdrawals (per pool)
        uint256 minStake;           // minimum tokens allowed to be staked
        uint256 maxStake;           // max tokens allowed to be staked
        address payable partnerTreasury;    // allows eth fee to be split with a partner on transfer
        uint256 partnerPercent;     // eth fee percent of partner split, 2 decimals (ie 10000 = 100.00%, 1002 = 10.02%)
    }

    // extra parameters for pools; optional
    struct PoolExtras {
        uint256 totalStakers;
        uint256 maxStakers;
        uint256 lpTokenFee;         // divide by 1000 ie 150 is 1.5%
        uint256 lockPeriod;         // time in blocks needed before withdrawal
        IERC20 accessToken;
        uint256 accessTokenMin;
        bool accessTokenRequired;
    }

    // default eth fee for deposits and withdrawals
    //uint256 public gasAmount = 2000000000000000;
    uint256 public gasAmount;
    address payable public treasury;
    IERC20 public accessToken;
    uint256 public accessTokenMin;
    bool public accessTokenRequired = false;

    IERC20 public rbxToken;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    PoolExtras[] public poolExtras;
    
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(IERC20 rbxTokenAddress) public {
        rbxToken = rbxTokenAddress;
        treasury = msg.sender;
    }

    function rewardPerBlock(uint index) external view returns (uint) {
        return poolInfo[index].rewardPerBlock;
    }

    // Number of LP pools
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function currentBlock() external view returns (uint256) {
        return block.number;
    }

    // Fund the farm, increase the end block
    function initialFund(uint256 _pid, uint256 _amount, uint256 _startBlock) public {
        require(poolInfo[_pid].startBlock == 0, "initialFund: initial funding already complete");
        IERC20 erc20;
        erc20 = poolInfo[_pid].rewardToken;

        uint256 startTokenBalance = erc20.balanceOf(address(this));
        erc20.safeTransferFrom(address(msg.sender), address(this), _amount);
        uint256 endTokenBalance = erc20.balanceOf(address(this));
        uint256 trueDepositedTokens = endTokenBalance.sub(startTokenBalance);

        poolInfo[_pid].lastRewardBlock = _startBlock;
        poolInfo[_pid].startBlock = _startBlock;
        poolInfo[_pid].endBlock = _startBlock.add(trueDepositedTokens.div(poolInfo[_pid].rewardPerBlock));
    }

    // Fund the farm, increase the end block
    function fundMore(uint256 _pid, uint256 _amount) public {
        require(block.number < poolInfo[_pid].endBlock, "fundMore: pool closed or use initialFund() first");
        IERC20 erc20;
        erc20 = poolInfo[_pid].rewardToken;

        uint256 startTokenBalance = erc20.balanceOf(address(this));
        erc20.safeTransferFrom(address(msg.sender), address(this), _amount);
        uint256 endTokenBalance = erc20.balanceOf(address(this));
        uint256 trueDepositedTokens = endTokenBalance.sub(startTokenBalance);

        poolInfo[_pid].endBlock += trueDepositedTokens.div(poolInfo[_pid].rewardPerBlock);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // rewards are calculated per pool, so you can add the same lpToken multiple times
    function add(IERC20 _lpToken, IERC20 _rewardToken, uint256 _rewardPerBlock, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        //###
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            lastRewardBlock: 0,
            accERC20PerShare: 0,
            rewardToken: _rewardToken,
            startBlock: 0,
            endBlock: 0,
            rewardPerBlock: _rewardPerBlock,
            paidOut: 0,
            tokensStaked: 0,
            gasAmount: gasAmount,   // defaults to global gas/eth fee
            minStake: 0,
            maxStake: ~uint256(0),
            partnerTreasury: treasury,
            partnerPercent: 0
        }));

        poolExtras.push(PoolExtras({
            totalStakers: 0,
            maxStakers: ~uint256(0),
            lpTokenFee: 0,
            lockPeriod: 0,
            accessTokenRequired: false,
            accessToken: IERC20(address(0)),
            accessTokenMin: 0
        }));
    }

    //####
    // Update the given pool's ERC20 reward per block. Can only be called by the owner.
    function set(uint256 _pid, uint256 _rewardPerBlock, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            updatePool(_pid);
        }
        poolInfo[_pid].rewardPerBlock = _rewardPerBlock;
        updatePool(_pid);
    }

    // Pool adjustment functions
    function minStake(uint256 _pid, uint256 _minStake) public onlyOwner {
        poolInfo[_pid].minStake = _minStake;
    }

    function maxStake(uint256 _pid, uint256 _maxStake) public onlyOwner {
        poolInfo[_pid].maxStake = _maxStake;
    }

    function maxStakersAdj(uint256 _pid, uint256 _maxStakers) public onlyOwner {
        poolExtras[_pid].maxStakers = _maxStakers;
    }

    function lpTokenFeeAdj(uint256 _pid, uint256 _lpTokenFee) public onlyOwner {
        poolExtras[_pid].lpTokenFee = _lpTokenFee;
    }

    function lockPeriodAdj(uint256 _pid, uint256 _lockPeriod) public onlyOwner {
        poolExtras[_pid].lockPeriod = _lockPeriod;
    }

    function poolAccessTokenReq(uint256 _pid, bool _accessTokenRequired) public onlyOwner {
        poolExtras[_pid].accessTokenRequired = _accessTokenRequired;
    }

    function poolAccessTokenAddy(uint256 _pid, IERC20 _accessToken) public onlyOwner {
        poolExtras[_pid].accessToken = _accessToken;
    }

    function poolAccessTokenMin(uint256 _pid, uint256 _accessTokenMin) public onlyOwner {
        poolExtras[_pid].accessTokenMin = _accessTokenMin;
    }
    // END Pool adjustment functions

    // View function to see deposited LP for a user.
    function deposited(uint256 _pid, address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        return user.amount;
    }

    // View function to see pending ERC20s for a user.
    function pending(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accERC20PerShare = pool.accERC20PerShare;
        
        uint256 lpSupply = pool.tokensStaked;

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 lastBlock = block.number < pool.endBlock ? block.number : pool.endBlock;
            uint256 nrOfBlocks = lastBlock.sub(pool.lastRewardBlock);
            uint256 erc20Reward = nrOfBlocks.mul(pool.rewardPerBlock);
            accERC20PerShare = accERC20PerShare.add(erc20Reward.mul(1e36).div(lpSupply));
        }

        return user.amount.mul(accERC20PerShare).div(1e36).sub(user.rewardDebt);
    }

    // View function for total reward the farm has yet to pay out.
    function totalPending(uint256 _pid) external view returns (uint256) {
        if (block.number <= poolInfo[_pid].startBlock) {
            return 0;
        }

        uint256 lastBlock = block.number < poolInfo[_pid].endBlock ? block.number : poolInfo[_pid].endBlock;
        return poolInfo[_pid].rewardPerBlock.mul(lastBlock - poolInfo[_pid].startBlock).sub(poolInfo[_pid].paidOut);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 lastBlock = block.number < pool.endBlock ? block.number : pool.endBlock;

        if (lastBlock <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.tokensStaked;
        if (lpSupply == 0) {
            pool.lastRewardBlock = lastBlock;
            return;
        }

        uint256 nrOfBlocks = lastBlock.sub(pool.lastRewardBlock);
        uint256 erc20Reward = nrOfBlocks.mul(pool.rewardPerBlock);

        pool.accERC20PerShare = pool.accERC20PerShare.add(erc20Reward.mul(1e36).div(lpSupply));
        pool.lastRewardBlock = lastBlock;
    }

    // Deposit LP tokens to VendingMachine for ERC20 allocation.
    function deposit(uint256 _pid, uint256 _amount) public payable {
        if(accessTokenRequired){
            require(accessToken.balanceOf(msg.sender) >= accessTokenMin, 'Must have minimum amount of access token!');
        }
        PoolExtras storage poolEx = poolExtras[_pid];

        if(poolEx.accessTokenRequired){
            require(poolEx.accessToken.balanceOf(msg.sender) >= poolEx.accessTokenMin, 'Must have minimum amount of access token!');
        }
        require(poolEx.totalStakers < poolEx.maxStakers, 'Max stakers reached!');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 poolGasAmount = pool.gasAmount;
        require(msg.value >= poolGasAmount, 'Correct gas amount must be sent!');
        require(_amount >= pool.minStake && (_amount.add(user.amount)) <= pool.maxStake, 'Min/Max stake required!');

        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pendingAmount = user.amount.mul(pool.accERC20PerShare).div(1e36).sub(user.rewardDebt);
            if(pendingAmount > 0)
                erc20Transfer(msg.sender, _pid, pendingAmount);
        }

        uint256 startTokenBalance = pool.lpToken.balanceOf(address(this));
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        uint256 endTokenBalance = pool.lpToken.balanceOf(address(this));
        uint256 depositFee = poolEx.lpTokenFee.mul(endTokenBalance).div(1000);
        uint256 trueDepositedTokens = endTokenBalance.sub(startTokenBalance).sub(depositFee);

        user.amount = user.amount.add(trueDepositedTokens);
        user.depositStamp = block.number;
        pool.tokensStaked = pool.tokensStaked.add(trueDepositedTokens);
        user.rewardDebt = user.amount.mul(pool.accERC20PerShare).div(1e36);
        
        // remit eth fee according to partner status 
        if (pool.partnerPercent == 0) {
            treasury.transfer(msg.value);
        } else {
            uint256 totalAmount = msg.value;
            uint256 partnerAmount = totalAmount.mul(pool.partnerPercent).div(10000);
            uint256 treasuryAmount = totalAmount.sub(partnerAmount);
            treasury.transfer(treasuryAmount);
            pool.partnerTreasury.transfer(partnerAmount);
        }
        
        poolEx.totalStakers = poolEx.totalStakers.add(1);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from VendingMachine.
    function withdraw(uint256 _pid, uint256 _amount) public payable {
        if(accessTokenRequired){
            require(accessToken.balanceOf(msg.sender) >= accessTokenMin, 'Must have minimum amount of access token!');
        }
        PoolExtras storage poolEx = poolExtras[_pid];
        PoolInfo storage pool = poolInfo[_pid];
        uint256 poolGasAmount = pool.gasAmount;
        require(msg.value >= poolGasAmount, 'Correct gas amount must be sent!');

        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: can't withdraw more than deposit");
        updatePool(_pid);
        uint256 pendingAmount = user.amount.mul(pool.accERC20PerShare).div(1e36).sub(user.rewardDebt);

        if(pendingAmount > 0)
            erc20Transfer(msg.sender, _pid, pendingAmount);
            
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accERC20PerShare).div(1e36);
        
        if(_amount > 0){
            require(user.depositStamp.add(poolEx.lockPeriod) <= block.number,'Lock period not fulfilled');
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.tokensStaked = pool.tokensStaked.sub(_amount);
        }

        // remit eth fee according to partner status 
        if (pool.partnerPercent == 0) {
            treasury.transfer(msg.value);
        } else {
            uint256 totalAmount = msg.value;
            uint256 partnerAmount = totalAmount.mul(pool.partnerPercent).div(10000);
            uint256 treasuryAmount = totalAmount.sub(partnerAmount);
            treasury.transfer(treasuryAmount);
            pool.partnerTreasury.transfer(partnerAmount);
        }

        if(user.amount == 0){
            poolEx.totalStakers = poolEx.totalStakers.sub(1);
        }
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        PoolExtras storage poolEx = poolExtras[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        pool.tokensStaked = pool.tokensStaked.sub(user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        poolEx.totalStakers = poolEx.totalStakers.sub(1);
    }

    // Transfer ERC20 and update the required ERC20 to payout all rewards
    function erc20Transfer(address _to, uint256 _pid, uint256 _amount) internal {
        IERC20 erc20;
        erc20 = poolInfo[_pid].rewardToken;
        erc20.transfer(_to, _amount);
        poolInfo[_pid].paidOut += _amount;
    }
    
    // adjust default/global gas fee
    function adjustGasGlobal(uint256 newgas) public onlyOwner {
        gasAmount = newgas;
    }

    // access token settings
    function changeAccessToken(IERC20 newToken) public onlyOwner {
        accessToken = newToken;
    }
    function changeAccessMin(uint256 newMin) public onlyOwner {
        accessTokenMin = newMin;
    }
    function changeAccessTknReq(bool setting) public onlyOwner {
        accessTokenRequired = setting;
    }

    // adjust pool gas/eth fee
    function adjustPoolGas(uint256 _pid, uint256 newgas) public onlyOwner {
        poolInfo[_pid].gasAmount = newgas;
    }

    function adjustBlockReward(uint256 _pid, uint256 newReward) public onlyOwner {
        poolInfo[_pid].rewardPerBlock = newReward;
    }

    function adjustEndBlock(uint256 _pid, uint256 newBlock) public onlyOwner {
        poolInfo[_pid].endBlock = newBlock;
    }

    function adjustLastBlock(uint256 _pid, uint256 newBlock) public onlyOwner {
        poolInfo[_pid].lastRewardBlock = newBlock;
    }
    
    function withdrawAnyToken(address _recipient, address _ERC20address, uint256 _amount) public onlyOwner returns(bool) {
        IERC20(_ERC20address).transfer(_recipient, _amount); //use of the _ERC20 traditional transfer
        return true;
    }

    // change global treasury
    function changeTreasury(address payable newTreasury) public onlyOwner {
        treasury = newTreasury;
    }

    function changePartnerTreasury(uint256 _pid, address payable newTreasury) public onlyOwner {
        poolInfo[_pid].partnerTreasury = newTreasury;
    }
    
    function changePartnerPercent(uint256 _pid, uint256 newPercent) public onlyOwner {
        poolInfo[_pid].partnerPercent = newPercent;
    }

    function transfer() public onlyOwner {
        treasury.transfer(address(this).balance);
    }
}