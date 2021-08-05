/**
 *Submitted for verification at Etherscan.io on 2020-11-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

interface IUniswapV2Router {
    function factory() external pure returns (address);

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

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// a library for performing various math operations
library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

interface Balancer {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external;
    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external;
    function swapExactAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut,
        uint maxPrice
    ) external returns (uint tokenAmountOut, uint spotPriceAfter);
    function swapExactAmountOut(
        address tokenIn,
        uint maxAmountIn,
        address tokenOut,
        uint tokenAmountOut,
        uint maxPrice
    ) external returns (uint tokenAmountIn, uint spotPriceAfter);
    function joinswapExternAmountIn(address tokenIn, uint tokenAmountIn, uint minPoolAmountOut) external returns (uint poolAmountOut);
    function exitswapPoolAmountIn(address tokenOut, uint poolAmountIn, uint minAmountOut) external returns (uint tokenAmountOut);
    function getBalance(address token) external view returns (uint);
    function totalSupply() external view returns (uint256);
    function getTotalDenormalizedWeight() external view returns (uint);
    function getNormalizedWeight(address token) external view returns (uint);
    function getDenormalizedWeight(address token) external view returns (uint);
}

interface OneSplitAudit {
    function swap(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256 flags
    )
        external
        payable
        returns(uint256 returnAmount);

    function getExpectedReturn(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    )
        external
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        );
}

interface ILpPairConverter {
    function lpPair() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);

    function accept(address _input) external view returns (bool);
    function get_virtual_price() external view returns (uint);

    function convert_rate(address _input, address _output, uint _inputAmount) external view returns (uint _outputAmount);
    function calc_add_liquidity(uint _amount0, uint _amount1) external view returns (uint);
    function calc_remove_liquidity(uint _shares) external view returns (uint _amount0, uint _amount1);

    function convert(address _input, address _output, address _to) external returns (uint _outputAmount);
    function add_liquidity(address _to) external returns (uint _outputAmount);
    function remove_liquidity(address _to) external returns (uint _amount0, uint _amount1);
}

interface IVaultMaster {
    function bank(address) view external returns (address);
    function isVault(address) view external returns (bool);
    function isController(address) view external returns (bool);
    function isStrategy(address) view external returns (bool);

    function slippage(address) view external returns (uint);
    function convertSlippage(address _input, address _output) view external returns (uint);

    function valueToken() view external returns (address);
    function govVault() view external returns (address);
    function insuranceFund() view external returns (address);
    function performanceReward() view external returns (address);

    function govVaultProfitShareFee() view external returns (uint);
    function gasFee() view external returns (uint);
    function insuranceFee() view external returns (uint);

    function withdrawalProtectionFee() view external returns (uint);
}

library ConverterHelper {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    function bmul(uint a, uint b)
    internal pure
    returns (uint)
    {
        uint c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint c1 = c0 + (1e18 / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint c2 = c1 / 1e18;
        return c2;
    }

    function bdiv(uint a, uint b)
    internal pure
    returns (uint)
    {
        require(b != 0, "ERR_DIV_ZERO");
        uint c0 = a * 1e18;
        require(a == 0 || c0 / a == 1e18, "ERR_DIV_INTERNAL");
        // bmul overflow
        uint c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL");
        //  badd require
        uint c2 = c1 / b;
        return c2;
    }

    function calculateAddBptLiquidity(Balancer _balPool,
        address _token0, address _token1,
        uint _amount0, uint _amount1) internal view returns (uint _poolAmountOut) {
        require(_amount0 > 0 && _amount1 > 0, "Insufficient liquidity amount");
        uint _balTotalSupply = _balPool.totalSupply();
        uint _balToken0Amount = _balPool.getBalance(_token0);
        uint _balToken1Amount = _balPool.getBalance(_token1);
        uint _poolOutByAmount0 = bdiv(bmul(_amount0, _balTotalSupply), _balToken0Amount);
        uint _poolOutByAmount1 = bdiv(bmul(_amount1, _balTotalSupply), _balToken1Amount);
        //        uint _poolOutByAmount0 = bmul(bdiv(_amount0, _balToken0Amount), _balTotalSupply);
        //        uint _poolOutByAmount1 = bmul(bdiv(_amount1, _balToken1Amount), _balTotalSupply);
        return bmul(Math.min(_poolOutByAmount0, _poolOutByAmount1), 1e18 - 1e10);
    }

    function calculateRemoveBptLiquidity(Balancer _balPool, uint _poolAmountIn,
        address _token0, address _token1
    ) internal view returns (uint _amount0, uint _amount1) {
        uint _balTotalSupply = _balPool.totalSupply();
        uint _balToken0Amount = _balPool.getBalance(_token0);
        uint _balToken1Amount = _balPool.getBalance(_token1);
        _amount0 = bdiv(bmul(_balToken0Amount, _poolAmountIn), _balTotalSupply);
        _amount1 = bdiv(bmul(_balToken1Amount, _poolAmountIn), _balTotalSupply);
    }

    function calculateAddUniLpLiquidity(IUniswapV2Pair _pair, uint _amount0, uint _amount1) internal view returns (uint) {
        uint _pairTotalSupply = _pair.totalSupply();
        uint _reserve0 = 0;
        uint _reserve1 = 0;
        (_reserve0, _reserve1,) = _pair.getReserves();
        return Math.min(_amount0.mul(_pairTotalSupply) / _reserve0, _amount1.mul(_pairTotalSupply) / _reserve1);
    }

    function calculateRemoveUniLpLiquidity(IUniswapV2Pair _pair, uint _shares) internal view returns (uint _amount0, uint _amount1) {
        uint _pairSupply = _pair.totalSupply();
        uint _reserve0 = 0;
        uint _reserve1 = 0;
        (_reserve0, _reserve1,) = _pair.getReserves();
        _amount0 = _shares.mul(_reserve0).div(_pairSupply);
        _amount1 = _shares.mul(_reserve1).div(_pairSupply);
        return (_amount0, _amount1);
    }

    function skim(address _token, address _to) internal returns (uint) {
        uint _amount = IERC20(_token).balanceOf(address(this));
        if (_amount > 0) {
            IERC20(_token).safeTransfer(_to, _amount);
        }
        return _amount;
    }

    function addUniLpLiquidity(IUniswapV2Router _router, IUniswapV2Pair _pair, address _to) internal returns (uint _outputAmount) {
        address _token0 = _pair.token0();
        address _token1 = _pair.token1();
        uint _amount0 = IERC20(_token0).balanceOf(address(this));
        uint _amount1 = IERC20(_token1).balanceOf(address(this));
        require(_amount0 > 0 && _amount1 > 0, "Insufficient liquidity amount");
        (,, _outputAmount) = _router.addLiquidity(_token0, _token1, _amount0, _amount1, 0, 0, _to, block.timestamp + 1);
        skim(_token0, _to);
        skim(_token1, _to);
    }

    function removeBptLiquidity(Balancer _pool) internal returns (uint _poolAmountIn) {
        uint[] memory _minAmountsOut = new uint[](2);
        _poolAmountIn = _pool.balanceOf(address(this));
        require(_poolAmountIn > 0, "Insufficient liquidity amount");
        _pool.exitPool(_poolAmountIn, _minAmountsOut);
    }

    function removeUniLpLiquidity(IUniswapV2Router _router, IUniswapV2Pair _pair, address _to) internal returns (uint _amount0, uint _amount1) {
        uint _liquidityAmount = _pair.balanceOf(address(this));
        require(_liquidityAmount > 0, "Insufficient liquidity amount");
        return _router.removeLiquidity(_pair.token0(), _pair.token1(), _liquidityAmount, 0, 0, _to, block.timestamp + 1);
    }

    function convertRateUniToUniInternal(address _input, address _output, uint _inputAmount) internal view returns (uint) {
        IUniswapV2Pair _inputPair = IUniswapV2Pair(_input);
        IUniswapV2Pair _outputPair = IUniswapV2Pair(_output);
        uint _amount0;
        uint _amount1;
        (_amount0, _amount1) = calculateRemoveUniLpLiquidity(_inputPair, _inputAmount);
        return calculateAddUniLpLiquidity(_outputPair, _amount0, _amount1);
    }

    function convertUniToUniLp(address _input, address _output, IUniswapV2Router _inputRouter, IUniswapV2Router _outputRouter, address _to) internal returns (uint) {
        IUniswapV2Pair _inputPair = IUniswapV2Pair(_input);
        IUniswapV2Pair _outputPair = IUniswapV2Pair(_output);
        removeUniLpLiquidity(_inputRouter, _inputPair, address(this));
        return addUniLpLiquidity(_outputRouter, _outputPair, _to);
    }

    function convertUniLpToBpt(address _input, address _output, IUniswapV2Router _inputRouter, address _to) internal returns (uint) {
        IUniswapV2Pair _inputPair = IUniswapV2Pair(_input);
        Balancer _balPool = Balancer(_output);
        address _token0 = _inputPair.token0();
        address _token1 = _inputPair.token1();
        uint _amount0;
        uint _amount1;
        (_amount0, _amount1) = removeUniLpLiquidity(_inputRouter, _inputPair, address(this));
        uint _balPoolAmountOut = calculateAddBptLiquidity(_balPool, _token0, _token1, _amount0, _amount1);
        uint _outputAmount = addBalancerLiquidity(_balPool, _balPoolAmountOut, _to);
        skim(_token0, _to);
        skim(_token1, _to);
        return _outputAmount;
    }

    function convertBPTToUniLp(address _input, address _output, IUniswapV2Router _outputRouter, address _to) internal returns (uint) {
        removeBptLiquidity(Balancer(_input));
        IUniswapV2Pair _outputPair = IUniswapV2Pair(_output);
        return addUniLpLiquidity(_outputRouter, _outputPair, _to);
    }

    function convertRateUniLpToBpt(address _input, address _lpBpt, uint _inputAmount) internal view returns (uint) {
        IUniswapV2Pair _inputPair = IUniswapV2Pair(_input);
        uint _amount0;
        uint _amount1;
        (_amount0, _amount1) = calculateRemoveUniLpLiquidity(_inputPair, _inputAmount);
        return calculateAddBptLiquidity(Balancer(_lpBpt), _inputPair.token0(), _inputPair.token1(), _amount0, _amount1);
    }

    function convertRateBptToUniLp(address _lpBpt, address _output, uint _inputAmount) internal view returns (uint) {
        IUniswapV2Pair _outputPair = IUniswapV2Pair(_output);
        uint _amount0;
        uint _amount1;
        (_amount0, _amount1) = calculateRemoveBptLiquidity(Balancer(_lpBpt), _inputAmount, _outputPair.token0(), _outputPair.token1());
        return calculateAddUniLpLiquidity(_outputPair, _amount0, _amount1);
    }

    function addBalancerLiquidity(Balancer _pool, uint _poolAmountOut, address _to) internal returns (uint _outputAmount) {
        uint[] memory _maxAmountsIn = new uint[](2);
        _maxAmountsIn[0] = type(uint256).max;
        _maxAmountsIn[1] = type(uint256).max;
        _pool.joinPool(_poolAmountOut, _maxAmountsIn);
        return skim(address(_pool), _to);
    }
}

interface IDecimals {
    function decimals() external view returns (uint8);
}

abstract contract BaseConverter is ILpPairConverter {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public governance;

    IUniswapV2Router public uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router public sushiswapRouter = IUniswapV2Router(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    address public lpUni;
    address public lpSlp;
    address public lpBpt;

    // To calculate virtual_price (dollar value)
    OneSplitAudit public oneSplitAudit = OneSplitAudit(0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E);
    IERC20 public tokenUSDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    uint private unlocked = 1;
    uint public preset_virtual_price = 0;

    modifier lock() {
        require(unlocked == 1, 'Converter: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor (
        IUniswapV2Router _uniswapRouter,
        IUniswapV2Router _sushiswapRouter,
        address _lpUni, address _lpSlp, address _lpBpt,
        OneSplitAudit _oneSplitAudit,
        IERC20 _usdc
    ) public {
        if (address(_uniswapRouter) != address(0)) uniswapRouter = _uniswapRouter;
        if (address(_sushiswapRouter) != address(0)) sushiswapRouter = _sushiswapRouter;

        lpUni = _lpUni;
        lpSlp = _lpSlp;
        lpBpt = _lpBpt;

        address token0_ = IUniswapV2Pair(lpUni).token0();
        address token1_ = IUniswapV2Pair(lpUni).token1();

        IERC20(lpUni).safeApprove(address(uniswapRouter), type(uint256).max);
        IERC20(token0_).safeApprove(address(uniswapRouter), type(uint256).max);
        IERC20(token1_).safeApprove(address(uniswapRouter), type(uint256).max);

        IERC20(lpSlp).safeApprove(address(sushiswapRouter), type(uint256).max);
        IERC20(token0_).safeApprove(address(sushiswapRouter), type(uint256).max);
        IERC20(token1_).safeApprove(address(sushiswapRouter), type(uint256).max);

        IERC20(token0_).safeApprove(address(lpBpt), type(uint256).max);
        IERC20(token1_).safeApprove(address(lpBpt), type(uint256).max);

        if (address(_oneSplitAudit) != address(0)) oneSplitAudit = _oneSplitAudit;
        if (address(_usdc) != address(0)) tokenUSDC = _usdc;

        governance = msg.sender;
    }

    function getName() public virtual pure returns (string memory);

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function approveForSpender(IERC20 _token, address _spender, uint _amount) external {
        require(msg.sender == governance, "!governance");
        _token.safeApprove(_spender, _amount);
    }

    function set_preset_virtual_price(uint _preset_virtual_price) public {
        require(msg.sender == governance, "!governance");
        preset_virtual_price = _preset_virtual_price;
    }

    /**
     * This function allows governance to take unsupported tokens out of the contract. This is in an effort to make someone whole, should they seriously mess up.
     * There is no guarantee governance will vote to return these. It also allows for removal of airdropped tokens.
     */
    function governanceRecoverUnsupported(IERC20 _token, uint256 amount, address to) external {
        require(msg.sender == governance, "!governance");
        _token.transfer(to, amount);
    }
}

contract SushiswapLpPairConverter_EthWbtc is BaseConverter {
    // lpUni = 0xBb2b8038a1640196FbE3e38816F3e67Cba72D940
    // lpSlp = 0xCEfF51756c56CeFFCA006cD410B03FFC46dd3a58
    // lpBpt = 0x1efF8aF5D577060BA4ac8A29A13525bb0Ee2A3D5
    constructor (
        IUniswapV2Router _uniswapRouter,
        IUniswapV2Router _sushiswapRouter,
        address _lpUni, address _lpSlp, address _lpBpt,
        OneSplitAudit _oneSplitAudit,
        IERC20 _usdc
    ) public BaseConverter(_uniswapRouter, _sushiswapRouter, _lpUni, _lpSlp, _lpBpt, _oneSplitAudit, _usdc) {
    }

    function getName() public override pure returns (string memory) {
        return "SushiswapLpPairConverter:EthWbtc";
    }

    function lpPair() external override view returns (address) {
        return lpSlp;
    }

    function token0() public override view returns (address) {
        return IUniswapV2Pair(lpSlp).token0();
    }

    function token1() public override view returns (address) {
        return IUniswapV2Pair(lpSlp).token1();
    }

    function accept(address _input) external override view returns (bool) {
        return (_input == lpUni) || (_input == lpSlp) || (_input == lpBpt);
    }

    function get_virtual_price() external override view returns (uint) {
        if (preset_virtual_price > 0) return preset_virtual_price;
        IUniswapV2Pair _pair = IUniswapV2Pair(lpSlp);
        uint _totalSupply = _pair.totalSupply();
        IDecimals _token0 = IDecimals(_pair.token0());
        uint _reserve0 = 0;
        (_reserve0,,) = _pair.getReserves();
        uint _amount = uint(10) ** _token0.decimals();
        // 0.1% pool
        if (_amount > _reserve0.div(1000)) {
            _amount = _reserve0.div(1000);
        }
        uint _returnAmount;
        (_returnAmount,) = oneSplitAudit.getExpectedReturn(address(_token0), address(tokenUSDC), _amount, 1, 0);
        // precision 1e18
        return _returnAmount.mul(2).mul(_reserve0).div(_amount).mul(10 ** 30).div(_totalSupply);
    }

    function convert_rate(address _input, address _output, uint _inputAmount) external override view returns (uint _outputAmount) {
        if (_input == _output) return 1;
        if (_inputAmount == 0) return 0;
        if ((_input == lpSlp && _output == lpUni) || (_input == lpUni && _output == lpSlp)) {// convert UNI <-> SLP
            return ConverterHelper.convertRateUniToUniInternal(_input, _output, _inputAmount);
        }
        if (_input == lpSlp && _output == lpBpt) {// convert SLP -> BPT
            return ConverterHelper.convertRateUniLpToBpt(_input, _output, _inputAmount);
        }
        if (_input == lpBpt && _output == lpSlp) {// convert BPT -> SLP
            return ConverterHelper.convertRateBptToUniLp(_input, _output, _inputAmount);
        }
        revert("Not supported");
    }

    function calc_add_liquidity(uint _amount0, uint _amount1) external override view returns (uint) {
        return ConverterHelper.calculateAddUniLpLiquidity(IUniswapV2Pair(lpSlp), _amount0, _amount1);
    }

    function calc_remove_liquidity(uint _shares) external override view returns (uint _amount0, uint _amount1) {
        return ConverterHelper.calculateRemoveUniLpLiquidity(IUniswapV2Pair(lpSlp), _shares);
    }

    function convert(address _input, address _output, address _to) external lock override returns (uint _outputAmount) {
        require(_input != _output, "same asset");
        if (_input == lpUni && _output == lpSlp) {// convert UNI -> SLP
            return ConverterHelper.convertUniToUniLp(_input, _output, uniswapRouter, sushiswapRouter, _to);
        }
        if (_input == lpSlp && _output == lpUni) {// convert SLP -> SLP
            return ConverterHelper.convertUniToUniLp(_input, _output, sushiswapRouter, uniswapRouter, _to);
        }
        if (_input == lpSlp && _output == lpBpt) {// convert SLP -> BPT
            return ConverterHelper.convertUniLpToBpt(_input, _output, sushiswapRouter, _to);
        }
        if (_input == lpBpt && _output == lpSlp) {// convert BPT -> SLP
            return ConverterHelper.convertBPTToUniLp(_input, _output, sushiswapRouter, _to);
        }
        revert("Not supported");
    }

    function add_liquidity(address _to) external lock override returns (uint _outputAmount) {
        return ConverterHelper.addUniLpLiquidity(sushiswapRouter, IUniswapV2Pair(lpSlp), _to);
    }

    function remove_liquidity(address _to) external lock override returns (uint _amount0, uint _amount1) {
        return ConverterHelper.removeUniLpLiquidity(sushiswapRouter, IUniswapV2Pair(lpSlp), _to);
    }
}