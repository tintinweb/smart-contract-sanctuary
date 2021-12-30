/**
 *Submitted for verification at polygonscan.com on 2021-12-30
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: interfaces/uniswap/Uni.sol


pragma solidity ^0.6.11;

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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

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

// File: interfaces/curve/ICurve.sol


pragma solidity ^0.6.11;

interface ICurveGauge {
    function deposit(uint256 _value) external;

    function deposit(uint256 _value, address addr) external;

    function balanceOf(address arg0) external view returns (uint256);

    function withdraw(uint256 _value) external;

    function withdraw(uint256 _value, bool claim_rewards) external;

    function claim_rewards() external;

    function claim_rewards(address addr) external;

    function claimable_tokens(address addr) external returns (uint256);

    function claimable_reward(address addr) external view returns (uint256);

    function claimable_reward(address, address) external view returns (uint256);

    function integrate_fraction(address arg0) external view returns (uint256);
}

interface ICurveStableSwapREN {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
    external;

    function remove_liquidity_imbalance(
        uint256[2] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts)
    external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function balances(uint256) external view returns (uint256);
}

interface ICurveStableSwapAM3CRV {
    function get_virtual_price() external view returns (uint256);

    function fee() external view returns (uint256);

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount, bool use_underlying)
    external;

    function remove_liquidity_imbalance(
        uint256[2] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount, bool _use_underlying) external;

    function remove_liquidity(uint256 _amount, uint256[3] calldata amounts)
    external;

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
    external view
    returns (uint256);

    function calc_token_amount(uint256[3] calldata amounts, bool _is_deposit)
    external view
    returns (uint256);

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function balances(uint256) external view returns (uint256);
}

interface ICurveStableSwapAMIM {
    function get_virtual_price() external view returns (uint256);

    function fee() external view returns (uint256);

    function add_liquidity(address _pool, uint256[3] calldata _deposit_amounts, uint256 _min_mint_amount)
    external;

    function remove_liquidity_one_coin(address _pool, uint256 _token_amount, int128 i, uint256 _min_amount) external;

    function calc_withdraw_one_coin(address _pool, uint256 _token_amount, int128 i)
    external view
    returns (uint256);

    function calc_token_amount(address _pool, uint256[3] calldata amounts, bool _is_deposit)
    external view
    returns (uint256);

}

interface ICurveStableSwapMIM {
    function get_virtual_price() external view returns (uint256);

    function fee() external view returns (uint256);

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount)
    external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts)
    external;

    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount) external;

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
    external view
    returns (uint256);

    function calc_token_amount(uint256[3] calldata amounts, bool _is_deposit)
    external view
    returns (uint256);

    function balances(uint256) external view returns (uint256);
}

interface ICurveStableSwapTricrypto {
    function get_virtual_price() external view returns (uint256);

    function fee() external view returns (uint256);

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount)
    external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts)
    external;

    function remove_liquidity_one_coin(uint256 _token_amount, uint256 i, uint256 _min_amount) external;

    function calc_withdraw_one_coin(uint256 _token_amount, uint256 i)
    external view
    returns (uint256);

    function calc_token_amount(uint256[3] calldata amounts)
    external view
    returns (uint256);

    function balances(uint256) external view returns (uint256);
}

interface ICurveStableSwapAave {
    function get_virtual_price() external view returns (uint256);

    function fee() external view returns (uint256);

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount, bool use_underlying)
    external;

    function remove_liquidity_imbalance(
        uint256[2] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts)
    external;

    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount, bool _use_underlying) external;

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
    external view
    returns (uint256);

    function calc_token_amount(uint256[3] calldata amounts, bool _is_deposit)
    external view
    returns (uint256);

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function balances(uint256) external view returns (uint256);
}

interface ICurveStableSwapTricrypto5 {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[5] calldata amounts, uint256 min_mint_amount)
    external;

    function remove_liquidity_imbalance(
        uint256[2] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts)
    external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function balances(uint256) external view returns (uint256);
}

// File: interfaces/nuke/IEpicVault.sol


pragma solidity ^0.6.11;

interface IEpicVault {
    function token() external view returns (address);

    function rewards() external view returns (address);

    function underlying() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function controller() external view returns (address);

    function governance() external view returns (address);

    function getPricePerFullShare() external view returns (uint256);

    function deposit(uint256) external;

    function depositAll() external;

    function withdraw(uint256) external;

    function withdrawAll() external;
}

// File: interfaces/pickle/Minichef.sol


pragma solidity ^0.6.11;

interface IMiniChefV2 {
    function deposit ( uint256 pid, uint256 amount, address to ) external;
    function emergencyWithdraw ( uint256 pid, address to ) external;
    function harvest ( uint256 pid, address to ) external;
    function lpToken ( uint256 ) external view returns ( address );
    function pendingPickle ( uint256 _pid, address _user ) external view returns ( uint256 pending );
    function poolInfo ( uint256 ) external view returns ( uint128 accSushiPerShare, uint64 lastRewardTime, uint64 allocPoint );
    function poolLength (  ) external view returns ( uint256 pools );
    function userInfo ( uint256, address ) external view returns ( uint256 amount, int256 rewardDebt );
    function withdraw ( uint256 pid, uint256 amount, address to ) external;
    function withdrawAndHarvest ( uint256 pid, uint256 amount, address to ) external;
}

// File: interfaces/pickle/IVault.sol


pragma solidity ^0.6.11;

interface IPickleVault {
    function token() external view returns (address);

    function underlying() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function controller() external view returns (address);

    function governance() external view returns (address);

    function getRatio() external view returns (uint256);

    function deposit(uint256) external;

    function depositAll() external;

    function withdraw(uint256) external;

    function withdrawAll() external;
}

// File: contracts/EpicStrategy_Polygon_Pickle_AM3CRV_USDC.sol


pragma solidity ^0.6.11;










contract EpicStrategy_Polygon_Pickle_AM3CRV_USDC{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    //tokens needed
    address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address public constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address public constant PICKLE = 0x2b88aD57897A8b496595925F43048301C37615Da;

    address public constant CURVE_LP_TOKEN = 0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171; //Curve.fi amDAI/amUSDC/amUSDT (am3CRV)
    address public constant PICKLE_LP_TOKEN = 0x261b5619d85B710f1c2570b65ee945975E2cC221;

    //The token we deposit into the Pool
    address public constant want = USDC;

    //The reward
    address public reward = PICKLE;

    // We add liquidity here
    address public constant CURVE_POOL = 0x445FE580eF8d70FF569aB36e80c647af338db351;
    address public constant PICKLE_POOL = PICKLE_LP_TOKEN;
    address public constant PICKLE_CHEF = 0x20B2a3fc7B13cA0cCf7AF81A68a14CB3116E8749;
    uint256 public constant pid = 4;

    address public constant SUSHISWAP_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    uint256 public constant MAX_BPS = 10000;
    uint256 public sl = 100;

    uint256 public performanceFee = 1000;
    uint256 public constant performanceMax = 10000;

    uint256 public withdrawalFee = 50;
    uint256 public constant withdrawalMax = 10000;

    address public governance;
    address public strategist;
    address public vault;

    uint256 public lifetimeEarned = 0;

    event Harvest(uint256 wantEarned, uint256 lifetimeEarned);

    constructor(address _vault) public {
        governance = msg.sender;
        strategist = msg.sender;
        vault = _vault;

    }

    function doApprovals() public {
        IERC20(CURVE_LP_TOKEN).safeApprove(PICKLE_POOL,type(uint256).max);
        IERC20(PICKLE_LP_TOKEN).safeApprove(PICKLE_CHEF,type(uint256).max);
        IERC20(reward).safeApprove(SUSHISWAP_ROUTER,type(uint256).max);
        IERC20(USDC).safeApprove(CURVE_POOL,type(uint256).max);
        IERC20(USDT).safeApprove(CURVE_POOL,type(uint256).max);
        IERC20(DAI).safeApprove(CURVE_POOL,type(uint256).max);
    }

    function getName() external pure returns (string memory) {
        return "EpicStrategy_Polygon_Pickle_AM3CRV_USDC";
    }

    /// @dev Balance of want currently held in strategy positions
    function balanceOfPool() public view returns (uint256) {
        //Balance of PICKLE_LP_TOKEN
        (uint256 amount, ) = IMiniChefV2(PICKLE_CHEF).userInfo(pid, address(this));

        if (amount > 0) {
            //Balance of Curve LP
            uint256 amountCRVLP = amount.mul(IPickleVault(PICKLE_POOL).getRatio()).div(1e18);

            //Balance of USDC / this is taking into account fees...
            uint256 amountUSDC = ICurveStableSwapAM3CRV(CURVE_POOL).calc_withdraw_one_coin(amountCRVLP, 1);

            return amountUSDC;
        } else {
            return 0;
        }

    }

    function balanceOf() public virtual view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function checkPendingReward() public view returns (uint256) {
        return IMiniChefV2(PICKLE_CHEF).pendingPickle(pid, address(this));
    }

    function deposit() public {

        //Add USDC liquidity into CURVE
        ICurveStableSwapAM3CRV(CURVE_POOL).add_liquidity(
            [0, IERC20(USDC).balanceOf(address(this)), 0],
            0,
            true
        );

        //Add the Curve LP into Pickle Vault
        IPickleVault(PICKLE_POOL).deposit(IERC20(CURVE_LP_TOKEN).balanceOf(address(this)));

        //Stake into Pickle Chef
        IMiniChefV2(PICKLE_CHEF).deposit(pid, IERC20(PICKLE_LP_TOKEN).balanceOf(address(this)), address(this));
    }


    function _withdrawSome(uint256 _amount) internal returns (uint256) {

        if (_amount > balanceOfPool()) {
            _amount = balanceOfPool();
        }

        uint256 _before = IERC20(want).balanceOf(address(this));

        //Figure out how many CRVLP
        uint256 _amountCRVLP = ICurveStableSwapAM3CRV(CURVE_POOL).calc_token_amount([0, _amount, 0], false);

        //multiply Curve _amount by pps to get the tokens
        uint256 pps = IPickleVault(PICKLE_POOL).getRatio();
        uint256 _amountInPickles = _amountCRVLP.mul(1e18).div(pps);

        //check that we have enough
        (uint256 amountOfPickles, ) = IMiniChefV2(PICKLE_CHEF).userInfo(pid, address(this));
        if (_amountInPickles > amountOfPickles) {
            _amountInPickles = amountOfPickles;
        }

        //WD from Pickle Chef
        IMiniChefV2(PICKLE_CHEF).withdraw(pid, _amountInPickles, address(this));
        //WD from Pickle Vault
        IPickleVault(PICKLE_POOL).withdraw(IERC20(PICKLE_LP_TOKEN).balanceOf(address(this)));
        //WD from CURVE_POOL
        ICurveStableSwapAM3CRV(CURVE_POOL).remove_liquidity_one_coin(
            IERC20(CURVE_LP_TOKEN).balanceOf(address(this)),
            1,
            0,
            true
        );

        uint256 _after = IERC20(want).balanceOf(address(this));
        return _after.sub(_before);
    }

    function _withdrawAll() internal {
        //Balance of PICKLE_LP_TOKEN
        (uint256 amount, ) = IMiniChefV2(PICKLE_CHEF).userInfo(pid, address(this));

        if(amount > 0) {
            //WD from Pickle Chef
            IMiniChefV2(PICKLE_CHEF).withdraw(pid, amount, address(this));
            //WD from Pickle Vault
            IPickleVault(PICKLE_POOL).withdraw(IERC20(PICKLE_LP_TOKEN).balanceOf(address(this)));
            //WD from CURVE_POOL
            ICurveStableSwapAM3CRV(CURVE_POOL).remove_liquidity_one_coin(
                IERC20(CURVE_LP_TOKEN).balanceOf(address(this)),
                1,
                0,
                true
            );
        }

    }

    function harvest() public {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");

        uint256 _before = IERC20(USDC).balanceOf(address(this));

        // figure out and claim our rewards
        IMiniChefV2(PICKLE_CHEF).harvest(pid, address(this));

        uint256 rewardsToReinvest = IERC20(reward).balanceOf(address(this)); //PICKLE

        require(rewardsToReinvest > 0 , "No Rewards to Harvest");

        //SWAP PICKLE for DAI
        address[] memory pathA = new address[](3);
        pathA[0] = reward;
        pathA[1] = DAI;
        pathA[2] = USDC;
        IUniswapRouterV2(SUSHISWAP_ROUTER).swapExactTokensForTokens(
            rewardsToReinvest,
            0,
            pathA,
            address(this),
            now
        );


        uint256 earned = IERC20(USDC).balanceOf(address(this)).sub(_before);

        /// @notice Keep this in so you get paid!
        if (earned > 0) {
            uint256 _fee = earned.mul(performanceFee).div(performanceMax);
            IERC20(USDC).safeTransfer(IEpicVault(vault).rewards(), _fee);
        }

        lifetimeEarned = lifetimeEarned.add(earned);

        /// @dev Harvest event that every strategy MUST have, see BaseStrategy
        emit Harvest(earned, lifetimeEarned);

        deposit();

    }


    //******************************
    // No need to change
    //******************************

    function setStrategist(address _strategist) external {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external {
        require(msg.sender == governance, "!governance");
        withdrawalFee = _withdrawalFee;
    }

    function setPerformanceFee(uint256 _performanceFee) external {
        require(msg.sender == governance, "!governance");
        performanceFee = _performanceFee;
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfToken(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setVault(address _vault) external {
        require(msg.sender == governance, "!governance");
        vault = _vault;
    }

    function setSlippageTolerance(uint256 _s) external {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        sl = _s;
    }

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == vault, "!vault");
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(vault, balance);
    }

    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint256 _amount) external {
        require(msg.sender == vault, "!vault");

        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        uint256 _fee = _amount.mul(withdrawalFee).div(withdrawalMax);

        //We removed the transfer of the fee to instead stay within the strategy,
        //therefor any fees generated by the withdrawal fee will be of benefit of all vault users
        //IERC20(want).safeTransfer(IController(controller).rewards(), _fee);

        IERC20(want).safeTransfer(vault, _amount.sub(_fee));
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == vault, "!vault");
        _withdrawAll();

        balance = IERC20(want).balanceOf(address(this));
        if (balance > 0) {
            IERC20(want).safeTransfer(vault, balance);
        }
    }

}