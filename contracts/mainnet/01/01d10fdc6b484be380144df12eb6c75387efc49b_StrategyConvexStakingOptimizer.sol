/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// Sources flattened with hardhat v2.0.3 https://hardhat.org

// File deps/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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


// File deps/@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol



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
library SafeMathUpgradeable {
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


// File deps/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol



pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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


// File deps/@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol



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
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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


// File deps/@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol



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
library EnumerableSetUpgradeable {
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


// File interfaces/uniswap/IUniswapRouterV2.sol


pragma solidity >=0.5.0 <0.8.0;

interface IUniswapRouterV2 {
    function factory() external view returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}


// File interfaces/badger/IBadgerGeyser.sol




pragma solidity >=0.5.0 <0.8.0;

interface IBadgerGeyser {
    function stake(address) external returns (uint256);

    function signalTokenLock(
        address token,
        uint256 amount,
        uint256 durationSec,
        uint256 startTime
    ) external;

    function modifyTokenLock(
        address token,
        uint256 index,
        uint256 amount,
        uint256 durationSec,
        uint256 startTime
    ) external;
}


// File interfaces/erc20/IERC20.sol



pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);

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


// File interfaces/sushi/ISushiChef.sol



pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// Info of each pool.
struct PoolInfo {
    IERC20 lpToken; // Address of LP token contract.
    uint256 allocPoint; // How many allocation points assigned to this pool. SUSHIs to distribute per block.
    uint256 lastRewardBlock; // Last block number that SUSHIs distribution occurs.
    uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
}

interface ISushiChef {
    // ===== Write =====

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function add(
        uint256 _allocPoint,
        address _lpToken,
        bool _withUpdate
    ) external;

    function updatePool(uint256 _pid) external;

    // ===== Read =====

    function totalAllocPoint() external view returns (uint256);

    function poolLength() external view returns (uint256);

    function owner() external view returns (address);

    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);

    function pendingSushi(uint256 _pid, address _user) external view returns (uint256);

    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
}


// File interfaces/uniswap/IUniswapPair.sol

pragma solidity ^0.6.0;

interface IUniswapPair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}


// File interfaces/sushi/IxSushi.sol

pragma solidity ^0.6.0;

interface IxSushi {
    function enter(uint256 _amount) external;

    function leave(uint256 _shares) external;
}


// File interfaces/badger/IController.sol


pragma solidity >=0.5.0 <0.8.0;

interface IController {
    function withdraw(address, uint256) external;
    function withdrawAll(address) external;

    function strategies(address) external view returns (address);

    function approvedStrategies(address, address) external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function earn(address, uint256) external;

    function approveStrategy(address, address) external;

    function setStrategy(address, address) external;

    function setVault(address, address) external;

    function want(address) external view returns (address);

    function rewards() external view returns (address);

    function vaults(address) external view returns (address);
}


// File interfaces/badger/IMintr.sol




pragma solidity >=0.5.0 <0.8.0;

interface IMintr {
    function mint(address) external;
}


// File interfaces/badger/IStrategy.sol




pragma solidity >=0.5.0 <0.8.0;

interface IStrategy {
    function want() external view returns (address);

    function deposit() external;

    // NOTE: must exclude any tokens used in the yield
    // Controller role - withdraw should return to Controller
    function withdrawOther(address) external returns (uint256 balance);

    // Controller | Vault role - withdraw should always return to Vault
    function withdraw(uint256) external;

    // Controller | Vault role - withdraw should always return to Vault
    function withdrawAll() external returns (uint256);

    function balanceOf() external view returns (uint256);

    function getName() external pure returns (string memory);

    function setStrategist(address _strategist) external;

    function setWithdrawalFee(uint256 _withdrawalFee) external;

    function setPerformanceFeeStrategist(uint256 _performanceFeeStrategist) external;

    function setPerformanceFeeGovernance(uint256 _performanceFeeGovernance) external;

    function setGovernance(address _governance) external;

    function setController(address _controller) external;

    function tend() external;

    function harvest() external;
}


// File interfaces/badger/ISettV4.sol


pragma solidity >=0.5.0 <0.8.0;

interface ISettV4 {
    function token() external view returns (address);
    function keeper() external view returns (address);

    function deposit(uint256) external;

    function depositFor(address, uint256) external;

    function depositAll() external;

    function withdraw(uint256) external;

    function withdrawAll() external;

    function earn() external;

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function claimInsurance() external; // NOTE: Only yDelegatedVault implements this

    function getPricePerFullShare() external view returns (uint256);
}


// File interfaces/convex/IBooster.sol

pragma solidity >=0.6.0;
interface IBooster {
    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        address stash;
        bool shutdown;
    }

    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns(bool);
    function depositAll(uint256 _pid, bool _stake) external returns(bool);
    function withdraw(uint256 _pid, uint256 _amount) external returns(bool);
    function withdrawAll(uint256 _pid) external returns(bool);
}


// File interfaces/convex/CrvDepositor.sol


pragma solidity >=0.6.0;
interface CrvDepositor {
    //deposit crv for cvxCrv
    //can locking immediately or defer locking to someone else by paying a fee.
    //while users can choose to lock or defer, this is mostly in place so that
    //the cvx reward contract isnt costly to claim rewards
    function deposit(uint256 _amount, bool _lock) external;
}


// File interfaces/convex/IBaseRewardsPool.sol



pragma solidity ^0.6.0;
interface IBaseRewardsPool {
    //balance
    function balanceOf(address _account) external view returns(uint256);
    //withdraw to a convex tokenized deposit
    function withdraw(uint256 _amount, bool _claim) external returns(bool);
    //withdraw directly to curve LP token
    function withdrawAndUnwrap(uint256 _amount, bool _claim) external returns(bool);
    //claim rewards
    function getReward() external returns(bool);
    //stake a convex tokenized deposit
    function stake(uint256 _amount) external returns(bool);
    //stake a convex tokenized deposit for another address(transfering ownership)
    function stakeFor(address _account,uint256 _amount) external returns(bool);
    function getReward(address _account, bool _claimExtras) external returns (bool);
    function rewards(address _account) external view returns (uint256);
    function earned(address _account) external view returns (uint256);
}


// File interfaces/convex/ICvxRewardsPool.sol



pragma solidity ^0.6.0;
interface ICvxRewardsPool {
    //balance
    function balanceOf(address _account) external view returns(uint256);
    //withdraw to a convex tokenized deposit
    function withdraw(uint256 _amount, bool _claim) external;
    //withdraw directly to curve LP token
    function withdrawAndUnwrap(uint256 _amount, bool _claim) external returns(bool);
    //claim rewards
    function getReward(bool _stake) external;
    //stake a convex tokenized deposit
    function stake(uint256 _amount) external;
    //stake a convex tokenized deposit for another address(transfering ownership)
    function stakeFor(address _account,uint256 _amount) external returns(bool);
    function rewards(address _account) external view returns (uint256);
    function earned(address _account) external view returns (uint256);
}


// File deps/@openzeppelin/contracts-upgradeable/proxy/Initializable.sol



pragma solidity >=0.4.24 <0.7.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}


// File deps/@openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol



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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


// File deps/@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol



pragma solidity ^0.6.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}


// File interfaces/uniswap/IUniswapV2Factory.sol


pragma solidity >=0.5.0 <0.8.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}


// File contracts/badger-sett/SettAccessControl.sol


pragma solidity ^0.6.11;

/*
    Common base for permissioned roles throughout Sett ecosystem
*/
contract SettAccessControl is Initializable {
    address public governance;
    address public strategist;
    address public keeper;

    // ===== MODIFIERS =====
    function _onlyGovernance() internal view {
        require(msg.sender == governance, "onlyGovernance");
    }

    function _onlyGovernanceOrStrategist() internal view {
        require(msg.sender == strategist || msg.sender == governance, "onlyGovernanceOrStrategist");
    }

    function _onlyAuthorizedActors() internal view {
        require(msg.sender == keeper || msg.sender == governance, "onlyAuthorizedActors");
    }

    // ===== PERMISSIONED ACTIONS =====

    /// @notice Change strategist address
    /// @notice Can only be changed by governance itself
    function setStrategist(address _strategist) external {
        _onlyGovernance();
        strategist = _strategist;
    }

    /// @notice Change keeper address
    /// @notice Can only be changed by governance itself
    function setKeeper(address _keeper) external {
        _onlyGovernance();
        keeper = _keeper;
    }

    /// @notice Change governance address
    /// @notice Can only be changed by governance itself
    function setGovernance(address _governance) public {
        _onlyGovernance();
        governance = _governance;
    }

    uint256[50] private __gap;
}


// File deps/@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol



pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


// File contracts/badger-sett/strategies/BaseStrategy.sol



pragma solidity ^0.6.11;










/*
    ===== Badger Base Strategy =====
    Common base class for all Sett strategies

    Changelog
    V1.1
    - Verify amount unrolled from strategy positions on withdraw() is within a threshold relative to the requested amount as a sanity check
    - Add version number which is displayed with baseStrategyVersion(). If a strategy does not implement this function, it can be assumed to be 1.0

    V1.2
    - Remove idle want handling from base withdraw() function. This should be handled as the strategy sees fit in _withdrawSome()
*/
abstract contract BaseStrategy is PausableUpgradeable, SettAccessControl {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    event Withdraw(uint256 amount);
    event WithdrawAll(uint256 balance);
    event WithdrawOther(address token, uint256 amount);
    event SetStrategist(address strategist);
    event SetGovernance(address governance);
    event SetController(address controller);
    event SetWithdrawalFee(uint256 withdrawalFee);
    event SetPerformanceFeeStrategist(uint256 performanceFeeStrategist);
    event SetPerformanceFeeGovernance(uint256 performanceFeeGovernance);
    event Harvest(uint256 harvested, uint256 indexed blockNumber);
    event Tend(uint256 tended);

    address public want; // Want: Curve.fi renBTC/wBTC (crvRenWBTC) LP token

    uint256 public performanceFeeGovernance;
    uint256 public performanceFeeStrategist;
    uint256 public withdrawalFee;

    uint256 public constant MAX_FEE = 10000;

    address public controller;
    address public guardian;

    uint256 public withdrawalMaxDeviationThreshold;

    function __BaseStrategy_init(
        address _governance,
        address _strategist,
        address _controller,
        address _keeper,
        address _guardian
    ) public initializer whenNotPaused {
        __Pausable_init();
        governance = _governance;
        strategist = _strategist;
        keeper = _keeper;
        controller = _controller;
        guardian = _guardian;
        withdrawalMaxDeviationThreshold = 50;
    }

    // ===== Modifiers =====

    function _onlyController() internal view {
        require(msg.sender == controller, "onlyController");
    }

    function _onlyAuthorizedActorsOrController() internal view {
        require(msg.sender == keeper || msg.sender == governance || msg.sender == controller, "onlyAuthorizedActorsOrController");
    }

    function _onlyAuthorizedPausers() internal view {
        require(msg.sender == guardian || msg.sender == governance, "onlyPausers");
    }

    /// ===== View Functions =====
    function baseStrategyVersion() public view returns (string memory) {
        return "1.2";
    }

    /// @notice Get the balance of want held idle in the Strategy
    function balanceOfWant() public view returns (uint256) {
        return IERC20Upgradeable(want).balanceOf(address(this));
    }

    /// @notice Get the total balance of want realized in the strategy, whether idle or active in Strategy positions.
    function balanceOf() public virtual view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function isTendable() public virtual view returns (bool) {
        return false;
    }
    
    function isProtectedToken(address token) public view returns (bool) {
        address[] memory protectedTokens = getProtectedTokens();
        for (uint256 i = 0; i < protectedTokens.length; i++) {
            if (token == protectedTokens[i]) {
                return true;
            }
        }
        return false;
    }
    
    /// ===== Permissioned Actions: Governance =====

    function setGuardian(address _guardian) external {
        _onlyGovernance();
        guardian = _guardian;
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external {
        _onlyGovernance();
        require(_withdrawalFee <= MAX_FEE, "base-strategy/excessive-withdrawal-fee");
        withdrawalFee = _withdrawalFee;
    }

    function setPerformanceFeeStrategist(uint256 _performanceFeeStrategist) external {
        _onlyGovernance();
        require(_performanceFeeStrategist <= MAX_FEE, "base-strategy/excessive-strategist-performance-fee");
        performanceFeeStrategist = _performanceFeeStrategist;
    }

    function setPerformanceFeeGovernance(uint256 _performanceFeeGovernance) external {
        _onlyGovernance();
        require(_performanceFeeGovernance <= MAX_FEE, "base-strategy/excessive-governance-performance-fee");
        performanceFeeGovernance = _performanceFeeGovernance;
    }

    function setController(address _controller) external {
        _onlyGovernance();
        controller = _controller;
    }

    function setWithdrawalMaxDeviationThreshold(uint256 _threshold) external {
        _onlyGovernance();
        require(_threshold <= MAX_FEE, "base-strategy/excessive-max-deviation-threshold");
        withdrawalMaxDeviationThreshold = _threshold;
    }

    function deposit() public virtual whenNotPaused {
        _onlyAuthorizedActorsOrController();
        uint256 _want = IERC20Upgradeable(want).balanceOf(address(this));
        if (_want > 0) {
            _deposit(_want);
        }
        _postDeposit();
    }

    // ===== Permissioned Actions: Controller =====

    /// @notice Controller-only function to Withdraw partial funds, normally used with a vault withdrawal
    function withdrawAll() external virtual whenNotPaused returns (uint256 balance) {
        _onlyController();

        _withdrawAll();

        _transferToVault(IERC20Upgradeable(want).balanceOf(address(this)));
    }

    /// @notice Withdraw partial funds from the strategy, unrolling from strategy positions as necessary
    /// @notice Processes withdrawal fee if present
    /// @dev If it fails to recover sufficient funds (defined by withdrawalMaxDeviationThreshold), the withdrawal should fail so that this unexpected behavior can be investigated
    function withdraw(uint256 _amount) external virtual whenNotPaused {
        _onlyController();

        // Withdraw from strategy positions, typically taking from any idle want first.
        _withdrawSome(_amount);
        uint256 _postWithdraw = IERC20Upgradeable(want).balanceOf(address(this));

        // Sanity check: Ensure we were able to retrieve sufficent want from strategy positions
        // If we end up with less than the amount requested, make sure it does not deviate beyond a maximum threshold
        if (_postWithdraw < _amount) {
            uint256 diff = _diff(_amount, _postWithdraw);

            // Require that difference between expected and actual values is less than the deviation threshold percentage
            require(diff <= _amount.mul(withdrawalMaxDeviationThreshold).div(MAX_FEE), "base-strategy/withdraw-exceed-max-deviation-threshold");
        }

        // Return the amount actually withdrawn if less than amount requested
        uint256 _toWithdraw = MathUpgradeable.min(_postWithdraw, _amount);

        // Process withdrawal fee
        uint256 _fee = _processWithdrawalFee(_toWithdraw);

        // Transfer remaining to Vault to handle withdrawal
        _transferToVault(_toWithdraw.sub(_fee));
    }

    // NOTE: must exclude any tokens used in the yield
    // Controller role - withdraw should return to Controller
    function withdrawOther(address _asset) external virtual whenNotPaused returns (uint256 balance) {
        _onlyController();
        _onlyNotProtectedTokens(_asset);

        balance = IERC20Upgradeable(_asset).balanceOf(address(this));
        IERC20Upgradeable(_asset).safeTransfer(controller, balance);
    }

    /// ===== Permissioned Actions: Authoized Contract Pausers =====

    function pause() external {
        _onlyAuthorizedPausers();
        _pause();
    }

    function unpause() external {
        _onlyGovernance();
        _unpause();
    }

    /// ===== Internal Helper Functions =====

    /// @notice If withdrawal fee is active, take the appropriate amount from the given value and transfer to rewards recipient
    /// @return The withdrawal fee that was taken
    function _processWithdrawalFee(uint256 _amount) internal returns (uint256) {
        if (withdrawalFee == 0) {
            return 0;
        }

        uint256 fee = _amount.mul(withdrawalFee).div(MAX_FEE);
        IERC20Upgradeable(want).safeTransfer(IController(controller).rewards(), fee);
        return fee;
    }

    /// @dev Helper function to process an arbitrary fee
    /// @dev If the fee is active, transfers a given portion in basis points of the specified value to the recipient
    /// @return The fee that was taken
    function _processFee(
        address token,
        uint256 amount,
        uint256 feeBps,
        address recipient
    ) internal returns (uint256) {
        if (feeBps == 0) {
            return 0;
        }
        uint256 fee = amount.mul(feeBps).div(MAX_FEE);
        IERC20Upgradeable(token).safeTransfer(recipient, fee);
        return fee;
    }

    function _transferToVault(uint256 _amount) internal {
        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20Upgradeable(want).safeTransfer(_vault, _amount);
    }
    
    /// @notice Utility function to diff two numbers, expects higher value in first position
    function _diff(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "diff/expected-higher-number-in-first-position");
        return a.sub(b);
    }

    // ===== Abstract Functions: To be implemented by specific Strategies =====

    /// @dev Internal deposit logic to be implemented by Stratgies
    function _deposit(uint256 _want) internal virtual;

    function _postDeposit() internal virtual {
        //no-op by default
    }

    /// @notice Specify tokens used in yield process, should not be available to withdraw via withdrawOther()
    function _onlyNotProtectedTokens(address _asset) internal virtual;

    function getProtectedTokens() public virtual view returns (address[] memory) {
        return new address[](0);
    }

    /// @dev Internal logic for strategy migration. Should exit positions as efficiently as possible
    function _withdrawAll() internal virtual;

    /// @dev Internal logic for partial withdrawals. Should exit positions as efficiently as possible.
    /// @dev The withdraw() function shell automatically uses idle want in the strategy before attempting to withdraw more using this
    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);

    /// @dev Realize returns from positions
    /// @dev Returns can be reinvested into positions, or distributed in another fashion
    /// @dev Performance fees should also be implemented in this function
    /// @dev Override function stub is removed as each strategy can have it's own return signature for STATICCALL
    // function harvest() external virtual;

    /// @dev User-friendly name for this strategy for purposes of convenient reading
    function getName() external virtual pure returns (string memory);

    /// @dev Balance of want currently held in strategy positions
    function balanceOfPool() public virtual view returns (uint256);

    uint256[49] private __gap;
}


// File contracts/badger-sett/strategies/BaseStrategySwapper.sol



pragma solidity ^0.6.11;










/*
    Expands swapping functionality over base strategy
    - ETH in and ETH out Variants
    - Sushiswap support in addition to Uniswap
*/
abstract contract BaseStrategyMultiSwapper is BaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    address public constant uniswap = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap Dex
    address public constant sushiswap = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F; // Sushiswap router

    /// @notice Swap specified balance of given token on Uniswap with given path
    function _swap_uniswap(
        address startToken,
        uint256 balance,
        address[] memory path
    ) internal {
        _safeApproveHelper(startToken, uniswap, balance);
        IUniswapRouterV2(uniswap).swapExactTokensForTokens(balance, 0, path, address(this), now);
    }

    /// @dev Reset approval and approve exact amount
    function _safeApproveHelper(
        address token,
        address recipient,
        uint256 amount
    ) internal {
        IERC20Upgradeable(token).safeApprove(recipient, 0);
        IERC20Upgradeable(token).safeApprove(recipient, amount);
    }

    /// @notice Swap specified balance of given token on Uniswap with given path
    function _swap_sushiswap(
        address startToken,
        uint256 balance,
        address[] memory path
    ) internal {
        _safeApproveHelper(startToken, sushiswap, balance);
        IUniswapRouterV2(sushiswap).swapExactTokensForTokens(balance, 0, path, address(this), now);
    }

    function _swapEthIn_uniswap(uint256 balance, address[] memory path) internal {
        IUniswapRouterV2(uniswap).swapExactETHForTokens{value: balance}(0, path, address(this), now);
    }

    function _swapEthIn_sushiswap(uint256 balance, address[] memory path) internal {
        IUniswapRouterV2(sushiswap).swapExactETHForTokens{value: balance}(0, path, address(this), now);
    }

    function _swapEthOut_uniswap(
        address startToken,
        uint256 balance,
        address[] memory path
    ) internal {
        _safeApproveHelper(startToken, uniswap, balance);
        IUniswapRouterV2(uniswap).swapExactTokensForETH(balance, 0, path, address(this), now);
    }

    function _swapEthOut_sushiswap(
        address startToken,
        uint256 balance,
        address[] memory path
    ) internal {
        _safeApproveHelper(startToken, sushiswap, balance);
        IUniswapRouterV2(sushiswap).swapExactTokensForETH(balance, 0, path, address(this), now);
    }

    function _get_uni_pair(address token0, address token1) internal view returns (address) {
        address factory = IUniswapRouterV2(uniswap).factory();
        return IUniswapV2Factory(factory).getPair(token0, token1);
    }

    function _get_sushi_pair(address token0, address token1) internal view returns (address) { 
        address factory = IUniswapRouterV2(sushiswap).factory();
        return IUniswapV2Factory(factory).getPair(token0, token1);
    }

    /// @notice Swap specified balance of given token on Uniswap with given path
    function _swap(
        address startToken,
        uint256 balance,
        address[] memory path
    ) internal {
        _safeApproveHelper(startToken, uniswap, balance);
        IUniswapRouterV2(uniswap).swapExactTokensForTokens(balance, 0, path, address(this), now);
    }

    function _swapEthIn(uint256 balance, address[] memory path) internal {
        IUniswapRouterV2(uniswap).swapExactETHForTokens{value: balance}(0, path, address(this), now);
    }

    function _swapEthOut(
        address startToken,
        uint256 balance,
        address[] memory path
    ) internal {
        _safeApproveHelper(startToken, uniswap, balance);
        IUniswapRouterV2(uniswap).swapExactTokensForETH(balance, 0, path, address(this), now);
    }

    /// @notice Add liquidity to uniswap for specified token pair, utilizing the maximum balance possible
    function _add_max_liquidity_uniswap(address token0, address token1) internal virtual {
        uint256 _token0Balance = IERC20Upgradeable(token0).balanceOf(address(this));
        uint256 _token1Balance = IERC20Upgradeable(token1).balanceOf(address(this));

        _safeApproveHelper(token0, uniswap, _token0Balance);
        _safeApproveHelper(token1, uniswap, _token1Balance);

        IUniswapRouterV2(uniswap).addLiquidity(token0, token1, _token0Balance, _token1Balance, 0, 0, address(this), block.timestamp);
    }

    /// @notice Add liquidity to uniswap for specified token pair, utilizing the maximum balance possible
    function _add_max_liquidity_sushiswap(address token0, address token1) internal {
        uint256 _token0Balance = IERC20Upgradeable(token0).balanceOf(address(this));
        uint256 _token1Balance = IERC20Upgradeable(token1).balanceOf(address(this));

        _safeApproveHelper(token0, sushiswap, _token0Balance);
        _safeApproveHelper(token1, sushiswap, _token1Balance);

        IUniswapRouterV2(sushiswap).addLiquidity(token0, token1, _token0Balance, _token1Balance, 0, 0, address(this), block.timestamp);
    }

    function _add_max_liquidity_eth_sushiswap(address token0) internal {
        uint256 _token0Balance = IERC20Upgradeable(token0).balanceOf(address(this));
        uint256 _ethBalance = address(this).balance;

        _safeApproveHelper(token0, sushiswap, _token0Balance);
        IUniswapRouterV2(sushiswap).addLiquidityETH{ value: address(this).balance }(token0, _token0Balance, 0, 0, address(this), block.timestamp);
    }

    uint256[50] private __gap;
}


// File interfaces/curve/ICurveFi.sol


pragma solidity >=0.5.0 <0.8.0;

interface ICurveFi {
    function get_virtual_price() external view returns (uint256 out);

    function add_liquidity(
        // renbtc/tbtc pool
        uint256[2] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        // sBTC pool
        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        // bUSD pool
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external returns (uint256 out);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external returns (uint256 out);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        uint256 deadline
    ) external;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        uint256 deadline
    ) external;

    function remove_liquidity(
        uint256 _amount,
        uint256 deadline,
        uint256[2] calldata min_amounts
    ) external;

    function remove_liquidity_imbalance(uint256[2] calldata amounts, uint256 deadline) external;

    function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[3] calldata amounts) external;

    function remove_liquidity_imbalance(uint256[4] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata amounts) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external;

    function commit_new_parameters(
        int128 amplification,
        int128 new_fee,
        int128 new_admin_fee
    ) external;

    function apply_new_parameters() external;

    function revert_new_parameters() external;

    function commit_transfer_ownership(address _owner) external;

    function apply_transfer_ownership() external;

    function revert_transfer_ownership() external;

    function withdraw_admin_fees() external;

    function coins(int128 arg0) external returns (address out);

    function underlying_coins(int128 arg0) external returns (address out);

    function balances(int128 arg0) external returns (uint256 out);

    function A() external returns (int128 out);

    function fee() external returns (int128 out);

    function admin_fee() external returns (int128 out);

    function owner() external returns (address out);

    function admin_actions_deadline() external returns (uint256 out);

    function transfer_ownership_deadline() external returns (uint256 out);

    function future_A() external returns (int128 out);

    function future_fee() external returns (int128 out);

    function future_admin_fee() external returns (int128 out);

    function future_owner() external returns (address out);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 _i) external view returns (uint256 out);
}


// File contracts/badger-sett/libraries/BaseSwapper.sol



pragma solidity ^0.6.11;



/*
    Expands swapping functionality over base strategy
    - ETH in and ETH out Variants
    - Sushiswap support in addition to Uniswap
*/
contract BaseSwapper {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    /// @dev Reset approval and approve exact amount
    function _safeApproveHelper(
        address token,
        address recipient,
        uint256 amount
    ) internal {
        IERC20Upgradeable(token).safeApprove(recipient, 0);
        IERC20Upgradeable(token).safeApprove(recipient, amount);
    }
}


// File contracts/badger-sett/libraries/CurveSwapper.sol



pragma solidity ^0.6.11;







/*
    Expands swapping functionality over base strategy
    - ETH in and ETH out Variants
    - Sushiswap support in addition to Uniswap
*/
contract CurveSwapper is BaseSwapper {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    function _add_liquidity_single_coin(
        address swap,
        address pool,
        address inputToken,
        uint256 inputAmount,
        uint256 inputPosition,
        uint256 numPoolElements,
        uint256 min_mint_amount
    ) internal {
        _safeApproveHelper(inputToken, swap, inputAmount);
        if (numPoolElements == 2) {
            uint256[2] memory convertedAmounts;
            convertedAmounts[inputPosition] = inputAmount;
            ICurveFi(swap).add_liquidity(convertedAmounts, min_mint_amount);
        } else if (numPoolElements == 3) {
            uint256[3] memory convertedAmounts;
            convertedAmounts[inputPosition] = inputAmount;
            ICurveFi(swap).add_liquidity(convertedAmounts, min_mint_amount);
        } else if (numPoolElements == 4) {
            uint256[4] memory convertedAmounts;
            convertedAmounts[inputPosition] = inputAmount;
            ICurveFi(swap).add_liquidity(convertedAmounts, min_mint_amount);
        } else {
            revert("Invalid number of amount elements");
        }
    }

    function _add_liquidity(
        address pool,
        uint256[2] memory amounts,
        uint256 min_mint_amount
    ) internal {
        ICurveFi(pool).add_liquidity(amounts, min_mint_amount);
    }

    function _add_liquidity(
        address pool,
        uint256[3] memory amounts,
        uint256 min_mint_amount
    ) internal {
        ICurveFi(pool).add_liquidity(amounts, min_mint_amount);
    }

    function _add_liquidity(
        address pool,
        uint256[4] memory amounts,
        uint256 min_mint_amount
    ) internal {
        ICurveFi(pool).add_liquidity(amounts, min_mint_amount);
    }

    function _remove_liquidity_one_coin(
        address swap,
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) internal {
        ICurveFi(swap).remove_liquidity_one_coin(_token_amount, i, _min_amount);
    }
}


// File deps/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol



pragma solidity ^0.6.0;




/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
 *     require(hasRole(MY_ROLE, msg.sender));
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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}


// File contracts/badger-sett/libraries/UniswapSwapper.sol



pragma solidity ^0.6.11;









/*
    Expands swapping functionality over base strategy
    - ETH in and ETH out Variants
    - Sushiswap support in addition to Uniswap
*/
contract UniswapSwapper is BaseSwapper{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    address internal constant uniswap = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap router
    address internal constant sushiswap = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F; // Sushiswap router

    function _swapExactTokensForTokens(
        address router,
        address startToken,
        uint256 balance,
        address[] memory path
    ) internal {
        _safeApproveHelper(startToken, router, balance);
        IUniswapRouterV2(router).swapExactTokensForTokens(balance, 0, path, address(this), now);
    }

    function _swapExactETHForTokens(address router, uint256 balance, address[] memory path) internal {
        IUniswapRouterV2(uniswap).swapExactETHForTokens{value: balance}(0, path, address(this), now);
    }

    function _swapExactTokensForETH(
        address router,
        address startToken,
        uint256 balance,
        address[] memory path
    ) internal {
        _safeApproveHelper(startToken, router, balance);
        IUniswapRouterV2(router).swapExactTokensForETH(balance, 0, path, address(this), now);
    }

    function _getPair(address router, address token0, address token1) internal view returns (address) {
        address factory = IUniswapRouterV2(router).factory();
        return IUniswapV2Factory(factory).getPair(token0, token1);
    }

    /// @notice Add liquidity to uniswap for specified token pair, utilizing the maximum balance possible
    function _addMaxLiquidity(address router, address token0, address token1) internal {
        uint256 _token0Balance = IERC20Upgradeable(token0).balanceOf(address(this));
        uint256 _token1Balance = IERC20Upgradeable(token1).balanceOf(address(this));

        _safeApproveHelper(token0, router, _token0Balance);
        _safeApproveHelper(token1, router, _token1Balance);

        IUniswapRouterV2(router).addLiquidity(token0, token1, _token0Balance, _token1Balance, 0, 0, address(this), block.timestamp);
    }

    function _addMaxLiquidityEth(address router, address token0) internal {
        uint256 _token0Balance = IERC20Upgradeable(token0).balanceOf(address(this));
        uint256 _ethBalance = address(this).balance;

        _safeApproveHelper(token0, router, _token0Balance);
        IUniswapRouterV2(router).addLiquidityETH{ value: address(this).balance }(token0, _token0Balance, 0, 0, address(this), block.timestamp);
    }
}


// File contracts/badger-sett/libraries/TokenSwapPathRegistry.sol



pragma solidity ^0.6.11;






/*
    Expands swapping functionality over base strategy
    - ETH in and ETH out Variants
    - Sushiswap support in addition to Uniswap
*/
contract TokenSwapPathRegistry {
    mapping(address => mapping(address => address[])) public tokenSwapPaths;

    event TokenSwapPathSet(address tokenIn, address tokenOut, address[] path);

    function getTokenSwapPath(address tokenIn, address tokenOut) public view returns (address[] memory) {
        return tokenSwapPaths[tokenIn][tokenOut];
    }
    function _setTokenSwapPath(
        address tokenIn,
        address tokenOut,
        address[] memory path
    ) internal {
        tokenSwapPaths[tokenIn][tokenOut] = path;
        emit TokenSwapPathSet(tokenIn, tokenOut, path);
    }

}


// File contracts/badger-sett/strategies/convex/StrategyConvexStakingOptimizer.sol



pragma solidity ^0.6.11;

/*
    === Deposit ===
    Deposit & Stake underlying asset into appropriate convex vault (deposit + stake is atomic)

    === Tend ===

    == Stage 1: Realize gains from all positions ==
    Harvest CRV and CVX from core vault rewards pool
    Harvest CVX and SUSHI from CVX/ETH LP
    Harvest CVX and SUSHI from cvxCRV/CRV LP

    Harvested coins:
    CRV
    CVX
    SUSHI

    == Stage 2: Deposit all gains into staked positions ==
    Zap all CRV -> cvxCRV/CRV
    Zap all CVX -> CVX/ETH
    Stake Sushi

    Position coins:
    cvxCRV/CRV
    CVX/ETH
    xSushi

    These position coins will be distributed on harvest

*/
contract StrategyConvexStakingOptimizer is BaseStrategy, CurveSwapper, UniswapSwapper, TokenSwapPathRegistry {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    
    // ===== Token Registry =====
    address public constant wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant cvx = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant cvxCrv = 0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant threeCrv = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

    IERC20Upgradeable public constant wbtcToken = IERC20Upgradeable(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IERC20Upgradeable public constant crvToken = IERC20Upgradeable(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20Upgradeable public constant cvxToken = IERC20Upgradeable(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    IERC20Upgradeable public constant cvxCrvToken = IERC20Upgradeable(0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7);
    IERC20Upgradeable public constant usdcToken = IERC20Upgradeable(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20Upgradeable public constant threeCrvToken = IERC20Upgradeable(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);

    // ===== Convex Registry =====
    CrvDepositor public constant crvDepositor = CrvDepositor(0x8014595F2AB54cD7c604B00E9fb932176fDc86Ae); // Convert CRV -> cvxCRV
    IBooster public constant booster = IBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    address public constant cvxCRV_CRV_SLP = 0x33F6DDAEa2a8a54062E021873bCaEE006CdF4007; // cvxCRV/CRV SLP
    address public constant CVX_ETH_SLP = 0x05767d9EF41dC40689678fFca0608878fb3dE906; // CVX/ETH SLP
    IBaseRewardsPool public baseRewardsPool;
    IBaseRewardsPool public constant cvxCrvRewardsPool = IBaseRewardsPool(0x3Fe65692bfCD0e6CF84cB1E7d24108E434A7587e);
    ICvxRewardsPool public constant cvxRewardsPool = ICvxRewardsPool(0xCF50b810E57Ac33B91dCF525C6ddd9881B139332);
    ISushiChef public constant convexMasterChef = ISushiChef(0x5F465e9fcfFc217c5849906216581a657cd60605);
    address public constant threeCrvSwap = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;

    uint256 public constant cvxCRV_CRV_SLP_Pid = 0;
    uint256 public constant CVX_ETH_SLP_Pid = 1;

    uint256 public constant MAX_UINT_256 = uint256(-1);

    uint256 public pid;
    address public badgerTree;
    ISettV4 public cvxHelperVault;
    ISettV4 public cvxCrvHelperVault;

    /**
    The default conditions for a rewards token are:
    - Collect rewards token
    - Distribute 100% via Tree to users

    === Harvest Config ===
    - autoCompoundingBps: Sell this % of rewards for underlying asset.
    - autoCompoundingPerfFee: Of the auto compounded portion, take this % as a performance fee.
    - treeDistributionPerfFee: Of the remaining portion (everything not distributed or converted via another mehcanic is distributed via the tree), take this % as a performance fee.

    === Tend Config ===
    - tendConvertTo: On tend, convert some of this token into another asset. By default with value as address(0), skip this step.
    - tendConvertBps: Convert this portion of balance into another asset.
     */
    struct RewardTokenConfig {
        uint256 autoCompoundingBps;
        uint256 autoCompoundingPerfFee;
        uint256 treeDistributionPerfFee;
        address tendConvertTo;
        uint256 tendConvertBps;
    }

    struct CurvePoolConfig {
        address swap;
        uint256 wbtcPosition;
        uint256 numElements;
    }

    event ExtraRewardsTokenSet(
        address indexed token, 
        uint256 autoCompoundingBps,
        uint256 autoCompoundingPerfFee,
        uint256 treeDistributionPerfFee,
        address tendConvertTo,
        uint256 tendConvertBps
    );

    EnumerableSetUpgradeable.AddressSet internal extraRewards; // Tokens other than CVX and cvxCRV to process as rewards
    mapping(address => RewardTokenConfig) public rewardsTokenConfig;
    CurvePoolConfig public curvePool;

    uint256 public autoCompoundingBps;
    uint256 public autoCompoundingPerformanceFeeGovernance;

    uint256 public constant AUTO_COMPOUNDING_BPS = 2000;
    uint256 public constant AUTO_COMPOUNDING_PERFORMANCE_FEE = 5000; // Proportion of auto-compounded rewards taken as fee

    event TreeDistribution(address indexed token, uint256 amount, uint256 indexed blockNumber, uint256 timestamp);
    event PerformanceFeeGovernance(address indexed destination, address indexed token, uint256 amount, uint256 indexed blockNumber, uint256 timestamp);
    event PerformanceFeeStrategist(address indexed destination, address indexed token, uint256 amount, uint256 indexed blockNumber, uint256 timestamp);

    event WithdrawState(uint256 toWithdraw, uint256 preWant, uint256 postWant, uint256 withdrawn);

    struct HarvestData {
        uint256 cvxCrvHarvested;
        uint256 cvxHarvsted;
    }

    struct TendData {
        uint256 crvTended;
        uint256 cvxTended;
        uint256 cvxCrvTended;
    }

    struct TokenSwapData {
        address tokenIn;
        uint256 totalSold;
        uint256 wantGained;
    }

    event TendState(
        uint256 crvTended,
        uint256 cvxTended,
        uint256 cvxCrvTended
    );

    function initialize(
        address _governance,
        address _strategist,
        address _controller,
        address _keeper,
        address _guardian,
        address[4] memory _wantConfig,
        uint256 _pid,
        uint256[3] memory _feeConfig,
        CurvePoolConfig memory _curvePool
    ) public initializer whenNotPaused {
        __BaseStrategy_init(_governance, _strategist, _controller, _keeper, _guardian);

        want = _wantConfig[0];
        badgerTree = _wantConfig[1];

        cvxHelperVault = ISettV4(_wantConfig[2]);
        cvxCrvHelperVault = ISettV4(_wantConfig[3]);

        pid = _pid; // Core staking pool ID

        IBooster.PoolInfo memory poolInfo = booster.poolInfo(pid);
        baseRewardsPool = IBaseRewardsPool(poolInfo.crvRewards);

        performanceFeeGovernance = _feeConfig[0];
        performanceFeeStrategist = _feeConfig[1];
        withdrawalFee = _feeConfig[2];

        // Approvals: Staking Pools
        IERC20Upgradeable(want).approve(address(booster), MAX_UINT_256);
        cvxToken.approve(address(cvxRewardsPool), MAX_UINT_256);
        cvxCrvToken.approve(address(cvxCrvRewardsPool), MAX_UINT_256);

        // Approvals: CRV -> cvxCRV converter
        crvToken.approve(address(crvDepositor), MAX_UINT_256);

        curvePool = CurvePoolConfig(
            _curvePool.swap,
            _curvePool.wbtcPosition,
            _curvePool.numElements
        );

        // Set Swap Paths
        address[] memory path = new address[](3);
        path[0] = usdc;
        path[1] = weth;
        path[2] = cvxCrv;
        _setTokenSwapPath(usdc, cvxCrv, path);

        path = new address[](2);
        path[0] = crv;
        path[1] = cvxCrv;
        _setTokenSwapPath(crv, cvxCrv, path);

        path = new address[](3);
        path[0] = cvxCrv;
        path[1] = weth;
        path[2] = wbtc;
        _setTokenSwapPath(cvxCrv, wbtc, path);

        path = new address[](3);
        path[0] = cvx;
        path[1] = weth;
        path[2] = wbtc;
        _setTokenSwapPath(cvx, wbtc, path);

        _initializeApprovals();
        autoCompoundingBps = 2000;
        autoCompoundingPerformanceFeeGovernance = 5000;
    }

    /// ===== Permissioned Functions =====
    function setPid(uint256 _pid) external {
        _onlyGovernance();
        pid = _pid; // LP token pool ID
    }

    function addExtraRewardsToken(address _extraToken, RewardTokenConfig memory _rewardsConfig, address[] memory _swapPathToWant) external {
        _onlyGovernance();

        require(!isProtectedToken(_extraToken)); // We can't process tokens that are part of special strategy logic as extra rewards
        require(isProtectedToken(_rewardsConfig.tendConvertTo));  // We should only convert to tokens the strategy handles natively for security reasons

        /**
        === tendConvertTo Attack Vector: Rug rewards via swap ===
            - Set a token as an extra rewards token
            - Provide liquidity on that pool (disallow swaps from non-admin to avoid others messing with it)
            - Convert it to a token on tend that can be rugged by an admin    
            - Admin steals value    
        */

        extraRewards.add(_extraToken);
        rewardsTokenConfig[_extraToken] = _rewardsConfig;

        emit ExtraRewardsTokenSet(
            _extraToken, 
            _rewardsConfig.autoCompoundingBps,
            _rewardsConfig.autoCompoundingPerfFee,
            _rewardsConfig.treeDistributionPerfFee,
            _rewardsConfig.tendConvertTo,
            _rewardsConfig.tendConvertBps
        );
    }

    function removeExtraRewardsToken(address _extraToken) external {
        _onlyGovernance();
        extraRewards.remove(_extraToken);
    }

    function setAutoCompoundingBps(uint256 _bps) external {
        _onlyGovernance();
        autoCompoundingBps = _bps;
    }

    function setAutoCompoundingPerformanceFeeGovernance(uint256 _bps) external {
        _onlyGovernance();
        autoCompoundingPerformanceFeeGovernance = _bps;
    }

    function initializeApprovals() external {
        _onlyGovernance();
        _initializeApprovals();

    }
    function setCurvePoolSwap(address _swap) external {
        _onlyGovernance();
        curvePool.swap = _swap;
    }

    function _initializeApprovals() internal {
        cvxToken.approve(address(cvxHelperVault), MAX_UINT_256);
        cvxCrvToken.approve(address(cvxCrvHelperVault), MAX_UINT_256);
    }

    /// ===== View Functions =====
    function version() external pure returns (string memory) {
        return "1.0";
    }

    function getName() external override pure returns (string memory) {
        return "StrategyConvexStakingOptimizer";
    }

    function balanceOfPool() public override view returns (uint256) {
        return baseRewardsPool.balanceOf(address(this));
    }

    function getProtectedTokens() public override view returns (address[] memory) {
        address[] memory protectedTokens = new address[](4);
        protectedTokens[0] = want;
        protectedTokens[1] = crv;
        protectedTokens[2] = cvx;
        protectedTokens[3] = cvxCrv;
        return protectedTokens;
    }

    function isTendable() public override view returns (bool) {
        return true;
    }

    /// ===== Internal Core Implementations =====
    function _onlyNotProtectedTokens(address _asset) internal override {
        require(address(want) != _asset, "want");
        require(address(crv) != _asset, "crv");
        require(address(cvx) != _asset, "cvx");
        require(address(cvxCrv) != _asset, "cvxCrv");
    }

    /// @dev Deposit Badger into the staking contract
    function _deposit(uint256 _want) internal override {
        // Deposit all want in core staking pool
        booster.deposit(pid, _want, true);
    }

    /// @dev Unroll from all strategy positions, and transfer non-core tokens to controller rewards
    function _withdrawAll() internal override {
        baseRewardsPool.withdrawAndUnwrap(balanceOfPool(), false);
        // Note: All want is automatically withdrawn outside this "inner hook" in base strategy function
    }

    /// @dev Withdraw want from staking rewards, using earnings first
    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        // Get idle want in the strategy
        uint256 _preWant = IERC20Upgradeable(want).balanceOf(address(this));

        // If we lack sufficient idle want, withdraw the difference from the strategy position
        if (_preWant < _amount) {
            uint256 _toWithdraw = _amount.sub(_preWant);
            baseRewardsPool.withdrawAndUnwrap(_toWithdraw, false);
        }

        // Confirm how much want we actually end up with
        uint256 _postWant = IERC20Upgradeable(want).balanceOf(address(this));

        // Return the actual amount withdrawn if less than requested
        uint256 _withdrawn = MathUpgradeable.min(_postWant, _amount);
        emit WithdrawState(_amount, _preWant, _postWant, _withdrawn);

        return _withdrawn;
    }

    function _tendGainsFromPositions() internal {
        // Harvest CRV, CVX, cvxCRV, 3CRV, and extra rewards tokens from staking positions
        // Note: Always claim extras
        baseRewardsPool.getReward(address(this), true);

        if (cvxCrvRewardsPool.earned(address(this)) > 0) {
            cvxCrvRewardsPool.getReward(address(this), true);
        }
        
        if (cvxRewardsPool.earned(address(this)) > 0) {
            cvxRewardsPool.getReward(false);
        }
    }

    /// @notice The more frequent the tend, the higher returns will be
    function tend() external whenNotPaused returns (TendData memory) {
        _onlyAuthorizedActors();

        TendData memory tendData;

        // 1. Harvest gains from positions
        _tendGainsFromPositions();
        
        // Track harvested coins, before conversion
        tendData.crvTended = crvToken.balanceOf(address(this));

        // 2. Convert CRV -> cvxCRV
        if ( tendData.crvTended > 0 ) {
            _swapExactTokensForTokens(sushiswap, crv, tendData.crvTended, getTokenSwapPath(crv, cvxCrv));
        }

        // Track harvested + converted coins
        tendData.cvxCrvTended = cvxCrvToken.balanceOf(address(this));
        tendData.cvxTended = cvxToken.balanceOf(address(this));

        // 3. Stake all cvxCRV
        if (tendData.cvxCrvTended > 0) {
            cvxCrvRewardsPool.stake(tendData.cvxCrvTended);
        }
        
        // 4. Stake all CVX
        if (tendData.cvxTended > 0) {
            cvxRewardsPool.stake(cvxToken.balanceOf(address(this)));
        }

        emit Tend(0);
        emit TendState(tendData.crvTended, tendData.cvxTended, tendData.cvxCrvTended);
        return tendData;
    }
    
    // No-op until we optimize harvesting strategy. Auto-compouding is key.
    function harvest() external whenNotPaused returns (HarvestData memory) {
        _onlyAuthorizedActors();
        HarvestData memory harvestData;

        uint256 idleWant = IERC20Upgradeable(want).balanceOf(address(this));
        uint256 totalWantBefore = balanceOf();
        
        // TODO: Harvest details still under constructuion. It's being designed to optimize yield while still allowing on-demand access to profits for users.

        // 1. Withdraw accrued rewards from staking positions (claim unclaimed positions as well)
        baseRewardsPool.getReward(address(this), true);
        cvxCrvRewardsPool.withdraw(cvxCrvRewardsPool.balanceOf(address(this)), true);
        cvxRewardsPool.withdraw(cvxRewardsPool.balanceOf(address(this)), true);

        harvestData.cvxCrvHarvested = cvxCrvToken.balanceOf(address(this));
        harvestData.cvxHarvsted = cvxToken.balanceOf(address(this));

        // 2. Convert 3CRV -> cvxCRV via USDC
        uint256 threeCrvBalance = threeCrvToken.balanceOf(address(this));
        if (threeCrvBalance > 0) {
            _remove_liquidity_one_coin(threeCrvSwap, threeCrvBalance, 1, 0);
            _swapExactTokensForTokens(sushiswap, usdc, usdcToken.balanceOf(address(this)), getTokenSwapPath(usdc, cvxCrv));
        }

        // 3. Sell 20% of accured rewards for underlying
        if (harvestData.cvxCrvHarvested > 0) {
            uint256 cvxCrvToSell = harvestData.cvxCrvHarvested.mul(autoCompoundingBps).div(MAX_FEE);
            _swapExactTokensForTokens(sushiswap, cvxCrv, cvxCrvToSell, getTokenSwapPath(cvxCrv, wbtc));
        }

        if (harvestData.cvxHarvsted > 0) {
            uint256 cvxToSell = harvestData.cvxHarvsted.mul(autoCompoundingBps).div(MAX_FEE);
            _swapExactTokensForTokens(sushiswap, cvx, cvxToSell, getTokenSwapPath(cvx, wbtc));
        }

        // // Process extra rewards tokens
        // {
        //     for (uint256 i = 0; i < extraRewards.length(); i=i+1) {
        //         address token = extraRewards.at(i);
        //         IERC20Upgradeable tokenContract = IERC20Upgradeable(token);
        //         uint256 tokenBalance = tokenContract.balanceOf(address(this));

        //         // Sell performance fee (as wbtc) proportion
        //         uint256 sellBps = getTokenSellBps(token);
        //         _swap_uniswap(token, sellBps, getTokenSwapPath(token, wbtc));
        //         // TODO: Distribute performance fee

        //         // Distribute remainder to users
        //         // token.transfer(tokenBalance.mul(sellBps).div(MAX_BPS));
        //     }
        // }

        // 4. Roll WBTC gained into want position
        uint256 wbtcToDeposit = wbtcToken.balanceOf(address(this));

        if (wbtcToDeposit > 0) {
            _add_liquidity_single_coin(curvePool.swap, want, wbtc, wbtcToDeposit, curvePool.wbtcPosition, curvePool.numElements, 0);
            uint256 wantGained = IERC20Upgradeable(want).balanceOf(address(this)).sub(idleWant);
            // Half of gained want (10% of rewards) are auto-compounded, half of gained want is taken as a performance fee
            uint256 autoCompoundedPerformanceFee = wantGained.mul(autoCompoundingPerformanceFeeGovernance).div(MAX_FEE);
            IERC20Upgradeable(want).transfer(IController(controller).rewards(), autoCompoundedPerformanceFee);
            emit PerformanceFeeGovernance(IController(controller).rewards(), want, autoCompoundedPerformanceFee, block.number, block.timestamp);
        }

        // Deposit remaining want (including idle want) into strategy position
        uint256 wantToDeposited = IERC20Upgradeable(want).balanceOf(address(this));

        if (wantToDeposited > 0) {
            _deposit(wantToDeposited);
        }

        // 5. Deposit remaining CVX / cvxCRV rewards into helper vaults and distribute
        if (harvestData.cvxCrvHarvested > 0) {
            uint256 cvxCrvToDistribute = cvxCrvToken.balanceOf(address(this));
            
            if (performanceFeeGovernance > 0) {
                uint256 cvxCrvToGovernance = cvxCrvToDistribute.mul(performanceFeeGovernance).div(MAX_FEE);
                cvxCrvHelperVault.depositFor(IController(controller).rewards(), cvxCrvToGovernance);
                emit PerformanceFeeGovernance(IController(controller).rewards(), cvxCrv, cvxCrvToGovernance, block.number, block.timestamp);
            }

            if (performanceFeeStrategist > 0) {
                uint256 cvxCrvToStrategist = cvxCrvToDistribute.mul(performanceFeeStrategist).div(MAX_FEE);
                cvxCrvHelperVault.depositFor(strategist, cvxCrvToStrategist);
                emit PerformanceFeeStrategist(strategist, cvxCrv, cvxCrvToStrategist, block.number, block.timestamp);
            }

            // TODO: [Optimization] Allow contract to circumvent blockLock to dedup deposit operations

            uint256 treeHelperVaultBefore = cvxCrvHelperVault.balanceOf(badgerTree);

            // Deposit remaining to tree after taking fees. 
            uint256 cvxCrvToTree = cvxCrvToken.balanceOf(address(this));
            cvxCrvHelperVault.depositFor(badgerTree, cvxCrvToTree);

            uint256 treeHelperVaultAfter = cvxCrvHelperVault.balanceOf(badgerTree);
            uint256 treeVaultPositionGained = treeHelperVaultAfter.sub(treeHelperVaultBefore);

            emit TreeDistribution(address(cvxCrvHelperVault), treeVaultPositionGained, block.number, block.timestamp);
        }

        if (harvestData.cvxHarvsted > 0) {
            uint256 cvxToDistribute = cvxToken.balanceOf(address(this));

            if (performanceFeeGovernance > 0) {
                uint256 cvxToGovernance = cvxToDistribute.mul(performanceFeeGovernance).div(MAX_FEE);
                cvxHelperVault.depositFor(IController(controller).rewards(), cvxToGovernance);
                emit PerformanceFeeGovernance(IController(controller).rewards(), cvx, cvxToGovernance, block.number, block.timestamp);
            }

            if (performanceFeeStrategist > 0) {
                uint256 cvxToStrategist = cvxToDistribute.mul(performanceFeeStrategist).div(MAX_FEE);
                cvxHelperVault.depositFor(strategist, cvxToStrategist);
                emit PerformanceFeeStrategist(strategist, cvx, cvxToStrategist, block.number, block.timestamp);
            }

            // TODO: [Optimization] Allow contract to circumvent blockLock to dedup deposit operations

            uint256 treeHelperVaultBefore = cvxHelperVault.balanceOf(badgerTree);

            // Deposit remaining to tree after taking fees. 
            uint256 cvxToTree = cvxToken.balanceOf(address(this));
            cvxHelperVault.depositFor(badgerTree, cvxToTree);

            uint256 treeHelperVaultAfter = cvxHelperVault.balanceOf(badgerTree);
            uint256 treeVaultPositionGained = treeHelperVaultAfter.sub(treeHelperVaultBefore);

            emit TreeDistribution(address(cvxHelperVault), treeVaultPositionGained, block.number, block.timestamp);
        }

        uint256 totalWantAfter = balanceOf();
        require(totalWantAfter >= totalWantBefore, "harvest-total-want-must-not-decrease");

        return harvestData;
    }
}