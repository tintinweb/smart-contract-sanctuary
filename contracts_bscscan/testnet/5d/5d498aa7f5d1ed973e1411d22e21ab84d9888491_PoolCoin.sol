/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;


/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 * 
 * from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol
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

/**
 * @dev Collection of functions related to the address type
 * 
 * from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
 * @dev Add Pancake Router and Pancake Pair interfaces
 * 
 * from https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/interfaces/IPancakeRouter01.sol
 */
interface IPancakeRouter01 {
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

// from https://github.com/pancakeswap/pancake-swap-periphery/blob/master/contracts/interfaces/IPancakeRouter02.sol
interface IPancakeRouter02 is IPancakeRouter01 {
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

// from https://github.com/pancakeswap/pancake-swap-core/blob/master/contracts/interfaces/IPancakeFactory.sol
interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setRewardFeeTo(address) external;
    function setRewardFeeToSetter(address) external;
}

// from https://github.com/pancakeswap/pancake-swap-core/blob/master/contracts/interfaces/IPancakePair.sol
interface IPancakePair {
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

/**
 * @dev BEP20 Token interface
 */
interface IBEP20 {
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
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     * 
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

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
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 * 
 * from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol
 */
library SafeBEP20 {
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeBEP20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
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
    address private _previousOwner;
    uint256 private _lockTime;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    // Locks the contract for owner for the amount of time provided
    function lock(uint256 time) external onlyOwner {
        _previousOwner = _owner;
        _lockTime      = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    // Unlocks the contract for owner when _lockTime is exceeds
    function unlock() external {
        require(_previousOwner == _msgSender(), "You don't have permission to unlock");
        require(block.timestamp > _lockTime, "Contract is locked!");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = address(0);
        _lockTime = 0;
    }

    function getUnlockTime() external view returns (uint256) {
        require(_lockTime > 0, "Contract is not locked!");
        return _lockTime;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

/**
 * @dev Contract module based on Safemoon Protocol
 */
contract PoolCoin is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using SafeBEP20 for IBEP20;

    mapping(address => uint256) private _rBalances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isLockedWallet;
    mapping(address => bool) private _isExcludedFromMax;
    mapping(address => bool) private _isExcludedFromFee;

    address private constant _burnAddress     = 0x000000000000000000000000000000000000dEaD;

    address public constant marketingWallet   = 0x6db52E2F2EFe5E6e0c0AE402Bc756c41D6a8Ee8F;

    string private constant _name          = "PoolCoin";
    string private constant _symbol        = "Snooker";
    uint8 private constant _decimals       = 9;
    uint256 private constant _tTotalSupply = 100 * 10**8 * 10**_decimals; 

    uint256 private constant _MAX = ~uint256(0); // _MAX = 115792089237316195423570985008687907853269984665640564039457584007913129639935

    // custom variables system
    uint256 public buyMaxTxAmountPercentFromLP      = 50; // max permited of 50% from LP on buy transaction
    uint256 public sellMaxTxAmountPercentPerAccount = 50; // max permited of 50% from balance on sell transaction
    uint256 public otherMaxTxAmountPercentNoAccount = 50; // max permited of 50% from total supply on other transaction

    uint256 public buyRewardFee   = 5; // 5% fee to distribute for holders on buy
    uint256 public sellRewardFee  = 5; // 5% fee to distribute for holders on sell
    uint256 public otherRewardFee = 1; // 1% fee to distribute for holders on other transaction

    uint256 public buyLiquidityFee   = 5; // 5% fee to distribute for holders on buy
    uint256 public sellLiquidityFee  = 5; // 5% fee to distribute for holders on sell
    uint256 public otherLiquidityFee = 1; // 1% fee to distribute for holders on other transaction

    

    uint256 public numTokensSellToSwap = _tTotalSupply / 2000; // number of tokens accumulated to exchange (0.05% of total supply)

    uint256 public sellBackMaxTimeForHistories = 1 days; // 24 hours to permit sells

    bool public maxTxAmountEnabled      = true;
    bool public swapTokensForBnbEnabled = true;
    bool public feesEnabled             = true;

    // variables for LP lock system
    bool public isLockedLP = false;
    uint256 private _releaseTimeLP;

    // variables for pre-sale system
    bool public isPreSaleEnabled = false;   
    uint256 private _sDivider;
    uint256 private _sPrice;
    uint256 private _sTotal;

    /**
     * @dev for Pancakeswap Router V2, use:
     * 0x10ED43C718714eb63d5aA57B78B54704E256024E to Mainnet Binance Smart Chain;
     * 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 to Testnet Binance Smart Chain;
     */
    IPancakeRouter02 private constant _pancakeRouter = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

    IPancakeRouter02 public immutable pancakeRouter;
    address public immutable pancakePair;

    // variables for safemoon contract system
    uint256 private _rTotalSupply;
    uint256 private _maxTxAmount;
    uint256 private _rewardFee;
    uint256 private _previousRewardFee;
    uint256 private _liquidityFee;
    uint256 private _previousLiquidityFee;


    uint256 private _tFeeTotal;

    bool private _inSwapTokens;

    // struct to store time of sells
    struct SellHistories {
        address account;
        uint256 time;
    }

    // LookBack into historical sale data
    SellHistories[] private _sellHistories;

    // struct to reflect transfers and fees
    struct rValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rRewardFee;
        uint256 rLiquidityFee;
       
    }

    // struct for transfers and fees
    struct tValues {
        uint256 tTransferAmount;
        uint256 tRewardFee;
        uint256 tLiquidityFee;
      
    }

    constructor() {
        // Create a pancake pair for this new token
        pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;

        // set reflect variables
        _rTotalSupply            = (_MAX - (_MAX % _tTotalSupply));
        _rBalances[_msgSender()] = _rTotalSupply;
        emit Transfer(address(0), _msgSender(), _tTotalSupply);

        // exclude owner, this contract, donation wallet and marketing wallet from fee
        _isExcludedFromFee[owner()]         = true;
        _isExcludedFromFee[address(this)]   = true;
        _isExcludedFromFee[_burnAddress]    = true;
       
        _isExcludedFromFee[marketingWallet] = true;

        // exclude this contract, donation wallet and marketing wallet from max tx amount
        _isExcludedFromMax[address(this)]   = true;
        _isExcludedFromMax[_burnAddress]    = true;
    
        _isExcludedFromMax[marketingWallet] = true;
    }

    modifier lockTheSwap {
        _inSwapTokens = true;
        _;
        _inSwapTokens = false;
    }



    function getOwner() external view returns (address) {
        return owner();
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rBalances[account]);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function lockWallet(address account) external onlyOwner {
        require(!_isLockedWallet[account], "Account is already locked");
        _isLockedWallet[account] = true;
        emit LockedWallet(account, true);
    }

    function unLockWallet(address account) external onlyOwner {
        require(_isLockedWallet[account], "Account is not locked");
        _isLockedWallet[account] = false;
        emit LockedWallet(account, false);
    }

    function isLockedWallet(address account) external view returns(bool) {
        return _isLockedWallet[account];
    }

    function excludeFromMax(address account) external onlyOwner {
        require(!_isExcludedFromMax[account], "Account is already excluded from limits");
        _isExcludedFromMax[account] = true; 
    }

    function includeInMax(address account) external onlyOwner {
        require(_isExcludedFromMax[account], "Account is not excluded from limits");
        _isExcludedFromMax[account] = false; 
    }

    function isExcludedFromMax(address account) external view returns (bool) {
        return _isExcludedFromMax[account]; 
    }

    function excludeFromFee(address account) external onlyOwner {
        require(!_isExcludedFromFee[account], "Account is already excluded from fees");
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        require(_isExcludedFromFee[account], "Account is not excluded from fees");
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function setBuyMaxTxAmountPercentFromLP(uint256 value) external onlyOwner {
        require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");
        buyMaxTxAmountPercentFromLP = value;
    }

    function setSellMaxTxAmountPercentPerAccount(uint256 value) external onlyOwner {
        require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");
        sellMaxTxAmountPercentPerAccount = value;
    }

    function setOtherMaxTxAmountPercentNoAccount(uint256 value) external onlyOwner {
        require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");
        otherMaxTxAmountPercentNoAccount = value;
    }

    function setBuyRewardFeePercent(uint256 value) external onlyOwner {
        require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");
        buyRewardFee = value;
    }

    function setSellRewardFeePercent(uint256 value) external onlyOwner {
        require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");
        sellRewardFee = value;
    }

    function setOtherRewardFeePercent(uint256 value) external onlyOwner {
        require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");
        otherRewardFee = value;
    }

    function setBuyLiquidityFeePercent(uint256 value) external onlyOwner {
        require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");
        buyLiquidityFee = value;
    }

    function setSellLiquidityFeePercent(uint256 value) external onlyOwner {
        require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");
        sellLiquidityFee = value;
    }

    function setOtherLiquidityFeePercent(uint256 value) external onlyOwner {
        require(value >= 0 && value <= 100, "Value out of range: values between 0 and 100");
        otherLiquidityFee = value;
    }



    function setNumTokensSellToSwap(uint256 value) external onlyOwner {
        uint256 maxValue = _tokensInLP();
        require(maxValue > 0, "Contract without liquidity!");
        require(value >= 0 && value <= maxValue.div(10**_decimals), "Value out of range: values between 0 and max of token in LP");
        numTokensSellToSwap = value.mul(10**_decimals);
    }

    function setSellBackMaxTimeForHistories(uint256 value) external onlyOwner {
        require(value >= 0 && value <= 1 weeks, "Value out of range: values between 0 and 1 week in unix timestamp");
        sellBackMaxTimeForHistories = value;
    }

    function getLeftTimeToSellForTokens(address account) external view returns (uint256) {
        return _locateAccountSellHistories(account);
    }

    function setSwapTokensForBnbEnabled(bool _enabled) external onlyOwner {
        //require(!isPreSaleEnabled, "This feature is not available during pre-sales.");
        swapTokensForBnbEnabled = _enabled;
        emit SwapTokensForBnbEnableUpdated(_enabled);
    }

    function disableFees() external onlyOwner {
        //require(!isPreSaleEnabled, "This feature is not available during pre-sales.");
        _disableFees();
    }

    function enableFees() external onlyOwner {
        //require(!isPreSaleEnabled, "This feature is not available during pre-sales.");
        _enableFees();   
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }



    function reflectionFromToken(uint256 tAmount, bool deductTransferRewardFee) external view returns (uint256) {
        require(tAmount <= _tTotalSupply, "Amount must be less than supply");
        if (!deductTransferRewardFee) {
            (rValues memory _rv, tValues memory _tv) = _getValues(tAmount);
            _rv.rTransferAmount = 0; _rv.rRewardFee = 0; _rv.rLiquidityFee = 0; 
            _tv.tTransferAmount = 0; _tv.tRewardFee = 0; _tv.tLiquidityFee = 0; 
            return _rv.rAmount;
        } else {
            (rValues memory _rv, tValues memory _tv) = _getValues(tAmount);
            _rv.rAmount         = 0; _rv.rRewardFee = 0; _rv.rLiquidityFee = 0; 
            _tv.tTransferAmount = 0; _tv.tRewardFee = 0; _tv.tLiquidityFee = 0; 
            return _rv.rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotalSupply, "Amount must be less than total reflections");
        return rAmount.div(_getRate());
    }

    function lockLP (uint256 releaseTime) external onlyOwner {
        require(!isLockedLP, "LP is already locked!");
        require(releaseTime > block.timestamp, "Release time is before current time");
        IBEP20 tokenLP = IBEP20(pancakePair);
        if (tokenLP.allowance(_msgSender(), address(this)) > 0) {
            uint256 amount = tokenLP.balanceOf(_msgSender());
            require(amount > 0, "No tokens to lock");
            tokenLP.safeTransferFrom(_msgSender(), address(this), amount);
        }
        _releaseTimeLP = releaseTime;
        isLockedLP     = true;
    }

    function releaseLP () external onlyOwner {
        require(isLockedLP, "LP is not already locked!");
        require(block.timestamp >= _releaseTimeLP, "Current time is before release time");
        IBEP20 tokenLP = IBEP20(pancakePair);
        uint256 amount = tokenLP.balanceOf(address(this));
        require(amount > 0, "No tokens to release");
        tokenLP.safeTransfer(_msgSender(), amount);
        _releaseTimeLP = 0;
        isLockedLP     = false;
    }

    function releaseTimeLP () external view returns (uint256) {
        require(isLockedLP, "LP is not already locked!");
        return _releaseTimeLP;
    }

    function startPreSale(uint256 referPercent, uint256 salePrice, uint256 tokenAmount) external onlyOwner {
        require(!isPreSaleEnabled, "Pre-sale is already activated!");
        require(referPercent >= 0 && referPercent <= 100, "Value out of range: values between 0 and 100");
        require(salePrice > 0, "Sale price must be greater than zero");
        require(tokenAmount > 0 && tokenAmount <= balanceOf(_msgSender()).div(10**_decimals), "Token amount must be greater than zero and less than or equal to balance of owner.");
        _sDivider  = referPercent;
        _sPrice    = salePrice;
        _sTotal    = 0;
        //_disableFees();
        _transfer(_msgSender(), address(this), tokenAmount.mul(10**_decimals));
        isPreSaleEnabled = true;
    }

    function stopPreSale() external onlyOwner {
        require(isPreSaleEnabled, "Pre-sale is not already activated!");
        isPreSaleEnabled = false;
        _getBnbAndTokens(_msgSender());
        //_enableFees();
    }

    function tokenSale(address _refer) external payable returns (bool success) {
        require(isPreSaleEnabled, "Pre-sale is not available.");
        // Min = 0.01 BNB, Max = 5 BNB
        require(msg.value >= 10000000 gwei && msg.value <= 5 ether, "Value out of range: values between 0.01 and 5 BNB");
        uint256 _tokens = _sPrice.mul(msg.value).div(1 ether).mul(10**_decimals);
        if (_msgSender() != _refer && balanceOf(_refer) != 0 && _refer != address(0)) {
            uint256 referTokens = _tokens.mul(_sDivider).div(10**2);
            require((_tokens + referTokens) <= balanceOf(address(this)), "Insufficient tokens for this sale");
            _transfer(address(this), _refer, referTokens);
            _transfer(address(this), _msgSender(), _tokens);
        } else {
            require(_tokens <= balanceOf(address(this)), "Insufficient tokens for this sale");
            _transfer(address(this), _msgSender(), _tokens);
        }
        _sTotal++;
        return true;
    }

    function clearBNB() external onlyOwner {
        // gets the BNBs accumulated in the contract
        if (address(this).balance > 0) _msgSender().transfer(address(this).balance);
    }

    function viewSale() external view returns (uint256 referPercent, uint256 SalePrice, uint256 SaleCap, uint256 remainingTokens, uint256 SaleCount) {
        require(isPreSaleEnabled, "Pre-sale is not available.");
        return (_sDivider, _sPrice, address(this).balance, balanceOf(address(this)), _sTotal);
    }

    function _transfer(address from, address to, uint256 amount) private {
        // prevents transfer of blocked wallets
        require(!_isLockedWallet[from], "Locked addresses cannot call this function");

        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // lock sale if pre sale is enabled
        if (from == pancakePair || to == pancakePair) {
            require(!isPreSaleEnabled, "It is not possible to exchange tokens during the pre sale");
        }

        // sales (holder -> pair) control by time
        if (to == pancakePair && from != owner() && !_isExcludedFromMax[from]) {
            require(block.timestamp - _locateAccountSellHistories(from) > sellBackMaxTimeForHistories, "Sale allowed only after some hours");
        }

        // set _maxTxAmount to buy, sell or other action
        if (from != owner() && to != owner() && 
            !_isExcludedFromMax[from] && !_isExcludedFromMax[to] &&
            maxTxAmountEnabled) {
            if (from == pancakePair) {
                // Buys only a certain percentage of the LP
                /** 
                 * here I have to trust that _tokensInLP() will never return zero, 
                 * as the PancakeSwap implementation would prevent this
                 */
                _maxTxAmount = _tokensInLP().mul(buyMaxTxAmountPercentFromLP).div(10**2);
            } else if (to == pancakePair) {
                // Sells only a certain percentage of the balance
                _maxTxAmount = balanceOf(from).mul(sellMaxTxAmountPercentPerAccount).div(10**2);
            } else if (otherMaxTxAmountPercentNoAccount > 0) {
                // For other action transfer only a certain percentage of the total supply
                _maxTxAmount = _tTotalSupply.mul(otherMaxTxAmountPercentNoAccount).div(10**2);
            } else {
                // For other action transfer the total of balance
                _maxTxAmount = balanceOf(from);
            }

            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToSwap;
        if (overMinTokenBalance && !_inSwapTokens &&
            from != pancakePair && swapTokensForBnbEnabled) {
            contractTokenBalance = numTokensSellToSwap;
          
        }

        // indicates if fee should be deducted from transfer
        bool takeFee = true;

        // if any account belongs to _isExcludedFromFee account or feesEnabled disabled then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || !feesEnabled) {
            takeFee = false;
        } else { // set fee to buy, sell and other transactions
            if (from == pancakePair) { // Buy
                _rewardFee = buyRewardFee;
                _liquidityFee = buyLiquidityFee;
               
            } else if (to == pancakePair) { // Sell
                _rewardFee = sellRewardFee;
                _liquidityFee = sellLiquidityFee;
               
            } else { // other
                _rewardFee = otherRewardFee;
                _liquidityFee = otherLiquidityFee;
               
            }
        }

        // transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);

        // buys (pair -> holder) and sales (holder -> pair) control by time
        if (from == pancakePair && to != owner() && !_isExcludedFromMax[to]) { // Buy
            uint256 timeCtrlToBuy = _locateAccountSellHistories(to);
            /** 
             * sale time lock valid only for the first purchase, 
             * from the second purchase onwards it will not be included in the record,
             * if time lock expires will be add the current time, 
             * the investor can sell their tokens at any time the sale lock expires.
             */
            if (timeCtrlToBuy == 0 || block.timestamp - timeCtrlToBuy > sellBackMaxTimeForHistories) { 
                _addAccountSellHistories(to);
            }
        } else if (to == pancakePair && from != owner() && !_isExcludedFromMax[from]) { // Sell
            _addAccountSellHistories(from);
        }
        // clear list of the old holders
        _removeOldSellHistories();
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _locateAccountSellHistories(address account) private view returns (uint256) {
        uint256 time = 0;

        for (uint256 i = 0; i < _sellHistories.length; i++) {
            if (_sellHistories[i].account == account) {
                time = _sellHistories[i].time;
                break;
            }
        }

        return time;
    }

    function _addAccountSellHistories(address account) private {
        SellHistories memory sellHistory;

        sellHistory.account = account;
        sellHistory.time    = block.timestamp;
        _sellHistories.push(sellHistory);
    }

    function _removeOldSellHistories() private {
        uint256 i                        = 0;
        uint256 maxStartTimeForHistories = block.timestamp - sellBackMaxTimeForHistories;

        for (uint256 j = 0; j < _sellHistories.length; j++) {
            if (_sellHistories[j].time >= maxStartTimeForHistories) {
                if (_sellHistories[j].time != _sellHistories[i].time) {
                    _sellHistories[i].account = _sellHistories[j].account;
                    _sellHistories[i].time    = _sellHistories[j].time;
                }
                i++;
            }
        }

        uint256 removedCnt = _sellHistories.length - i;
        for (uint256 j = 0; j < removedCnt; j++) {
            _sellHistories.pop();
        }
    }

  

    function _swapTokensForBnb(uint256 tokenAmount) private {
        // generate the pancake pair path of token -> wbnb
        address[] memory path = new address[](2);
        path[0]               = address(this);
        path[1]               = pancakeRouter.WETH();

        _approve(address(this), address(pancakeRouter), tokenAmount);

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

  

    // this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) {
            _removeAllFee();
        }

         (rValues memory _rv, tValues memory _tv) = _getValues(amount);
        _rBalances[sender]    = _rBalances[sender].sub(_rv.rAmount);
        _rBalances[recipient] = _rBalances[recipient].add(_rv.rTransferAmount);
        _takeLiquidity(_tv.tLiquidityFee);
        _reflectRewardFee(_rv.rRewardFee, _tv.tRewardFee);
        emit Transfer(sender, recipient, _tv.tTransferAmount);
        

        if (!takeFee) {
            _restoreAllFee();
        }
    }

    function _removeAllFee() private {
        if (_rewardFee == 0 && _liquidityFee == 0) return;

        _previousRewardFee    = _rewardFee;
        _previousLiquidityFee = _liquidityFee;
       
        _rewardFee    = 0;
        _liquidityFee = 0;
        
    }

    function _getValues(uint256 tAmount) private view returns (rValues memory, tValues memory) {
        tValues memory _tv = _getTValues(tAmount);
        rValues memory _rv = _getRValues(tAmount, _tv.tRewardFee, _tv.tLiquidityFee,  _getRate());
        return (_rv, _tv);
    }

    function _getTValues(uint256 tAmount) private view returns (tValues memory) {
        tValues memory _tv;
        _tv.tRewardFee      = _calculateRewardFee(tAmount);
        _tv.tLiquidityFee   = _calculateLiquidityFee(tAmount);
       
        _tv.tTransferAmount = tAmount.sub(_tv.tRewardFee).sub(_tv.tLiquidityFee);
        return _tv;
    }

    function _getRValues(uint256 tAmount, uint256 tRewardFee, uint256 tLiquidityFee, uint256 currentRate) private pure returns (rValues memory) {
        rValues memory _rv;
        _rv.rAmount         = tAmount.mul(currentRate);
        _rv.rRewardFee      = tRewardFee.mul(currentRate);
        _rv.rLiquidityFee   = tLiquidityFee.mul(currentRate);
       
        _rv.rTransferAmount = _rv.rAmount.sub(_rv.rRewardFee).sub(_rv.rLiquidityFee);
        return _rv;
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotalSupply;
        uint256 tSupply = _tTotalSupply;
        if (rSupply < _rTotalSupply.div(_tTotalSupply)) return (_rTotalSupply, _tTotalSupply);
        return (rSupply, tSupply);
    }

    function _calculateRewardFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_rewardFee).div(10**2);
    }

    function _calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(10**2);
    }

  
    function _takeLiquidity(uint256 tLiquidityFee) private {
        uint256 rLiquidityFee     = tLiquidityFee.mul(_getRate());
        _rBalances[address(this)] = _rBalances[address(this)].add(rLiquidityFee);
        _tFeeTotal = _tFeeTotal.add(tLiquidityFee);
    }

    function _reflectRewardFee(uint256 rRewardFee, uint256 tRewardFee) private {
        _rTotalSupply = _rTotalSupply.sub(rRewardFee);
        _tFeeTotal    = _tFeeTotal.add(tRewardFee);
    }

 
    function _restoreAllFee() private {
        _rewardFee    = _previousRewardFee;
        _liquidityFee = _previousLiquidityFee;
       
    }

    function _tokensInLP() private view returns (uint256) {
        IPancakePair tokenLP = IPancakePair(pancakePair);
        uint256 tokensInLP   = 0;

        if (tokenLP.totalSupply() > 0) {
            (uint112 _reserve0, 
             uint112 _reserve1, 
             uint32 _blockTimestampLast) = tokenLP.getReserves();
            _blockTimestampLast = 0; // to silence compiler warnings
            if (tokenLP.token0() == address(this)) {
                tokensInLP = _reserve0;
            } else if (tokenLP.token1() == address(this)) {
                tokensInLP = _reserve1;
            }
        }

        return tokensInLP;
    }

    function _disableFees() private {
        maxTxAmountEnabled      = false;
        swapTokensForBnbEnabled = false;
        feesEnabled             = false;
    }

    function _enableFees() private {
        maxTxAmountEnabled      = true;
        swapTokensForBnbEnabled = true;
        feesEnabled             = true;   
    }

    function _getBnbAndTokens(address payable _receiver) private {
        // Receiving BNBs gives pre-sales
        if (address(this).balance > 0) _receiver.transfer(address(this).balance);
        // Remove tokens left over from the pre-sales contract
        if ( balanceOf(address(this)) > 0) _transfer(address(this), _receiver,  balanceOf(address(this)));
    }

    event SwapTokensForBnbEnableUpdated(bool enabled);
    event LockedWallet(address indexed wallet, bool locked);
    event Received(address indexed from, address indexed to, uint256 amount);
    event BnbFromLP(address indexed wallet, uint256 amount);
}