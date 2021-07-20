/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
  // Booleans are more expensive than uint256 or any type that takes up a full
  // word because each write operation emits an extra SLOAD to first read the
  // slot's contents, replace the bits taken up by the boolean, and then write
  // back. This is the compiler's defense against contract upgrades and
  // pointer aliasing, and it cannot be disabled.

  // The values being non-zero value makes deployment a bit more expensive,
  // but in exchange the refund on every call to nonReentrant will be lower in
  // amount. Since refunds are capped to a percentage of the total
  // transaction's gas, it is best to keep them low in cases like this one, to
  // increase the likelihood of the full refund coming into effect.
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor() internal {
    _status = _NOT_ENTERED;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and make it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    // On the first call to nonReentrant, _notEntered will be true
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
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
   * @dev Returns the addition of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    uint256 c = a + b;
    if (c < a) return (false, 0);
    return (true, c);
  }

  /**
   * @dev Returns the substraction of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b > a) return (false, 0);
    return (true, a - b);
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) return (true, 0);
    uint256 c = a * b;
    if (c / a != b) return (false, 0);
    return (true, c);
  }

  /**
   * @dev Returns the division of two unsigned integers, with a division by zero flag.
   *
   * _Available since v3.4._
   */
  function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b == 0) return (false, 0);
    return (true, a / b);
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
   *
   * _Available since v3.4._
   */
  function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b == 0) return (false, 0);
    return (true, a % b);
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
    require(b <= a, "SafeMath: subtraction overflow");
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
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting on
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
    require(b > 0, "SafeMath: division by zero");
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
    require(b > 0, "SafeMath: modulo by zero");
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
    require(b <= a, errorMessage);
    return a - b;
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {tryDiv}.
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
    require(b > 0, errorMessage);
    return a / b;
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
    require(b > 0, errorMessage);
    return a % b;
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
    assembly {
      size := extcodesize(account)
    }
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
    (bool success, ) = recipient.call{value: amount}("");
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
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
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
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: value}(data);
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
  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.staticcall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, "Address: low-level delegate call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
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

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
   * {IERC20-approve}, and its usage is discouraged.
   *
   * Whenever possible, use {safeIncreaseAllowance} and
   * {safeDecreaseAllowance} instead.
   */
  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    // solhint-disable-next-line max-line-length
    require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
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
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

interface IWETH {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256) external;

  function balanceOf(address account) external view returns (uint256);
}

interface IUniswapV2Router {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

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

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

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

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

interface IFireBirdRouter {
  event Exchange(address pair, uint256 amountOut, address output);

  function factory() external view returns (address);

  function formula() external view returns (address);

  function WETH() external view returns (address);

  function addLiquidity(
    address pair,
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
    address pair,
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

  function swapExactTokensForTokens(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    address tokenIn,
    address tokenOut,
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    address tokenOut,
    uint256 amountOutMin,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    address tokenIn,
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    address tokenIn,
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    address tokenOut,
    uint256 amountOut,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    address tokenOut,
    uint256 amountOutMin,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    address tokenIn,
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external;

  function createPair(
    address tokenA,
    address tokenB,
    uint256 amountA,
    uint256 amountB,
    uint32 tokenWeightA,
    uint32 swapFee,
    address to
  ) external returns (uint256 liquidity);

  function createPairETH(
    address token,
    uint256 amountToken,
    uint32 tokenWeight,
    uint32 swapFee,
    address to
  ) external payable returns (uint256 liquidity);

  function removeLiquidity(
    address pair,
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address pair,
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address pair,
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address pair,
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address pair,
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address pair,
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);
}

interface IFireBirdFactory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint32 tokenWeight0, uint32 swapFee, uint256);

  function feeTo() external view returns (address);

  function formula() external view returns (address);

  function protocolFee() external view returns (uint256);

  function feeToSetter() external view returns (address);

  function getPair(
    address tokenA,
    address tokenB,
    uint32 tokenWeightA,
    uint32 swapFee
  ) external view returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function isPair(address) external view returns (bool);

  function allPairsLength() external view returns (uint256);

  function createPair(
    address tokenA,
    address tokenB,
    uint32 tokenWeightA,
    uint32 swapFee
  ) external returns (address pair);

  function getWeightsAndSwapFee(address pair)
    external
    view
    returns (
      uint32 tokenWeight0,
      uint32 tokenWeight1,
      uint32 swapFee
    );

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;

  function setProtocolFee(uint256) external;
}

interface IFireBirdPair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event PaidProtocolFee(uint112 collectedFee0, uint112 collectedFee1);
  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
  event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

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

  function getCollectedFees() external view returns (uint112 _collectedFee0, uint112 _collectedFee1);

  function getTokenWeights() external view returns (uint32 tokenWeight0, uint32 tokenWeight1);

  function getSwapFee() external view returns (uint32);

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(
    address,
    address,
    uint32,
    uint32
  ) external;
}

/*
    Bancor Formula interface
*/
interface IFireBirdFormula {
  function getFactoryReserveAndWeights(
    address factory,
    address pair,
    address tokenA,
    uint8 dexId
  )
    external
    view
    returns (
      address tokenB,
      uint256 reserveA,
      uint256 reserveB,
      uint32 tokenWeightA,
      uint32 tokenWeightB,
      uint32 swapFee
    );

  function getFactoryWeightsAndSwapFee(
    address factory,
    address pair,
    uint8 dexId
  )
    external
    view
    returns (
      uint32 tokenWeight0,
      uint32 tokenWeight1,
      uint32 swapFee
    );

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut,
    uint32 tokenWeightIn,
    uint32 tokenWeightOut,
    uint32 swapFee
  ) external view returns (uint256 amountIn);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut,
    uint32 tokenWeightIn,
    uint32 tokenWeightOut,
    uint32 swapFee
  ) external view returns (uint256 amountOut);

  function getFactoryAmountsIn(
    address factory,
    address tokenIn,
    address tokenOut,
    uint256 amountOut,
    address[] calldata path,
    uint8[] calldata dexIds
  ) external view returns (uint256[] memory amounts);

  function getFactoryAmountsOut(
    address factory,
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    address[] calldata path,
    uint8[] calldata dexIds
  ) external view returns (uint256[] memory amounts);

  function ensureConstantValue(
    uint256 reserve0,
    uint256 reserve1,
    uint256 balance0Adjusted,
    uint256 balance1Adjusted,
    uint32 tokenWeight0
  ) external view returns (bool);

  function getReserves(
    address pair,
    address tokenA,
    address tokenB
  ) external view returns (uint256 reserveA, uint256 reserveB);

  function getOtherToken(address pair, address tokenA) external view returns (address tokenB);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);

  function mintLiquidityFee(
    uint256 totalLiquidity,
    uint112 reserve0,
    uint112 reserve1,
    uint32 tokenWeight0,
    uint32 tokenWeight1,
    uint112 collectedFee0,
    uint112 collectedFee1
  ) external view returns (uint256 amount);
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "TransferHelper: ETH_TRANSFER_FAILED");
  }
}

library Babylonian {
  function sqrt(uint256 y) internal pure returns (uint256 z) {
    if (y > 3) {
      z = y;
      uint256 x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
    // else z = 0
  }
}

contract FireBirdZap is ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // governance
  address public governance;
  address public WBNB;
  address private constant BNB_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

  IUniswapV2Router public uniRouter;
  IFireBirdRouter public fireBirdRouter;
  IFireBirdFactory public fireBirdFactory;
  IFireBirdFormula public fireBirdFormula;

  uint256 public maxResidual = 10000; // 1%, set 10000 to disable
  address[] public tokensResidual;

  event ZapIn(address indexed sender, address from, uint256 amtFrom, address pool, uint256 amtLp);
  event ZapOut(address indexed sender, address pool, uint256 amtLp, address to, uint256 amtTo);
  event Withdraw(address indexed token, uint256 amount, address to);
  event LogGovernance(address governance);

  receive() external payable {
    require(msg.sender != tx.origin, "Zap: Do not send ETH directly");
  }

  modifier onlyGovernance() {
    require(msg.sender == governance, "Zap: !governance");
    _;
  }

  constructor(IUniswapV2Router _uniRouter, IFireBirdRouter _fireBirdRouter) public {
    governance = msg.sender;
    uniRouter = _uniRouter;
    fireBirdRouter = _fireBirdRouter;
    fireBirdFactory = IFireBirdFactory(_fireBirdRouter.factory());
    fireBirdFormula = IFireBirdFormula(_fireBirdRouter.formula());
    WBNB = _fireBirdRouter.WETH();
  }

  /* ========== External Functions ========== */

  // _to: must be a pair lp
  // _from: must be in lp
  // _amounts: amount_from, _minTokenB, _minLp
  function zapInToken(
    address _from,
    uint256[] calldata amounts,
    address _to,
    uint8 dexId,
    bool transferResidual
  ) external nonReentrant returns (uint256 lpAmt) {
    IERC20(_from).safeTransferFrom(msg.sender, address(this), amounts[0]);
    _approveTokenIfNeeded(_from);

    require(_from == IFireBirdPair(_to).token0() || _from == IFireBirdPair(_to).token1(), "FireBirdZap: !pair");
    // swap half amount for other
    address other;
    uint256 sellAmount;
    {
      address token0 = IFireBirdPair(_to).token0();
      address token1 = IFireBirdPair(_to).token1();
      other = _from == token0 ? token1 : token0;
      sellAmount = calculateSwapInAmount(_to, _from, amounts[0], token0, dexId);
    }
    uint256 otherAmount = _swap(_from, sellAmount, other, address(this), _to, dexId);
    require(otherAmount >= amounts[1], "Zap: Insufficient Receive Amount");

    lpAmt = _pairDeposit(_to, _from, other, amounts[0].sub(sellAmount), otherAmount, msg.sender, fireBirdFactory.isPair(_to), transferResidual);

    require(lpAmt >= amounts[2], "Zap: High Slippage In");
    emit ZapIn(msg.sender, _from, amounts[0], _to, lpAmt);
    return lpAmt;
  }

  // _to: must be a pair lp
  function zapIn(
    address _to,
    uint256 _minTokenB,
    uint256 _minLp,
    uint8 dexId,
    bool transferResidual
  ) external payable nonReentrant returns (uint256) {
    uint256 lpAmt = _swapBNBToLp(IFireBirdPair(_to), msg.value, msg.sender, _minTokenB, dexId, transferResidual);
    require(lpAmt >= _minLp, "Zap: High Slippage In");
    emit ZapIn(msg.sender, WBNB, msg.value, _to, lpAmt);
    return lpAmt;
  }

  // _from: must be a pair lp
  // _toToken: must be in lp
  function zapOut(
    address _from,
    uint256 amount,
    address _toToken,
    uint256 _minTokensRec,
    uint8 dexId
  ) public nonReentrant returns (uint256) {
    IERC20(_from).safeTransferFrom(msg.sender, address(this), amount);
    _approveTokenIfNeeded(_from);

    address token0;
    address token1;
    uint256 amountA;
    uint256 amountB;
    {
      IFireBirdPair pair = IFireBirdPair(_from);
      token0 = pair.token0();
      token1 = pair.token1();
      bool isfireBirdPair = fireBirdFactory.isPair(_from);
      if (isfireBirdPair) {
        (amountA, amountB) = fireBirdRouter.removeLiquidity(_from, token0, token1, amount, 1, 1, address(this), block.timestamp);
      } else {
        (amountA, amountB) = uniRouter.removeLiquidity(token0, token1, amount, 1, 1, address(this), block.timestamp);
      }
    }

    uint256 tokenBought;
    _approveTokenIfNeeded(token0);
    _approveTokenIfNeeded(token1);
    if (_toToken == BNB_ADDRESS) {
      address _lpOfFromAndTo = WBNB == token0 || WBNB == token1 ? _from : address(0);
      if (_lpOfFromAndTo == address(0)) revert("FireBirdZap: !pairBNB");
      tokenBought = _swapTokenForBNB(token0, amountA, address(this), _lpOfFromAndTo, dexId);
      tokenBought = tokenBought.add(_swapTokenForBNB(token1, amountB, address(this), _lpOfFromAndTo, dexId));
    } else {
      address _lpOfFromAndTo = _toToken == token0 || _toToken == token1 ? _from : address(0);
      if (_lpOfFromAndTo == address(0)) revert("FireBirdZap: !pair");
      tokenBought = _swap(token0, amountA, _toToken, address(this), _lpOfFromAndTo, dexId);
      tokenBought = tokenBought.add(_swap(token1, amountB, _toToken, address(this), _lpOfFromAndTo, dexId));
    }

    require(tokenBought >= _minTokensRec, "Zap: High Slippage Out");
    if (_toToken == BNB_ADDRESS) {
      TransferHelper.safeTransferETH(msg.sender, tokenBought);
    } else {
      IERC20(_toToken).safeTransfer(msg.sender, tokenBought);
    }

    emit ZapOut(msg.sender, _from, amount, _toToken, tokenBought);
    return tokenBought;
  }

  function zapOutWithPermit(
    address _from,
    uint256 amount,
    address _toToken,
    uint256 _minTokensRec,
    uint8 dexId,
    uint256 _approvalAmount,
    uint256 _deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256) {
    // permit
    IFireBirdPair(_from).permit(msg.sender, address(this), _approvalAmount, _deadline, v, r, s);

    return zapOut(_from, amount, _toToken, _minTokensRec, dexId);
  }

  /* ========== View Functions ===========*/
  // _from: token A
  // return amount B that will be convert from A to perform zap in
  // return amount A that will be convert to B to perform zap in
  function getAmountBToZapIn(
    address _from,
    uint256 _fromAmount,
    address lp,
    uint8 dexId
  ) external view returns (uint256 amountBConverted, uint256 amountASell) {
    address other;
    uint256 sellAmount;
    {
      IFireBirdPair pair = IFireBirdPair(lp);
      address token0 = pair.token0();
      address token1 = pair.token1();
      other = _from == token0 ? token1 : token0;
      sellAmount = calculateSwapInAmount(lp, _from, _fromAmount, token0, dexId);
    }

    address[] memory path = new address[](1);
    path[0] = lp;
    uint8[] memory dexIds = new uint8[](1);
    dexIds[0] = dexId;
    uint256[] memory amounts = fireBirdFormula.getFactoryAmountsOut(address(fireBirdFactory), _from, other, sellAmount, path, dexIds);
    return (amounts[amounts.length - 1], sellAmount);
  }

  // _from: lp pair
  // return amountOtherSell _otherToken that will be removed from pair
  // return amountToConverted _toToken that will be converted from other
  // return amountToOrigin _toToken that will be removed from pair
  function getAmountToZapOut(
    address _from,
    uint256 amount,
    address _toToken,
    uint8 dexId
  )
    external
    view
    returns (
      uint256 amountOtherSell,
      uint256 amountToConverted,
      uint256 amountToOrigin
    )
  {
    address other;
    {
      IFireBirdPair pair = IFireBirdPair(_from);
      address token0 = pair.token0();
      address token1 = pair.token1();
      other = _toToken == token0 ? token1 : token0;
    }
    uint256 sellAmount;
    uint256 amountToRemoved;
    {
      uint256 _totalSupply = IERC20(_from).totalSupply();
      sellAmount = amount.mul(IERC20(other).balanceOf(_from)) / _totalSupply;
      amountToRemoved = amount.mul(IERC20(_toToken).balanceOf(_from)) / _totalSupply;
    }

    uint256 _amountOut = _getRemovedReserveAmountOut(_from, other, sellAmount, amountToRemoved, dexId);
    return (sellAmount, _amountOut, amountToRemoved);
  }

  function calculateSwapInAmount(
    address pair,
    address tokenIn,
    uint256 userIn,
    address pairToken0,
    uint8 dexId
  ) internal view returns (uint256) {
    (uint32 tokenWeight0, uint32 tokenWeight1, uint32 swapFee) = fireBirdFormula.getFactoryWeightsAndSwapFee(address(fireBirdFactory), pair, dexId);

    if (tokenWeight0 == 50) {
      (uint256 res0, uint256 res1, ) = IFireBirdPair(pair).getReserves();
      uint256 reserveIn = tokenIn == pairToken0 ? res0 : res1;
      uint256 rMul = uint256(10000).sub(uint256(swapFee));
      return _getExactSwapInAmount(reserveIn, userIn, rMul);
    } else {
      uint256 otherWeight = tokenIn == pairToken0 ? uint256(tokenWeight1) : uint256(tokenWeight0);
      return userIn.mul(otherWeight).div(100);
    }
  }

  /* ========== Private Functions ========== */
  function _getExactSwapInAmount(
    uint256 reserveIn,
    uint256 userIn,
    uint256 rMul
  ) internal pure returns (uint256) {
    return Babylonian.sqrt(reserveIn.mul(userIn.mul(40000).mul(rMul) + reserveIn.mul(rMul.add(10000)).mul(rMul.add(10000)))).sub(reserveIn.mul(rMul.add(10000))) / (rMul.mul(2));
  }

  function _getRemovedReserveAmountOut(
    address pair,
    address tokenIn,
    uint256 sellAmount,
    uint256 amountToRemoved,
    uint8 dexId
  ) internal view returns (uint256) {
    (, uint256 reserveIn, uint256 reserveOut, uint32 tokenWeightIn, uint32 tokenWeightOut, uint32 swapFee) =
      fireBirdFormula.getFactoryReserveAndWeights(address(fireBirdFactory), pair, tokenIn, dexId);
    return fireBirdFormula.getAmountOut(sellAmount, reserveIn.sub(sellAmount), reserveOut.sub(amountToRemoved), tokenWeightIn, tokenWeightOut, swapFee);
  }

  function _approveTokenIfNeeded(address token) private {
    if (IERC20(token).allowance(address(this), address(uniRouter)) == 0) {
      IERC20(token).safeApprove(address(uniRouter), uint256(~0));
    }
    if (IERC20(token).allowance(address(this), address(fireBirdRouter)) == 0) {
      IERC20(token).safeApprove(address(fireBirdRouter), uint256(~0));
    }
  }

  function _pairDeposit(
    address _pair,
    address _poolToken0,
    address _poolToken1,
    uint256 token0Bought,
    uint256 token1Bought,
    address receiver,
    bool isfireBirdPair,
    bool transferResidual
  ) internal returns (uint256 lpAmt) {
    _approveTokenIfNeeded(_poolToken0);
    _approveTokenIfNeeded(_poolToken1);

    uint256 amountA;
    uint256 amountB;
    if (isfireBirdPair) {
      (amountA, amountB, lpAmt) = fireBirdRouter.addLiquidity(_pair, _poolToken0, _poolToken1, token0Bought, token1Bought, 1, 1, receiver, block.timestamp);
    } else {
      (amountA, amountB, lpAmt) = uniRouter.addLiquidity(_poolToken0, _poolToken1, token0Bought, token1Bought, 1, 1, receiver, block.timestamp);
    }

    uint256 amountAResidual = token0Bought.sub(amountA);
    if (transferResidual || amountAResidual > token0Bought.mul(maxResidual).div(10000)) {
      if (amountAResidual > 0) {
        //Returning Residue in token0, if any.
        _transferToken(_poolToken0, msg.sender, amountAResidual);
      }
    }

    uint256 amountBRedisual = token1Bought.sub(amountB);
    if (transferResidual || amountBRedisual > token1Bought.mul(maxResidual).div(10000)) {
      if (amountBRedisual > 0) {
        //Returning Residue in token1, if any
        _transferToken(_poolToken1, msg.sender, amountBRedisual);
      }
    }

    return lpAmt;
  }

  function _swapBNBToLp(
    IFireBirdPair pair,
    uint256 amount,
    address receiver,
    uint256 _minTokenB,
    uint8 dexId,
    bool transferResidual
  ) private returns (uint256 lpAmt) {
    address lp = address(pair);

    require(pair.token0() == WBNB || pair.token1() == WBNB, "FireBirdZap: !pairBNB");
    // Lp
    address token = pair.token0() == WBNB ? pair.token1() : pair.token0();
    uint256 swapValue = calculateSwapInAmount(lp, WBNB, amount, pair.token0(), dexId);
    uint256 tokenAmount = _swapBNBForToken(token, swapValue, address(this), lp, dexId);
    require(tokenAmount >= _minTokenB, "Zap: Insufficient Receive Amount");

    uint256 wbnbAmount = amount.sub(swapValue);
    IWETH(WBNB).deposit{value: wbnbAmount}();
    lpAmt = _pairDeposit(lp, WBNB, token, wbnbAmount, tokenAmount, receiver, fireBirdFactory.isPair(lp), transferResidual);
  }

  function _swapBNBForToken(
    address token,
    uint256 value,
    address _receiver,
    address lpBNBToken,
    uint8 dexId
  ) private returns (uint256) {
    if (token == WBNB) {
      IWETH(WBNB).deposit{value: value}();
      if (_receiver != address(this)) {
        IERC20(WBNB).safeTransfer(_receiver, value);
      }
      return value;
    }
    address[] memory path = new address[](1);
    path[0] = lpBNBToken;
    uint8[] memory dexIds = new uint8[](1);
    dexIds[0] = dexId;
    uint256[] memory amounts = fireBirdRouter.swapExactETHForTokens{value: value}(token, 1, path, dexIds, _receiver, block.timestamp);

    return amounts[amounts.length - 1];
  }

  function _swapTokenForBNB(
    address token,
    uint256 amount,
    address _receiver,
    address lpTokenBNB,
    uint8 dexId
  ) private returns (uint256) {
    if (token == WBNB) {
      _transferToken(WBNB, _receiver, amount);
      return amount;
    }
    address[] memory path = new address[](1);
    path[0] = lpTokenBNB;
    uint8[] memory dexIds = new uint8[](1);
    dexIds[0] = dexId;
    uint256[] memory amounts = fireBirdRouter.swapExactTokensForETH(token, amount, 1, path, dexIds, _receiver, block.timestamp);

    return amounts[amounts.length - 1];
  }

  function _swap(
    address _from,
    uint256 _amount,
    address _to,
    address _receiver,
    address _lpOfFromTo,
    uint8 dexId
  ) internal returns (uint256) {
    if (_from == _to) {
      if (_receiver != address(this)) {
        IERC20(_from).safeTransfer(_receiver, _amount);
      }
      return _amount;
    }
    address[] memory path = new address[](1);
    path[0] = _lpOfFromTo;
    uint8[] memory dexIds = new uint8[](1);
    dexIds[0] = dexId;
    uint256[] memory amounts = fireBirdRouter.swapExactTokensForTokens(_from, _to, _amount, 1, path, dexIds, _receiver, block.timestamp);

    return amounts[amounts.length - 1];
  }

  function _transferToken(
    address token,
    address to,
    uint256 amount
  ) internal {
    if (amount == 0) {
      return;
    }

    if (token == WBNB) {
      IWETH(WBNB).withdraw(amount);
      if (to != address(this)) {
        TransferHelper.safeTransferETH(to, amount);
      }
    } else {
      IERC20(token).safeTransfer(to, amount);
    }
    return;
  }

  /* ========== RESTRICTED FUNCTIONS ========== */
  function withdraw(address to) external onlyGovernance {
    address[] memory _tokens = tokensResidual;
    withdrawToken(_tokens, to);
  }

  function withdrawToken(address[] memory tokens, address to) public onlyGovernance {
    require(to != address(0), "Zap: Invalid Receiver Address");

    for (uint256 i = 0; i < tokens.length; i++) {
      _withdraw(tokens[i], to);
    }
  }

  function withdrawTokenAmount(
    address token,
    address to,
    uint256 amount
  ) external onlyGovernance {
    require(to != address(0), "Zap: Invalid Receiver Address");
    IERC20(token).safeTransfer(to, amount);
    emit Withdraw(token, amount, to);
  }

  function _withdraw(address _token, address _to) internal {
    if (_token == BNB_ADDRESS) {
      TransferHelper.safeTransferETH(_to, address(this).balance);
      emit Withdraw(_token, address(this).balance, _to);
      return;
    }

    uint256 _balance = IERC20(_token).balanceOf(address(this));
    IERC20(_token).safeTransfer(_to, _balance);
    emit Withdraw(_token, _balance, _to);
  }

  function setTokensResidual(address[] memory _tokensResidual) external onlyGovernance {
    tokensResidual = _tokensResidual;
  }

  function addTokensResidual(address _token) external onlyGovernance {
    tokensResidual.push(_token);
  }

  function setGovernance(address _governance) external onlyGovernance {
    governance = _governance;
    emit LogGovernance(governance);
  }

  function setMaxResidual(uint256 _maxResidual) external onlyGovernance {
    maxResidual = _maxResidual;
  }
}