/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;


// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol
 

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

 
interface IUniswapV2Router01 {
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
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

 

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

// File: @openzeppelin/contracts/utils/Address.sol
 
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


/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}



// File: @openzeppelin/contracts/math/SafeMath.sol

 
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

 

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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

// File: @openzeppelin/contracts/utils/Context.sol
 
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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol
 

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
    constructor (){
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

 
 
contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 public _totalSupply;

    string public _name;
    string public _symbol;
    uint8 public _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory Name, string memory Symbol){
        _name = Name;
        _symbol = Symbol;
        _decimals = 9;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance")
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero")
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}


// PetCoinToken
contract PetCoinToken is BEP20 {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // The swap router, modifiable. Will be changed to PETSSwap's router when our own AMM release
    IUniswapV2Router02 public petsSwapRouter;
    // The trading pair
    address public petsSwapPair;

    // Wallet Addresses
    address public LiquidityPoolWalletAddress = 0xa34130DC361b374d038916a3D9d178c9A8C8a561;
    address public PublicSaleWalletAddress = 0x5Bc9a8e2D4Da09Ee4058Ea3d55fd86E372edE241;
    address public ReserveWalletAddress = 0x81A6e04D5924aA89dA1b53eD771498Fdfd289Ec2;
    address public TreasuryWalletAddress = 0x049a203AC85b2Bca08DfC12841162cc4BEeD42d9;
    address public CharityWalletAddress = 0x91BE73994841631f44861bc2b32d5C93C684b6d1;

    // Liquidity rate % of transfer tax
    uint256 public liquidityFee = 125;
    // Charity rate % of transfer tax
    uint256 public charityFee = 125;
    // Treasury rate % of transfer tax
    uint256 public treasuryFee = 125;
    // Transfer tax rate in basis points. (default 3.75%)
    uint256 public transferTaxRate = liquidityFee.add(charityFee).add(treasuryFee);
    // Max transfer tax rate: 10%.
    uint256 public constant MAXIMUM_TRANSFER_TAX_RATE = 1000;

    // Max transfer amount rate in basis points. (default is 0.5% of total supply)
    uint256 public maxTransferAmountRate = 50;
    // Max sale amount rate in basis points. (default is 0.25% of LP)
    uint256 public maxSaleAmountRate = 25;

    // Addresses that excluded from blacklisted, antiWhale, limitswap, fees
    mapping(address => bool) public _isBlacklisted;
    mapping(address => bool) private _excludedFromAntiWhale;
    mapping(address => bool) private _excludedFromLimitSwap;
    mapping (address => bool) private _excludedFromFees;


    // Automatic swap and liquify enabled
    bool public swapAndLiquifyEnabled = true;
    // start Block Swap
    uint256 public startBlockSwap = 91651040;
    // Min amount to liquify. (default 500 PETSs)
    uint256 public minAmountToLiquify = 500 * (10 ** 9) ;

    // In swap and liquify
    bool private _inSwapAndLiquify;
    // The operator can only update the transfer tax rate
    address private _operator;
    // limit swap enabled
    bool public limitSwap = true;
    // Minimum time between 2 swap of an user by the number of blocks. (default is 45mins)
	uint256 public timeLimitSwap = 900;
    // Info of lastswaptimeInfo.
	mapping(address => uint256) private _userInfo;

    // Additional tax rate
    uint256 public additionalTaxRate = 2000;
    // Additional tax expired block number(default is 30days)
    uint256 public bigtaxclearperiod = 864000;

    // to control selling
    bool public selling = true;
    // to control buying
    bool public buying = true;


    // Events
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event MaxTransferAmountRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event SwapAndLiquifyEnabledUpdated(address indexed operator, bool enabled);
    event StartBlockSwapUpdated(address indexed owner, uint256 block);
    event MinAmountToLiquifyUpdated(address indexed operator, uint256 previousAmount, uint256 newAmount);
    event AdditionalTaxRateUpdated(address indexed operator, uint256 previousTax, uint256 newTax);
    event PETSSwapRouterUpdated(address indexed operator, address indexed router, address indexed pair);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event ExcludeFromAntiWhale(address indexed account, bool isExcluded);
    event ExcludeFromLimitSwap(address indexed account, bool isExcluded);
    event LimitSwapUpdated(address indexed operator, bool enabled);
    event TimeLimitSwapUpdated(address indexed operator, uint256 newTimeLimit);
    event BigTaxPeriodUpdated(address indexed operator, uint256 oldBlocknumber, uint256 newBlocknumber);
    event GetToken(address indexed token, address indexed recipient, uint256 amount);
    
    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    modifier antiWhale(address from, address to, uint256 amount) {
        if (maxTransferAmount() > 0) {
            if (
                _excludedFromAntiWhale[from] == false
                && _excludedFromAntiWhale[to] == false
            ) {
                require(amount <= maxTransferAmount(), "PETS::antiWhale: Transfer amount exceeds the maxTransferAmount");
                // On Sale
                if ( from == petsSwapPair || to == petsSwapPair ) {
                    require(amount <= maxSaleAmount(), "PETS::antiWhale: Sale amount exceeds the maxSaleAmount");
                    require(startBlockSwap <= block.number, "PETS::swap: Cannot Swap at the moment");
                }
            }
        }
        _;
    }

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    modifier transferTaxFree {
        uint256 _transferTaxRate = transferTaxRate;
        transferTaxRate = 0;
        _;
        transferTaxRate = _transferTaxRate;
    }

    /**
     * @notice Constructs the PETSToken contract.
     */
    constructor()  BEP20("PetCoin", "PETS") {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);

        if(startBlockSwap == 0) {
            startBlockSwap = block.number;
        }
        // IUniswapV2Router02 _petsSwapRouter = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); 
        // // for testnet: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        // // for mainnet: 0x10ED43C718714eb63d5aA57B78B54704E256024E

        // // Create a uniswap pair for this new token
        // address _petsSwapPair = IUniswapV2Factory(_petsSwapRouter.factory())
        //     .createPair(address(this), _petsSwapRouter.WETH());

        // petsSwapRouter = _petsSwapRouter;
        // petsSwapPair = _petsSwapPair;

        // exclude from paying fees or having max transaction amount
        setExcludeFromFees(owner(), true);
        // setExcludeFromFees(LiquidityPoolWalletAddress, true);
        // setExcludeFromFees(PublicSaleWalletAddress, true);
        // setExcludeFromFees(ReserveWalletAddress, true);
        // setExcludeFromFees(TreasuryWalletAddress, true);
        // setExcludeFromFees(CharityWalletAddress, true);
        setExcludeFromFees(address(this), true);

        // exclude from antiwhale
        _excludedFromAntiWhale[msg.sender] = true;
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;
        // _excludedFromAntiWhale[LiquidityPoolWalletAddress] = true;
        // _excludedFromAntiWhale[PublicSaleWalletAddress] = true;
        // _excludedFromAntiWhale[ReserveWalletAddress] = true;
        // _excludedFromAntiWhale[TreasuryWalletAddress] = true;
        // _excludedFromAntiWhale[CharityWalletAddress] = true;

      
        /*
        *    _mint is an internal function in ERC20.sol that is only called here,
        *    and CANNOT be called ever again
        */
        // _mint(LiquidityPoolWalletAddress, 3000000000 * (10**9));
        // _mint(PublicSaleWalletAddress, 3000000000 * (10**9));
        // _mint(ReserveWalletAddress, 1500000000 * (10**9));
        // _mint(TreasuryWalletAddress, 1000000000 * (10**9));
        // _mint(CharityWalletAddress, 1000000000 * (10**9));
        _mint(owner(), 10000000000 * (10**9));
    }

    // To receive BNB from PETSSwapRouter when swapping
    receive() external payable {}

    /**
     * Overrides transfer function to meet tokenomics of PETS
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override antiWhale(sender, recipient, amount) {
        require(!_isBlacklisted[sender] && !_isBlacklisted[recipient], 'PETS: Blacklisted address');
        if(!selling && sender != owner() && sender != address(this)){
            require(recipient != petsSwapPair, "PETS: Selling disabled");
        }

        if(!buying && recipient != owner()){
            require(sender != petsSwapPair,"PETS: Buying disabled");
        }

        if (limitSwap == true && 
            ((sender == petsSwapPair &&  !_excludedFromLimitSwap[recipient]) || 
            (recipient == petsSwapPair && !_excludedFromLimitSwap[sender]))) {	
			
			address userAddress = address(0);
			if (sender == petsSwapPair){
				userAddress = recipient;
			}
			else {
				userAddress = sender;
			}

			if (userAddress != address(0)){
				if (_userInfo[userAddress] > 0) {
					uint256 lastSwap = _userInfo[userAddress];
					uint256 checkLastSwap = block.number.sub(lastSwap);
					require(checkLastSwap >= timeLimitSwap, "PETS:: Trade Too fast");					
				}																
				_userInfo[userAddress] = block.number;
			}
		}

        // swap and liquify
        if (
            swapAndLiquifyEnabled == true
            && _inSwapAndLiquify == false
            && address(petsSwapRouter) != address(0)
            && petsSwapPair != address(0)
            && sender != petsSwapPair
            && sender != owner()
            && recipient != owner()
        ) {
            swapAndLiquifyHadleFee();
        }
  
        if(transferTaxRate == 0) {
            super._transfer(sender, recipient, amount);
        } else {
            if((!_excludedFromFees[sender] && !_excludedFromFees[recipient]) ){
                uint256 AdditionaltaxAmount = 0;
                if( block.number < startBlockSwap + bigtaxclearperiod && (sender == petsSwapPair || recipient == petsSwapPair)) {
                    AdditionaltaxAmount = amount.mul(additionalTaxRate).div(10000);
                    super._transfer(sender, TreasuryWalletAddress, AdditionaltaxAmount);
                }
                uint256 taxAmount = amount.mul(transferTaxRate).div(10000);
                uint256 sendAmount = amount.sub(taxAmount).sub(AdditionaltaxAmount);
                require(amount == taxAmount + sendAmount + AdditionaltaxAmount, "PETS:: transfer: Tax value invalid");
                super._transfer(sender, address(this), taxAmount);
                super._transfer(sender, recipient, sendAmount);
            } else {
                super._transfer(sender, recipient, amount);
            }
        }
    }
    /**
     * Swap and liquity function.
     */
    function swapAndLiquifyHadleFee() private lockTheSwap transferTaxFree{
        uint256 contractTokenBalance = balanceOf(address(this));
        contractTokenBalance = contractTokenBalance > maxTransferAmount() ? maxTransferAmount() : contractTokenBalance;
        if(contractTokenBalance >= minAmountToLiquify) {
            uint256 totalfees = charityFee + treasuryFee + liquidityFee;
            uint256 charityTokens = contractTokenBalance.mul(charityFee).div(totalfees);
            swapAndSendFee(charityTokens, CharityWalletAddress);

            uint256 treasuryTokens = contractTokenBalance.mul(treasuryFee).div(totalfees);
            swapAndSendFee(treasuryTokens, TreasuryWalletAddress);

            uint256 liquidityTokens = balanceOf(address(this));
            swapAndLiquify(liquidityTokens);
        }
    }
    /**
     * Swap and send fee function.
     */
    function swapAndSendFee(uint256 tokens, address _address) private  {
        uint256 initialBNBBalance = address(this).balance;

        swapTokensForEth(tokens);
        uint256 newBalance = (address(this).balance).sub(initialBNBBalance);
        payable(_address).transfer(newBalance);
    }
    /**
     * Swap and liquity function.
     */
    function swapAndLiquify(uint256 tokens) private {
       // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    /**
     * Swap tokens for eth
     */
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the PETSSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = petsSwapRouter.WETH();

        _approve(address(this), address(petsSwapRouter), tokenAmount);

        // make the swap
        petsSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    /**
     * Add liquidity
     */
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(petsSwapRouter), tokenAmount);

        // add the liquidity
        petsSwapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
    /**
     * Returns the max transfer amount.
     */
    function maxTransferAmount() public view returns (uint256) {
        return totalSupply().mul(maxTransferAmountRate).div(10000);
    }
    /**
     * Returns the max sale amount.
     */
    function maxSaleAmount() public view returns (uint256) {
        return balanceOf(petsSwapPair).mul(maxSaleAmountRate).div(10000);
    }
    /**
     * Returns the address is excluded from fees or not.
     */
    function isExcludedFromFees(address account) public view returns(bool) {
        return _excludedFromFees[account];
    }
    /**
     * Returns the address is excluded from antiWhale or not.
     */
    function isExcludedFromAntiWhale(address _account) public view returns (bool) {
        return _excludedFromAntiWhale[_account];
    }
    /**
     * Returns the address is excluded from limitswap or not.
     */
    function isExcludedFromLimitSwap(address account) public view returns (bool) {
        return _excludedFromLimitSwap[account];
    }
    /**
     * Returns the address is blacklisted or not.
     */
    function isBlacklisted(address account) public view returns (bool) {
        return _isBlacklisted[account];
    }
    /**
     * Returns the address of the current operator.
     */
    function operator() public view returns (address) {
        return _operator;
    }
    /**
     * Update the max transfer amount rate.
     * Can only be called by the current onlyOperator.
     */
    function updateMaxTransferAmountRate(uint16 _maxTransferAmountRate) public onlyOperator {
        require(_maxTransferAmountRate <= 10000, "PETS::updateMaxTransferAmountRate: Max transfer amount rate must not exceed the maximum rate.");
        emit MaxTransferAmountRateUpdated(msg.sender, maxTransferAmountRate, _maxTransferAmountRate);
        maxTransferAmountRate = _maxTransferAmountRate;
    }
    /**
     * Update the min amount to liquify.
     * Can only be called by the current onlyOperator.
     */
    function updateMinAmountToLiquify(uint256 _minAmount) public onlyOperator {
        emit MinAmountToLiquifyUpdated(msg.sender, minAmountToLiquify, _minAmount);
        minAmountToLiquify = _minAmount;
    }
    /* Update the additional tax rate.
    Can only be called by the current operator */
    function updateadditionalTaxRate(uint256 _newtax) public onlyOperator {
        emit AdditionalTaxRateUpdated(msg.sender, additionalTaxRate, _newtax);
        additionalTaxRate= _newtax;
    }
    /**
     * Exclude or include an address from antiWhale.
     * Can only be called by the current onlyOperator.
     */
    function setExcludeFromFees(address _account, bool _excluded) public onlyOperator {
        require(_excludedFromFees[_account] != _excluded, "PETS: Account is already the value of 'excluded'");
        _excludedFromFees[_account] = _excluded;

        emit ExcludeFromFees(_account, _excluded);
    }
    /**
     * Exclude or include multi addresses from antiWhale.
     * Can only be called by the current onlyOperator.
     */
    function excludeMultipleAccountsFromFees(address[] calldata _accounts, bool _excluded) public onlyOperator {
        for(uint256 i = 0; i < _accounts.length; i++) {
            _excludedFromFees[_accounts[i]] = _excluded;
        }
        emit ExcludeMultipleAccountsFromFees(_accounts, _excluded);
    }
    /**
     * Exclude or include an address from antiWhale.
     * Can only be called by the current onlyOperator.
     */
    function setExcludedFromAntiWhale(address _account, bool _excluded) public onlyOperator {
        _excludedFromAntiWhale[_account] = _excluded;
        emit ExcludeFromAntiWhale(_account, _excluded);
    }
    /**
     * Exclude or include an address from LimitSwap.
     * Can only be called by the current onlyOperator.
     */
    function setExcludedFromLimitSwap(address _accounts, bool _excluded) public onlyOperator {
        _excludedFromLimitSwap[_accounts] = _excluded;
        emit ExcludeFromLimitSwap(_accounts, _excluded);
    }
    /**
     * Enable or disalbe time limit swap function.
     * Can only be called by the current onlyOperator.
     */
    function UpdateLimitSwap(bool value) public onlyOperator {
        emit LimitSwapUpdated(msg.sender, value);
        limitSwap = value;
    }
    /**
     * Update limit sale time period function
     * Can only be called by the current onlyOperator.
     */
    function UpdateTimeLimitSwap(uint256 _timeLimitSwap) public onlyOperator {
		require(_timeLimitSwap <= 28800, "PETS::UpdateTimeLimitSwap: Too long.");
        emit TimeLimitSwapUpdated(msg.sender, _timeLimitSwap);
        timeLimitSwap = _timeLimitSwap;
    }
    /**
     * Enable or disalbe time swapAndLiquify function.
     * Can only be called by the current onlyOperator.
     */
    function updateSwapAndLiquifyEnabled(bool _enabled) public onlyOperator {
        emit SwapAndLiquifyEnabledUpdated(msg.sender, _enabled);
        swapAndLiquifyEnabled = _enabled;
    }
    /**
     * Update the swap router.
     * Can only be called by the current onlyOperator.
     */
    function updatePETSSwapRouter(address _router) public onlyOperator {
        petsSwapRouter = IUniswapV2Router02(_router);
        petsSwapPair = IUniswapV2Factory(petsSwapRouter.factory()).getPair(address(this), petsSwapRouter.WETH());
        require(petsSwapPair != address(0), "PETS::updatePETSSwapRouter: Invalid pair address.");
        emit PETSSwapRouterUpdated(_router, address(petsSwapRouter), petsSwapPair);  
    }
    
    function updateBigtaxclearPeriod(uint256 _newPeriodinblock) public onlyOperator {
        // require(block.number < startBlockSwap, "PETS: Already in Big tax period. Can not update.");
        emit BigTaxPeriodUpdated(msg.sender, bigtaxclearperiod, _newPeriodinblock);
        bigtaxclearperiod = _newPeriodinblock;
    }
    /**
     * Update Start Block Swap. Can only be called by the current Owner.
     */
    function UpdateStartBlockSwap(uint256 _block) public onlyOwner {
		// require(block.number <= startBlockSwap, "PETS::UpdateStartBlockSwap: Cannot update when ready");
        uint256 startblock;
        if(_block < block.number) {
            startblock = block.number;
        } else {
            startblock = _block;
        }
        emit StartBlockSwapUpdated(msg.sender, startblock);
        startBlockSwap = startblock;
    }	
    /**
     * Enable or disable selling.
     * Can only be called by the current onlyOperator.
     */
    function setSelling(bool _value) public onlyOperator {
        selling = _value;
    }
    /**
     * Enable or disable buying.
     * Can only be called by the current onlyOperator.
     */
    function setBuying(bool _value) public onlyOperator {
        buying = _value;
    }
    /**
     * Update fees function.
     * Can only be called by the current onlyOperator.
     */
    function setFees(uint256 _liquidityFee, uint256 _charityFee, uint256 _treasuryFee) external onlyOperator{
        liquidityFee = _liquidityFee;
        charityFee = _charityFee;
        treasuryFee = _treasuryFee;
        uint256 totalFees = liquidityFee.add(charityFee).add(treasuryFee);
        require(totalFees <= MAXIMUM_TRANSFER_TAX_RATE, "PETS: Total fees can not be bigger than max value");
        transferTaxRate = totalFees;
    }
    /**
     * Update charity wallet address function.
     * Can only be called by the current onlyOperator.
     */
    function setCharityWallet(address payable _wallet) external onlyOperator{
        TreasuryWalletAddress = _wallet;
    }
    /**
     * Update treasury wallet address function.
     * Can only be called by the current onlyOperator.
     */
    function setTreasuryWallet(address payable _wallet) external onlyOperator{
        CharityWalletAddress = _wallet;
    }
    /**
     * Add or remove account address to (or from) blacklist
     * Can only be called by the current onlyOperator.
     */
    function blacklistAddress(address _account, bool _value) external onlyOperator{
        _isBlacklisted[_account] = _value;
    }
    /**
     * Transfers operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */
    function transferOperator(address newOperator) public onlyOperator {
        require(newOperator != address(0), "PETS::transferOperator: new operator is the zero address");
        emit OperatorTransferred(_operator, newOperator);
        _operator = newOperator;
    }
    /* Withdraw tokens 
    * Can only be called by the current operator.
    */
    function getToken(IBEP20 _token, address _recipient, uint256 _amount) public onlyOperator {
        require(_recipient != address(0), "PETS::withdraw: ZERO address.");

        uint256 amount = _token.balanceOf(address(this));
        if( _amount > amount){amount = _amount;}
        _token.safeTransfer(_recipient, amount);
        emit GetToken(address(_token), _recipient, amount);
    }
}