// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

// SPDX-License-Identifier: MIT

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * This file is derived from Uniswap, available under the GNU General Public
 * License 3.0. https://uniswap.org/
 *
 * SPDX-License-Identifier: Apache-2.0 AND GPL-3.0-or-later
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0;

interface IUniswapV2Factory {
  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint256
  );

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * This file is derived from Uniswap, available under the GNU General Public
 * License 3.0. https://uniswap.org/
 *
 * SPDX-License-Identifier: Apache-2.0 AND GPL-3.0-or-later
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  // solhint-disable-next-line func-name-mixedcase
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

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * This file is derived from Uniswap, available under the GNU General Public
 * License 3.0. https://uniswap.org/
 *
 * SPDX-License-Identifier: Apache-2.0 AND GPL-3.0-or-later
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '@openzeppelin/contracts/GSN/Context.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

import '../../interfaces/uniswap/IUniswapV2Factory.sol';
import '../../interfaces/uniswap/IUniswapV2Router02.sol';

import '../investment/interfaces/IStakeFarm.sol';
import '../token/interfaces/IERC20WolfMintable.sol';
import '../utils/AddressBook.sol';
import '../utils/interfaces/IAddressRegistry.sol';

/**
 * @title Crowdsale
 *
 * @dev Crowdsale is a base contract for managing a token crowdsale, allowing
 * investors to purchase tokens with ether. This contract implements such
 * functionality in its most fundamental form and can be extended to provide
 * additional functionality and/or custom behavior.
 *
 * The external interface represents the basic interface for purchasing tokens,
 * and conforms the base architecture for crowdsales. It is *not* intended to
 * be modified / overridden.
 *
 * The internal interface conforms the extensible and modifiable surface of
 * crowdsales. Override the methods to add functionality. Consider using 'super'
 * where appropriate to concatenate behavior.
 */
contract Crowdsale is Context, ReentrancyGuard, AddressBook {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using SafeERC20 for IERC20WolfMintable;

  // The token being sold
  IERC20WolfMintable public token;

  // Address where funds are collected
  address payable private _wallet;

  // How many token units a buyer gets per wei.
  //
  // The rate is the conversion between wei and the smallest and indivisible
  // token unit. So, if you are using a rate of 1 with a ERC20Detailed token
  // with 3 decimals called TOK 1 wei will give you 1 unit, or 0.001 TOK.
  //
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  uint256 public cap;
  uint256 public investMin;
  uint256 public walletCap;

  uint256 public openingTime;
  uint256 public closingTime;

  // Per wallet investment (in wei)
  mapping(address => uint256) private _walletInvest;

  /**
   * Event for token purchase logging
   *
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokensPurchased(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * Event for add liquidity logging
   *
   * @param beneficiary who got the tokens
   * @param amountToken how many token were added
   * @param amountETH how many ETH were added
   * @param liquidity how many pool tokens were created
   */
  event LiquidityAdded(
    address indexed beneficiary,
    uint256 amountToken,
    uint256 amountETH,
    uint256 liquidity
  );

  /**
   * Event for stake liquidity logging
   *
   * @param beneficiary who got the tokens
   * @param liquidity how many pool tokens were created
   */
  event Staked(address indexed beneficiary, uint256 liquidity);

  // Uniswap Router for providing liquidity
  IUniswapV2Router02 public immutable uniV2Router;
  IERC20 public immutable uniV2Pair;

  IStakeFarm public immutable stakeFarm;

  // Rate of tokens to insert into the UNISwapv2 liquidity pool
  //
  // Because they will be devided, expanding by multiples of 10
  // is fine to express decimal values.
  //
  uint256 private tokenForLp;
  uint256 private ethForLp;

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    require(isOpen(), 'not open');
    _;
  }

  /**
   * @dev Crowdsale constructor
   *
   * @param _addressRegistry IAdressRegistry to get wallet and uniV2Router02
   * @param _rate Number of token units a buyer gets per wei
   *
   * The rate is the conversion between wei and the smallest and indivisible
   * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
   * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
   *
   * @param _token Address of the token being sold
   * @param _cap Max amount of wei to be contributed
   * @param _investMin minimum investment in wei
   * @param _walletCap Max amount of wei to be contributed per wallet
   * @param _lpEth numerator of liquidity pair
   * @param _lpToken denominator of liquidity pair
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  constructor(
    IAddressRegistry _addressRegistry,
    uint256 _rate,
    IERC20WolfMintable _token,
    uint256 _cap,
    uint256 _investMin,
    uint256 _walletCap,
    uint256 _lpEth,
    uint256 _lpToken,
    uint256 _openingTime,
    uint256 _closingTime
  ) {
    require(_rate > 0, 'rate is 0');
    require(address(_token) != address(0), 'token is addr(0)');
    require(_cap > 0, 'cap is 0');
    require(_lpEth > 0, 'lpEth is 0');
    require(_lpToken > 0, 'lpToken is 0');

    // solhint-disable-next-line not-rely-on-time
    require(_openingTime >= block.timestamp, 'opening > now');
    require(_closingTime > _openingTime, 'open > close');

    // Reverts if address is invalid
    IUniswapV2Router02 _uniV2Router =
      IUniswapV2Router02(
        _addressRegistry.getRegistryEntry(UNISWAP_V2_ROUTER02)
      );
    uniV2Router = _uniV2Router;

    // Get our liquidity pair
    address _uniV2Pair =
      IUniswapV2Factory(_uniV2Router.factory()).getPair(
        address(_token),
        _uniV2Router.WETH()
      );
    require(_uniV2Pair != address(0), 'invalid pair');
    uniV2Pair = IERC20(_uniV2Pair);

    // Reverts if address is invalid
    address _marketingWallet =
      _addressRegistry.getRegistryEntry(MARKETING_WALLET);
    _wallet = payable(_marketingWallet);

    // Reverts if address is invalid
    address _stakeFarm =
      _addressRegistry.getRegistryEntry(WETH_WOWS_STAKE_FARM);
    stakeFarm = IStakeFarm(_stakeFarm);

    rate = _rate;
    token = _token;
    cap = _cap;
    investMin = _investMin;
    walletCap = _walletCap;
    ethForLp = _lpEth;
    tokenForLp = _lpToken;
    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  /**
   * @dev Fallback function ***DO NOT OVERRIDE***
   *
   * Note that other contracts will transfer funds with a base gas stipend
   * of 2300, which is not enough to call buyTokens. Consider calling
   * buyTokens directly when purchasing tokens from a contract.
   */
  receive() external payable {
    // A payable receive() function follows the OpenZeppelin strategy, in which
    // it is designed to buy tokens.
    //
    // However, because we call out to uniV2Router from the crowdsale contract,
    // re-imbursement of ETH from UniswapV2Pair must not buy tokens.
    //
    // Instead it must be payed to this contract as a first step and will then
    // be transferred to the recipient in _addLiquidity().
    //
    if (_msgSender() != address(uniV2Router)) buyTokens(_msgSender());
  }

  /**
   * @dev Checks whether the cap has been reached
   *
   * @return Whether the cap was reached
   */
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

  /**
   * @return True if the crowdsale is open, false otherwise.
   */
  function isOpen() public view returns (bool) {
    // solhint-disable-next-line not-rely-on-time
    return block.timestamp >= openingTime && block.timestamp <= closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   *
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    // solhint-disable-next-line not-rely-on-time
    return block.timestamp > closingTime;
  }

  /**
   * @dev Provide a collection of UI relevant values to reduce # of queries
   *
   * @return ethRaised Amount eth raised (wei)
   * @return timeOpen Time presale opens (unix timestamp seconds)
   * @return timeClose Time presale closes (unix timestamp seconds)
   * @return timeNow Current time (unix timestamp seconds)
   * @return userEthInvested Amount of ETH users have already spent (wei)
   * @return userTokenAmount Amount of token held by user (token::decimals)
   */
  function getStates(address beneficiary)
    public
    view
    returns (
      uint256 ethRaised,
      uint256 timeOpen,
      uint256 timeClose,
      uint256 timeNow,
      uint256 userEthInvested,
      uint256 userTokenAmount
    )
  {
    uint256 tokenAmount =
      beneficiary == address(0) ? 0 : token.balanceOf(beneficiary);
    uint256 ethInvest = _walletInvest[beneficiary];

    return (
      weiRaised,
      openingTime,
      closingTime,
      // solhint-disable-next-line not-rely-on-time
      block.timestamp,
      ethInvest,
      tokenAmount
    );
  }

  /**
   * @dev Low level token purchase ***DO NOT OVERRIDE***
   *
   * This function has a non-reentrancy guard, so it shouldn't be called by
   * another `nonReentrant` function.
   *
   * @param beneficiary Recipient of the token purchase
   */
  function buyTokens(address beneficiary) public payable nonReentrant {
    uint256 weiAmount = msg.value;
    _preValidatePurchase(beneficiary, weiAmount);

    // Calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // Update state
    weiRaised = weiRaised.add(weiAmount);
    _walletInvest[beneficiary] = _walletInvest[beneficiary].add(weiAmount);

    _processPurchase(beneficiary, tokens);
    emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);

    _forwardFunds(weiAmount);
  }

  /**
   * @dev Low level token purchase and liquidity staking ***DO NOT OVERRIDE***
   *
   * This function has a non-reentrancy guard, so it shouldn't be called by
   * another `nonReentrant` function.
   *
   * @param beneficiary Recipient of the token purchase
   */
  function buyTokensAddLiquidity(address payable beneficiary)
    public
    payable
    nonReentrant
  {
    uint256 weiAmount = msg.value;

    // The ETH amount we buy WOWS token for
    uint256 buyAmount =
      weiAmount.mul(tokenForLp).div(rate.mul(ethForLp).add(tokenForLp));

    // The ETH amount we invest for liquidity (ETH + WOLF)
    uint256 investAmount = weiAmount.sub(buyAmount);

    _preValidatePurchase(beneficiary, buyAmount);

    // Calculate token amount to be created
    uint256 tokens = _getTokenAmount(buyAmount);

    // Verify that the ratio is in 0.1% limit
    uint256 tokensReverse = investAmount.mul(tokenForLp).div(ethForLp);
    require(
      tokens < tokensReverse || tokens.sub(tokensReverse) < tokens.div(1000),
      'ratio wrong'
    );
    require(
      tokens > tokensReverse || tokensReverse.sub(tokens) < tokens.div(1000),
      'ratio wrong'
    );

    // Update state
    weiRaised = weiRaised.add(buyAmount);
    _walletInvest[beneficiary] = _walletInvest[beneficiary].add(buyAmount);

    _processLiquidity(beneficiary, investAmount, tokens);

    _forwardFunds(buyAmount);
  }

  /**
   * @dev Low level token liquidity staking ***DO NOT OVERRIDE***
   *
   * This function has a non-reentrancy guard, so it shouldn't be called by
   * another `nonReentrant` function.
   *
   * approve() must be called before to let us transfer msgsenders tokens.
   *
   * @param beneficiary Recipient of the token purchase
   */
  function addLiquidity(address payable beneficiary)
    public
    payable
    nonReentrant
    onlyWhileOpen
  {
    uint256 weiAmount = msg.value;
    require(beneficiary != address(0), 'beneficiary is the zero address');
    require(weiAmount != 0, 'weiAmount is 0');

    // Calculate number of tokens
    uint256 tokenAmount = weiAmount.mul(tokenForLp).div(ethForLp);
    require(token.balanceOf(_msgSender()) >= tokenAmount, 'insufficient token');

    // Get the tokens from msg.sender
    token.safeTransferFrom(_msgSender(), address(this), tokenAmount);

    // Step 1: add liquidity
    uint256 lpToken =
      _addLiquidity(address(this), beneficiary, weiAmount, tokenAmount);

    // Step 2: we now own the liquidity tokens, stake them
    uniV2Pair.approve(address(stakeFarm), lpToken);
    stakeFarm.stake(lpToken);

    // Step 3: transfer the stake to the user
    stakeFarm.transfer(beneficiary, lpToken);

    emit Staked(beneficiary, lpToken);
  }

  /**
   * @dev Finalize presale / create liquidity pool
   */
  function finalizePresale() external {
    require(hasClosed(), 'not closed');

    uint256 ethBalance = address(this).balance;
    require(ethBalance > 0, 'no eth balance');

    // Calculate how many token we add into liquidity pool
    uint256 tokenToLp = (ethBalance.mul(tokenForLp)).div(ethForLp);

    // Calculate amount unsold token
    uint256 tokenUnsold = cap.sub(weiRaised).mul(rate);

    // Mint token we spend
    require(
      token.mint(address(this), tokenToLp.add(tokenUnsold)),
      'minting failed'
    );

    _addLiquidity(_wallet, _wallet, ethBalance, tokenToLp);

    // Transfer all tokens from this contract to _wallet
    uint256 tokenInContract = token.balanceOf(address(this));
    if (tokenInContract > 0) token.transfer(_wallet, tokenInContract);

    // Finally whitelist uniV2 LP pool on token contract
    token.enableUniV2Pair(true);
  }

  /**
   * @dev Added to support recovering LP Rewards from other systems to be distributed to holders
   */
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external {
    require(msg.sender == _wallet, 'restricted to wallet');
    require(hasClosed(), 'not closed');
    // Cannot recover the staking token or the rewards token
    require(tokenAddress != address(token), 'native tokens unrecoverable');

    IERC20(tokenAddress).safeTransfer(_wallet, tokenAmount);
  }

  /**
   * @dev Change the closing time which gives you the possibility
   * to either shorten or enlarge the presale period
   */
  function setClosingTime(uint256 newClosingTime) external {
    require(msg.sender == _wallet, 'restricted to wallet');
    require(newClosingTime > openingTime, 'close < open');

    closingTime = newClosingTime;
  }

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert
   * state when conditions are not met
   *
   * Use `super` in contracts that inherit from Crowdsale to extend their validations.
   *
   * Example from CappedCrowdsale.sol's _preValidatePurchase method:
   *     super._preValidatePurchase(beneficiary, weiAmount);
   *     require(weiRaised().add(weiAmount) <= cap);
   *
   * @param beneficiary Address performing the token purchase
   * @param weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(address beneficiary, uint256 weiAmount)
    internal
    view
    onlyWhileOpen
  {
    require(beneficiary != address(0), 'beneficiary zero address');
    require(weiAmount != 0, 'weiAmount is 0');
    require(weiRaised.add(weiAmount) <= cap, 'cap exceeded');
    require(weiAmount >= investMin, 'invest too small');
    require(
      _walletInvest[beneficiary].add(weiAmount) <= walletCap,
      'wallet-cap exceeded'
    );

    // Silence state mutability warning without generating bytecode - see
    // https://github.com/ethereum/solidity/issues/2691
    this;
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed
   *
   * Doesn't necessarily emit/send tokens.
   *
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount)
    internal
  {
    require(token.mint(address(this), _tokenAmount), 'minting failed');
    token.transfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed
   *
   * This function adds liquidity and stakes the liquidity in our initial farm.
   *
   * @param beneficiary Address receiving the tokens
   * @param ethAmount Amount of ETH provided
   * @param tokenAmount Number of tokens to be purchased
   */
  function _processLiquidity(
    address payable beneficiary,
    uint256 ethAmount,
    uint256 tokenAmount
  ) internal {
    require(token.mint(address(this), tokenAmount), 'minting failed');

    // Step 1: add liquidity
    uint256 lpToken =
      _addLiquidity(address(this), beneficiary, ethAmount, tokenAmount);

    // Step 2: we now own the liquidity tokens, stake them
    // Allow stakeFarm to own our tokens
    uniV2Pair.approve(address(stakeFarm), lpToken);
    stakeFarm.stake(lpToken);

    // Step 3: transfer the stake to the user
    stakeFarm.transfer(beneficiary, lpToken);

    emit Staked(beneficiary, lpToken);
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   *
   * @param weiAmount Value in wei to be converted into tokens
   *
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
    return weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds(uint256 weiAmount) internal {
    _wallet.transfer(weiAmount.div(2));
  }

  function _addLiquidity(
    address tokenOwner,
    address payable remainingReceiver,
    uint256 ethBalance,
    uint256 tokenBalance
  ) internal returns (uint256) {
    // Add Liquidity, receiver of pool tokens is _wallet
    token.approve(address(uniV2Router), tokenBalance);

    (uint256 amountToken, uint256 amountETH, uint256 liquidity) =
      uniV2Router.addLiquidityETH{ value: ethBalance }(
        address(token),
        tokenBalance,
        tokenBalance.mul(90).div(100),
        ethBalance.mul(90).div(100),
        tokenOwner,
        // solhint-disable-next-line not-rely-on-time
        block.timestamp + 86400
      );

    emit LiquidityAdded(tokenOwner, amountToken, amountETH, liquidity);

    // Send remaining ETH to the team wallet
    if (amountETH < ethBalance)
      remainingReceiver.transfer(ethBalance.sub(amountETH));

    // Send remaining WOWS token to team wallet
    if (amountToken < tokenBalance)
      token.transfer(remainingReceiver, tokenBalance.sub(amountToken));

    return liquidity;
  }
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title IStakeFarm
 *
 * @dev IStakeFarm is the business logic interface to staking farms.
 */

interface IStakeFarm {
  /**
   * @dev Stake amount of ERC20 tokens and earn rewards
   */
  function stake(uint256 amount) external;

  /**
   * @dev Unstake amount of previous staked tokens, rewards will not be claimed
   */
  function unstake(uint256 amount) external;

  /**
   * @dev Claim rewards harvested during stake time
   */
  function getReward() external;

  /**
   * @dev Unstake and getRewards in a single step
   */
  function exit() external;

  /**
   * @dev Transfer amount of stake from msg.sender to recipient.
   */
  function transfer(address recipient, uint256 amount) external;
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IERC20WolfMintable is IERC20 {
  function mint(address account, uint256 amount) external returns (bool);

  function enableUniV2Pair(bool enable) external;
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

contract AddressBook {
  bytes32 public constant TEAM_WALLET = 'TEAM_WALLET';
  bytes32 public constant MARKETING_WALLET = 'MARKETING_WALLET';
  bytes32 public constant UNISWAP_V2_ROUTER02 = 'UNISWAP_V2_ROUTER02';
  bytes32 public constant WETH_WOWS_STAKE_FARM = 'WETH_WOWS_STAKE_FARM';
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

interface IAddressRegistry {
  /**
   * @dev Set an abitrary key / address pair into the registry
   */
  function setRegistryEntry(bytes32 _key, address _location) external;

  /**
   * @dev Get an registry enty with by key, returns 0 address if not existing
   */
  function getRegistryEntry(bytes32 _key) external view returns (address);
}