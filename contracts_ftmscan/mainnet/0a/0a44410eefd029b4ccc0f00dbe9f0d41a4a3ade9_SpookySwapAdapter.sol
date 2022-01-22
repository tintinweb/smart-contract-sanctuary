/**
 *Submitted for verification at FtmScan.com on 2022-01-22
*/

// File: ..\Contracts\interfaces\IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

// File: ..\Contracts\IAdapter.sol


pragma solidity >= 0.6.12;


interface IAdapter {
    // Victim info
    function rewardTokenCount() external view returns (uint256);
    function rewardToken(uint256 id) external view returns (IERC20);
    function defaultToken() external view returns (IERC20);
    function poolCount() external view returns (uint256);

    function zapAny(address sellToken, uint256 poolId, uint256 amount, uint256 min_out, address to) external returns(uint256);
    function _zapAny(address sellToken, uint256 poolId, uint256 amount, uint256 min_out, address to) external returns(uint256);
    function unzapAny(address sellToken, uint256 poolId, uint256 amount, uint256 min_out, address to) external returns(uint256);
    function _unzapAny(address sellToken, uint256 poolId, uint256 amount, uint256 min_out, address to) external returns(uint256);
    function zapAnyRouted(address sellToken, bytes calldata call, uint256 poolId, uint256 amount, uint256 min_out, address to) external returns(uint256);
    function _zapAnyRouted(address sellToken, bytes calldata call, uint256 poolId, uint256 amount, uint256 min_out, address to) external returns(uint256);
    function unzapAnyRouted(address sellToken, bytes calldata call, uint256 poolId, uint256 amount, uint256 min_out, address to) external returns(uint256);
    function _unzapAnyRouted(address sellToken, bytes calldata call, uint256 poolId, uint256 amount, uint256 min_out, address to) external returns(uint256);

    // Pool info
    function lockableToken(uint256 poolId) external view returns (IERC20);
    function lockedAmount(address user, uint256 poolId) external view returns (uint256);

    // Service methods
    function poolAddress(uint256 poolId) external view returns (address);
    function earnedReward(address _adapter, uint256 poolId, address user, uint256 tokenId) external view returns (uint256);
    
}

// File: ..\Contracts\interfaces\IUniswapV2Pair.sol


pragma solidity 0.6.12;

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

// File: ..\Contracts\interfaces\IUniswapV2Factory.sol


pragma solidity 0.6.12;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// File: ..\Contracts\interfaces\IUniswapV2Router01.sol


pragma solidity 0.6.12;

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

// File: ..\Contracts\interfaces\IUniswapV2Router02.sol


pragma solidity 0.6.12;


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

// File: ..\Contracts\libraries\SafeMath.sol


pragma solidity 0.6.12;

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

// File: ..\Contracts\libraries\Address.sol


pragma solidity 0.6.12;

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

// File: ..\Contracts\libraries\SafeERC20.sol


pragma solidity 0.6.12;



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

// File: ..\Contracts\adapters\FTM\SpookySwap\SpookySwapAdapter.sol


pragma solidity 0.6.12;







interface IspookyFarm{
    function poolInfo(uint256) external view returns (address,uint256,uint256,uint256);
    function userInfo(uint256, address) external view returns (uint256,uint256);
    function poolLength() external view returns (uint256);
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);
    function spookyPerBlock() external view returns (uint256);
    function totalAllocPoint() external view returns (uint256);
    function pendingBOO(uint256 _pid, address _user) external view returns (uint256);
}

contract SpookySwapAdapter is IAdapter {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    IspookyFarm constant spookyFarm = IspookyFarm(0x2b2929E785374c651a81A63878Ab22742656DcDd);
    IERC20 constant weth = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
    IERC20 constant spooky = IERC20(0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE);
    IUniswapV2Router02 constant spookyRouter = IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
    IUniswapV2Factory constant spookyFactory = IUniswapV2Factory(0x152eE697f2E276fA89E96742e9bB9aB1F2E61bE3);

    // Target info
    function rewardTokenCount() external view override returns (uint256) {
        return 1;
    }

    function rewardToken(uint256) external view override returns (IERC20) {
        return spooky;
    }

    function defaultToken() external view override returns (IERC20) {
        return weth;
    }

    function poolCount() external view override returns (uint256) {
        return spookyFarm.poolLength();
    }

    function zapAny( address sellToken, uint256 poolId, uint256 amount, uint256 min_out, address to) external override returns(uint256) {
        IERC20(sellToken).safeTransferFrom(address(msg.sender), address(this), amount);
        return this._zapAny(sellToken, poolId, amount, min_out, to);
    }

    function _zapAny(address sellToken, uint256 poolId, uint256 amount, uint256 min_out, address to) external override returns(uint256) {
        (address lpAddress,,,) = spookyFarm.poolInfo(poolId);
        IUniswapV2Pair lpToken = IUniswapV2Pair(lpAddress);
        address token0 = lpToken.token0();
        address token1 = lpToken.token1();
        IERC20(sellToken).safeIncreaseAllowance(address(spookyRouter), amount);
        amount = amount.div(2);

        if (sellToken != token0) {
            if (address(weth) == sellToken) {
                address[] memory path = new address[](2);
                path[0] = address(weth);
                path[1] = token0;
                spookyRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp + 60);
            }
            else if (token0 != address(weth)){
                address[] memory path = new address[](3);
                path[0] = sellToken;
                path[1] = address(weth);
                path[2] = token0;
                spookyRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp + 60);
            } else if (token0 == address(weth)){
                address[] memory path = new address[](2);
                path[0] = sellToken;
                path[1] = address(weth);
                spookyRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp + 60);
            }
        }

        if (sellToken != token1) {
            if (address(weth) == sellToken) {
                address[] memory path = new address[](2);
                path[0] = address(weth);
                path[1] = token1;
                spookyRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp + 60);
            }
            else if (token1 != address(weth)) {
                address[] memory path = new address[](3);
                path[0] = sellToken;
                path[1] = address(weth);
                path[2] = token1;
                spookyRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp + 60);
            } else if (token1 == address(weth)){
                address[] memory path = new address[](2);
                path[0] = sellToken;
                path[1] = address(weth);
                spookyRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp + 60);
            }
        }

        uint256 token0Amt = IERC20(token0).balanceOf(address(this));
        uint256 token1Amt = IERC20(token1).balanceOf(address(this));
        if (token0Amt > 0 && token1Amt > 0) {
        IERC20(token0).safeIncreaseAllowance(address(spookyRouter),token0Amt);
        IERC20(token1).safeIncreaseAllowance(address(spookyRouter),token1Amt);

        spookyRouter.addLiquidity(
            token0,
            token1,
            token0Amt,
            token1Amt,
            0,
            0,
            address(this),
            block.timestamp + 60
        );

        uint256 amountOut = lpToken.balanceOf(address(this));
        lpToken.transfer(to, amountOut);
        require(amountOut >= min_out, "Bad zap");
        return amountOut;
        }
        require(false, "Bad Zap");

    }

    function zapAnyRouted(address sellToken, bytes calldata call, uint256 poolId, uint256 amount, uint256 min_out, address to) external override returns(uint256) {
        IERC20(sellToken).safeTransferFrom(address(msg.sender), address(this), amount);
        return this._zapAnyRouted(sellToken, call, poolId, amount, min_out, to);
    }

    function _zapAnyRouted(address, bytes calldata, uint256, uint256, uint256, address) external override returns(uint256) {
        require(false, "not implemented");
    }

    function unzapAny(address, uint256, uint256, uint256, address) external override returns(uint256) { 
        require(false, "not implemented");
    }

    function _unzapAny(address, uint256, uint256, uint256, address) external override returns(uint256) { 
        require(false, "not implemented");
    }

    function unzapAnyRouted(address,bytes calldata,  uint256, uint256, uint256, address) external override returns(uint256) { 
        require(false, "not implemented");
    }

    function _unzapAnyRouted(address, bytes calldata,  uint256, uint256, uint256, address) external override returns(uint256) { 
        require(false, "not implemented");
    }

    // Pool info
    function lockableToken(uint256 poolId) external view override returns (IERC20) {
        (address lpToken,,,) = spookyFarm.poolInfo(poolId);
        return IERC20(lpToken);
    }

    function lockedAmount(address user, uint256 poolId) external view override returns (uint256) {
        (uint256 amount,) = spookyFarm.userInfo(poolId, user);
        return amount;
    }

    function earnedReward(address, uint256 poolId, address user, uint256) external view override returns (uint256) {
        return spookyFarm.pendingBOO(poolId, user);
    }

    // Service methods
    function poolAddress(uint256) external view override returns (address) {
        return address(spookyFarm);
    }
}