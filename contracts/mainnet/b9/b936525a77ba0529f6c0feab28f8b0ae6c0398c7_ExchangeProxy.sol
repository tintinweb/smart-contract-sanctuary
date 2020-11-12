// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

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

interface IBPool is IERC20 {
    function version() external view returns(uint);

    function swapExactAmountIn(address, uint, address, uint, uint) external returns (uint, uint);

    function swapExactAmountOut(address, uint, address, uint, uint) external returns (uint, uint);

    function calcInGivenOut(uint, uint, uint, uint, uint, uint) external pure returns (uint);

    function calcOutGivenIn(uint, uint, uint, uint, uint, uint) external pure returns (uint);

    function getDenormalizedWeight(address) external view returns (uint);

    function swapFee() external view returns (uint);

    function setSwapFee(uint _swapFee) external;

    function bind(address token, uint balance, uint denorm) external;

    function rebind(address token, uint balance, uint denorm) external;

    function finalize(
        uint _swapFee,
        uint _initPoolSupply,
        address[] calldata _bindTokens,
        uint[] calldata _bindDenorms
    ) external;

    function setPublicSwap(bool _publicSwap) external;
    function setController(address _controller) external;
    function setExchangeProxy(address _exchangeProxy) external;
    function getFinalTokens() external view returns (address[] memory tokens);

    function getTotalDenormalizedWeight() external view returns (uint);

    function getBalance(address token) external view returns (uint);

    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external;
    function joinPoolFor(address account, uint rewardAmountOut, uint[] calldata maxAmountsIn) external;
    function joinswapPoolAmountOut(address tokenIn, uint poolAmountOut, uint maxAmountIn) external returns (uint tokenAmountIn);

    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external;
    function exitswapPoolAmountIn(address tokenOut, uint poolAmountIn, uint minAmountOut) external returns (uint tokenAmountOut);
    function exitswapExternAmountOut(address tokenOut, uint tokenAmountOut, uint maxPoolAmountIn) external returns (uint poolAmountIn);
    function joinswapExternAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        uint minPoolAmountOut
    ) external returns (uint poolAmountOut);
}

interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

interface IBFactory {
    function newBPool() external returns (IBPool);
}

interface IValueLiquidRegistry {
    function getBestPoolsWithLimit(address, address, uint) external view returns (address[] memory);
}

interface IWETH {
    function deposit() external payable;
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address account) external view returns (uint256);
}

contract ExchangeProxy {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    IFreeFromUpTo public constant chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    modifier discountCHI(uint8 flag) {
        if ((flag & 0x1) == 0) {
            _;
        } else {
            uint256 gasStart = gasleft();
            _;
            uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
            chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41130);
        }
    }

    struct Pool {
        address pool;
        uint tokenBalanceIn;
        uint tokenWeightIn;
        uint tokenBalanceOut;
        uint tokenWeightOut;
        uint swapFee;
        uint effectiveLiquidity;
    }

    struct Swap {
        address pool;
        address tokenIn;
        address tokenOut;
        uint swapAmount; // tokenInAmount / tokenOutAmount
        uint limitReturnAmount; // minAmountOut / maxAmountIn
        uint maxPrice;
    }

    IWETH weth;
    IValueLiquidRegistry registry;
    address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    uint private constant BONE = 10 ** 18;

    address public governance;

    constructor(address _weth) public {
        weth = IWETH(_weth);
        governance = tx.origin;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setRegistry(address _registry) external {
        require(msg.sender == governance, "!governance");
        registry = IValueLiquidRegistry(_registry);
    }

    function batchSwapExactIn(
        Swap[] memory swaps,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint totalAmountIn,
        uint minTotalAmountOut,
        uint8 flag
    )
    public payable discountCHI(flag)
    returns (uint totalAmountOut)
    {
        transferFromAll(tokenIn, totalAmountIn);

        for (uint i = 0; i < swaps.length; i++) {
            Swap memory swap = swaps[i];
            IERC20 SwapTokenIn = IERC20(swap.tokenIn);
            IBPool pool = IBPool(swap.pool);

            if (SwapTokenIn.allowance(address(this), swap.pool) > 0) {
                SwapTokenIn.safeApprove(swap.pool, 0);
            }
            SwapTokenIn.safeApprove(swap.pool, swap.swapAmount);

            (uint tokenAmountOut,) = pool.swapExactAmountIn(
                swap.tokenIn,
                swap.swapAmount,
                swap.tokenOut,
                swap.limitReturnAmount,
                swap.maxPrice
            );
            totalAmountOut = tokenAmountOut.add(totalAmountOut);
        }

        require(totalAmountOut >= minTotalAmountOut, "ERR_LIMIT_OUT");

        transferAll(tokenOut, totalAmountOut);
        transferAll(tokenIn, getBalance(tokenIn));
    }

    function batchSwapExactOut(
        Swap[] memory swaps,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint maxTotalAmountIn,
        uint8 flag
    )
    public payable discountCHI(flag)
    returns (uint totalAmountIn)
    {
        transferFromAll(tokenIn, maxTotalAmountIn);

        for (uint i = 0; i < swaps.length; i++) {
            Swap memory swap = swaps[i];
            IERC20 SwapTokenIn = IERC20(swap.tokenIn);
            IBPool pool = IBPool(swap.pool);

            if (SwapTokenIn.allowance(address(this), swap.pool) > 0) {
                SwapTokenIn.safeApprove(swap.pool, 0);
            }
            SwapTokenIn.safeApprove(swap.pool, swap.limitReturnAmount);

            (uint tokenAmountIn,) = pool.swapExactAmountOut(
                swap.tokenIn,
                swap.limitReturnAmount,
                swap.tokenOut,
                swap.swapAmount,
                swap.maxPrice
            );
            totalAmountIn = tokenAmountIn.add(totalAmountIn);
        }
        require(totalAmountIn <= maxTotalAmountIn, "ERR_LIMIT_IN");

        transferAll(tokenOut, getBalance(tokenOut));
        transferAll(tokenIn, getBalance(tokenIn));

    }

    function multihopBatchSwapExactIn(
        Swap[][] memory swapSequences,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint totalAmountIn,
        uint minTotalAmountOut,
        uint8 flag
    )
    public payable discountCHI(flag)
    returns (uint totalAmountOut)
    {

        transferFromAll(tokenIn, totalAmountIn);

        for (uint i = 0; i < swapSequences.length; i++) {
            uint tokenAmountOut;
            for (uint k = 0; k < swapSequences[i].length; k++) {
                Swap memory swap = swapSequences[i][k];
                IERC20 SwapTokenIn = IERC20(swap.tokenIn);
                if (k == 1) {
                    // Makes sure that on the second swap the output of the first was used
                    // so there is not intermediate token leftover
                    swap.swapAmount = tokenAmountOut;
                }

                IBPool pool = IBPool(swap.pool);
                if (SwapTokenIn.allowance(address(this), swap.pool) > 0) {
                    SwapTokenIn.safeApprove(swap.pool, 0);
                }
                SwapTokenIn.safeApprove(swap.pool, swap.swapAmount);
                (tokenAmountOut,) = pool.swapExactAmountIn(
                    swap.tokenIn,
                    swap.swapAmount,
                    swap.tokenOut,
                    swap.limitReturnAmount,
                    swap.maxPrice
                );
            }
            // This takes the amountOut of the last swap
            totalAmountOut = tokenAmountOut.add(totalAmountOut);
        }

        require(totalAmountOut >= minTotalAmountOut, "ERR_LIMIT_OUT");

        transferAll(tokenOut, totalAmountOut);
        transferAll(tokenIn, getBalance(tokenIn));

    }

    function multihopBatchSwapExactOut(
        Swap[][] memory swapSequences,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint maxTotalAmountIn,
        uint8 flag
    )
    public payable discountCHI(flag)
    returns (uint totalAmountIn)
    {

        transferFromAll(tokenIn, maxTotalAmountIn);

        for (uint i = 0; i < swapSequences.length; i++) {
            uint tokenAmountInFirstSwap;
            // Specific code for a simple swap and a multihop (2 swaps in sequence)
            if (swapSequences[i].length == 1) {
                Swap memory swap = swapSequences[i][0];
                IERC20 SwapTokenIn = IERC20(swap.tokenIn);

                IBPool pool = IBPool(swap.pool);
                if (SwapTokenIn.allowance(address(this), swap.pool) > 0) {
                    SwapTokenIn.safeApprove(swap.pool, 0);
                }
                SwapTokenIn.safeApprove(swap.pool, swap.limitReturnAmount);

                (tokenAmountInFirstSwap,) = pool.swapExactAmountOut(
                    swap.tokenIn,
                    swap.limitReturnAmount,
                    swap.tokenOut,
                    swap.swapAmount,
                    swap.maxPrice
                );
            } else {
                // Consider we are swapping A -> B and B -> C. The goal is to buy a given amount
                // of token C. But first we need to buy B with A so we can then buy C with B
                // To get the exact amount of C we then first need to calculate how much B we'll need:
                uint intermediateTokenAmount;
                // This would be token B as described above
                Swap memory secondSwap = swapSequences[i][1];
                IBPool poolSecondSwap = IBPool(secondSwap.pool);
                intermediateTokenAmount = poolSecondSwap.calcInGivenOut(
                    poolSecondSwap.getBalance(secondSwap.tokenIn),
                    poolSecondSwap.getDenormalizedWeight(secondSwap.tokenIn),
                    poolSecondSwap.getBalance(secondSwap.tokenOut),
                    poolSecondSwap.getDenormalizedWeight(secondSwap.tokenOut),
                    secondSwap.swapAmount,
                    poolSecondSwap.swapFee()
                );

                //// Buy intermediateTokenAmount of token B with A in the first pool
                Swap memory firstSwap = swapSequences[i][0];
                IERC20 FirstSwapTokenIn = IERC20(firstSwap.tokenIn);
                IBPool poolFirstSwap = IBPool(firstSwap.pool);
                if (FirstSwapTokenIn.allowance(address(this), firstSwap.pool) < uint(- 1)) {
                    FirstSwapTokenIn.safeApprove(firstSwap.pool, uint(- 1));
                }

                (tokenAmountInFirstSwap,) = poolFirstSwap.swapExactAmountOut(
                    firstSwap.tokenIn,
                    firstSwap.limitReturnAmount,
                    firstSwap.tokenOut,
                    intermediateTokenAmount, // This is the amount of token B we need
                    firstSwap.maxPrice
                );

                //// Buy the final amount of token C desired
                IERC20 SecondSwapTokenIn = IERC20(secondSwap.tokenIn);
                if (SecondSwapTokenIn.allowance(address(this), secondSwap.pool) < uint(- 1)) {
                    SecondSwapTokenIn.safeApprove(secondSwap.pool, uint(- 1));
                }

                poolSecondSwap.swapExactAmountOut(
                    secondSwap.tokenIn,
                    secondSwap.limitReturnAmount,
                    secondSwap.tokenOut,
                    secondSwap.swapAmount,
                    secondSwap.maxPrice
                );
            }
            totalAmountIn = tokenAmountInFirstSwap.add(totalAmountIn);
        }

        require(totalAmountIn <= maxTotalAmountIn, "ERR_LIMIT_IN");

        transferAll(tokenOut, getBalance(tokenOut));
        transferAll(tokenIn, getBalance(tokenIn));

    }

    function smartSwapExactIn(
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint totalAmountIn,
        uint minTotalAmountOut,
        uint nPools,
        uint8 flag
    )
    public payable discountCHI(flag)
    returns (uint totalAmountOut)
    {
        Swap[] memory swaps;
        if (isETH(tokenIn)) {
            (swaps,) = viewSplitExactIn(address(weth), address(tokenOut), totalAmountIn, nPools);
        } else if (isETH(tokenOut)) {
            (swaps,) = viewSplitExactIn(address(tokenIn), address(weth), totalAmountIn, nPools);
        } else {
            (swaps,) = viewSplitExactIn(address(tokenIn), address(tokenOut), totalAmountIn, nPools);
        }

        totalAmountOut = batchSwapExactIn(swaps, tokenIn, tokenOut, totalAmountIn, minTotalAmountOut, 0x0);
    }

    function smartSwapExactOut(
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint totalAmountOut,
        uint maxTotalAmountIn,
        uint nPools,
        uint8 flag
    )
    public payable discountCHI(flag)
    returns (uint totalAmountIn)
    {
        Swap[] memory swaps;
        if (isETH(tokenIn)) {
            (swaps,) = viewSplitExactOut(address(weth), address(tokenOut), totalAmountOut, nPools);
        } else if (isETH(tokenOut)) {
            (swaps,) = viewSplitExactOut(address(tokenIn), address(weth), totalAmountOut, nPools);
        } else {
            (swaps,) = viewSplitExactOut(address(tokenIn), address(tokenOut), totalAmountOut, nPools);
        }

        totalAmountIn = batchSwapExactOut(swaps, tokenIn, tokenOut, maxTotalAmountIn, 0x0);
    }

    function viewSplitExactIn(
        address tokenIn,
        address tokenOut,
        uint swapAmount,
        uint nPools
    )
    public view
    returns (Swap[] memory swaps, uint totalOutput)
    {
        address[] memory poolAddresses = registry.getBestPoolsWithLimit(tokenIn, tokenOut, nPools);

        Pool[] memory pools = new Pool[](poolAddresses.length);
        uint sumEffectiveLiquidity;
        for (uint i = 0; i < poolAddresses.length; i++) {
            pools[i] = getPoolData(tokenIn, tokenOut, poolAddresses[i]);
            sumEffectiveLiquidity = sumEffectiveLiquidity.add(pools[i].effectiveLiquidity);
        }

        uint[] memory bestInputAmounts = new uint[](pools.length);
        uint totalInputAmount;
        for (uint i = 0; i < pools.length; i++) {
            bestInputAmounts[i] = swapAmount.mul(pools[i].effectiveLiquidity).div(sumEffectiveLiquidity);
            totalInputAmount = totalInputAmount.add(bestInputAmounts[i]);
        }

        if (totalInputAmount < swapAmount) {
            bestInputAmounts[0] = bestInputAmounts[0].add(swapAmount.sub(totalInputAmount));
        } else {
            bestInputAmounts[0] = bestInputAmounts[0].sub(totalInputAmount.sub(swapAmount));
        }

        swaps = new Swap[](pools.length);

        for (uint i = 0; i < pools.length; i++) {
            swaps[i] = Swap({
            pool : pools[i].pool,
            tokenIn : tokenIn,
            tokenOut : tokenOut,
            swapAmount : bestInputAmounts[i],
            limitReturnAmount : 0,
            maxPrice : uint(- 1)
            });
        }

        totalOutput = calcTotalOutExactIn(bestInputAmounts, pools);

        return (swaps, totalOutput);
    }

    function viewSplitExactOut(
        address tokenIn,
        address tokenOut,
        uint swapAmount,
        uint nPools
    )
    public view
    returns (Swap[] memory swaps, uint totalOutput)
    {
        address[] memory poolAddresses = registry.getBestPoolsWithLimit(tokenIn, tokenOut, nPools);

        Pool[] memory pools = new Pool[](poolAddresses.length);
        uint sumEffectiveLiquidity;
        for (uint i = 0; i < poolAddresses.length; i++) {
            pools[i] = getPoolData(tokenIn, tokenOut, poolAddresses[i]);
            sumEffectiveLiquidity = sumEffectiveLiquidity.add(pools[i].effectiveLiquidity);
        }

        uint[] memory bestInputAmounts = new uint[](pools.length);
        uint totalInputAmount;
        for (uint i = 0; i < pools.length; i++) {
            bestInputAmounts[i] = swapAmount.mul(pools[i].effectiveLiquidity).div(sumEffectiveLiquidity);
            totalInputAmount = totalInputAmount.add(bestInputAmounts[i]);
        }

        if (totalInputAmount < swapAmount) {
            bestInputAmounts[0] = bestInputAmounts[0].add(swapAmount.sub(totalInputAmount));
        } else {
            bestInputAmounts[0] = bestInputAmounts[0].sub(totalInputAmount.sub(swapAmount));
        }

        swaps = new Swap[](pools.length);

        for (uint i = 0; i < pools.length; i++) {
            swaps[i] = Swap({
            pool : pools[i].pool,
            tokenIn : tokenIn,
            tokenOut : tokenOut,
            swapAmount : bestInputAmounts[i],
            limitReturnAmount : uint(- 1),
            maxPrice : uint(- 1)
            });
        }

        totalOutput = calcTotalOutExactOut(bestInputAmounts, pools);

        return (swaps, totalOutput);
    }

    function getPoolData(
        address tokenIn,
        address tokenOut,
        address poolAddress
    )
    internal view
    returns (Pool memory)
    {
        IBPool pool = IBPool(poolAddress);
        uint tokenBalanceIn = pool.getBalance(tokenIn);
        uint tokenBalanceOut = pool.getBalance(tokenOut);
        uint tokenWeightIn = pool.getDenormalizedWeight(tokenIn);
        uint tokenWeightOut = pool.getDenormalizedWeight(tokenOut);
        uint swapFee = pool.swapFee();

        uint effectiveLiquidity = calcEffectiveLiquidity(
            tokenWeightIn,
            tokenBalanceOut,
            tokenWeightOut
        );
        Pool memory returnPool = Pool({
        pool : poolAddress,
        tokenBalanceIn : tokenBalanceIn,
        tokenWeightIn : tokenWeightIn,
        tokenBalanceOut : tokenBalanceOut,
        tokenWeightOut : tokenWeightOut,
        swapFee : swapFee,
        effectiveLiquidity : effectiveLiquidity
        });

        return returnPool;
    }

    function calcEffectiveLiquidity(
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut
    )
    internal pure
    returns (uint effectiveLiquidity)
    {

        // Bo * wi/(wi+wo)
        effectiveLiquidity =
        tokenWeightIn.mul(BONE).div(
            tokenWeightOut.add(tokenWeightIn)
        ).mul(tokenBalanceOut).div(BONE);

        return effectiveLiquidity;
    }

    function calcTotalOutExactIn(
        uint[] memory bestInputAmounts,
        Pool[] memory bestPools
    )
    internal pure
    returns (uint totalOutput)
    {
        totalOutput = 0;
        for (uint i = 0; i < bestInputAmounts.length; i++) {
            uint output = IBPool(bestPools[i].pool).calcOutGivenIn(
                bestPools[i].tokenBalanceIn,
                bestPools[i].tokenWeightIn,
                bestPools[i].tokenBalanceOut,
                bestPools[i].tokenWeightOut,
                bestInputAmounts[i],
                bestPools[i].swapFee
            );

            totalOutput = totalOutput.add(output);
        }
        return totalOutput;
    }

    function calcTotalOutExactOut(
        uint[] memory bestInputAmounts,
        Pool[] memory bestPools
    )
    internal pure
    returns (uint totalOutput)
    {
        totalOutput = 0;
        for (uint i = 0; i < bestInputAmounts.length; i++) {
            uint output = IBPool(bestPools[i].pool).calcInGivenOut(
                bestPools[i].tokenBalanceIn,
                bestPools[i].tokenWeightIn,
                bestPools[i].tokenBalanceOut,
                bestPools[i].tokenWeightOut,
                bestInputAmounts[i],
                bestPools[i].swapFee
            );

            totalOutput = totalOutput.add(output);
        }
        return totalOutput;
    }

    function transferFromAll(IERC20 token, uint amount) internal returns (bool) {
        if (isETH(token)) {
            weth.deposit{value : msg.value}();
        } else {
            token.safeTransferFrom(msg.sender, address(this), amount);
        }
        return true;
    }

    function getBalance(IERC20 token) internal view returns (uint) {
        if (isETH(token)) {
            return weth.balanceOf(address(this));
        } else {
            return token.balanceOf(address(this));
        }
    }

    function transferAll(IERC20 token, uint amount) internal returns (bool) {
        if (amount == 0) {
            return true;
        }

        if (isETH(token)) {
            weth.withdraw(amount);
            (bool xfer,) = msg.sender.call{value : amount}("");
            require(xfer, "ERR_ETH_FAILED");
        } else {
            token.safeTransfer(msg.sender, amount);
        }
        return true;
    }

    function isETH(IERC20 token) internal pure returns (bool) {
        return (address(token) == ETH_ADDRESS);
    }

    /**
     * This function allows governance to take unsupported tokens out of the contract.
     * This is in an effort to make someone whole, should they seriously mess up.
     * There is no guarantee governance will vote to return these.
     * It also allows for removal of airdropped tokens.
     */
    function governanceRecoverUnsupported(IERC20 _token, uint _amount, address _to) external {
        require(msg.sender == governance, "!governance");
        if (isETH(_token)) {
            (bool xfer,) = _to.call{value : _amount}("");
            require(xfer, "ERR_ETH_FAILED");
        } else {
            _token.safeTransfer(_to, _amount);
        }
    }

    receive() external payable {}

    function create(
        IBFactory factory,
        address[] memory tokens,
        uint[] calldata balances,
        uint[] calldata denorms,
        uint swapFee,
        uint initPoolSupply,
        uint8 flag
    ) payable external discountCHI(flag) returns (IBPool pool) {
        require(tokens.length == balances.length, "ERR_LENGTH_MISMATCH");
        require(tokens.length == denorms.length, "ERR_LENGTH_MISMATCH");
        pool = factory.newBPool();
        bool containsETH = false;
        for (uint i = 0; i < tokens.length; i++) {
            if (transferFromAllTo(tokens[i], balances[i], address(pool))) {
                containsETH = true;
                tokens[i] = address(weth);
            }
        }
        require(msg.value == 0 || containsETH, "!invalid payable");
        pool.finalize(swapFee, initPoolSupply, tokens, denorms);
        pool.setExchangeProxy(address(this));
        pool.setController(msg.sender);
        uint lpAmount = pool.balanceOf(address(this));
        if (lpAmount > 0) {
            IERC20(pool).safeTransfer(msg.sender, lpAmount);
        }
    }

    function joinPool(
        IBPool pool,
        uint poolAmountOut,
        uint[] calldata maxAmountsIn,
        uint8 flag
    ) payable external discountCHI(flag) {
        address[] memory tokens = pool.getFinalTokens();
        require(maxAmountsIn.length == tokens.length, "ERR_LENGTH_MISMATCH");
        bool containsETH = false;
        for (uint i = 0; i < tokens.length; i++) {
            if (transferFromAllAndApprove(tokens[i], maxAmountsIn[i], address(pool))) {
                containsETH = true;
            }
        }
        require(msg.value == 0 || containsETH, "!invalid payable");
        if (pool.version() == 1001) {
            pool.joinPool(poolAmountOut, maxAmountsIn);
        } else {
            pool.joinPoolFor(msg.sender, poolAmountOut, maxAmountsIn);
        }
        for (uint i = 0; i < tokens.length; i++) {
            transferAll(IERC20(tokens[i]), getBalance(IERC20(tokens[i])));
        }
        uint lpAmount = pool.balanceOf(address(this));
        transferAll(pool, lpAmount);
    }

    function joinswapExternAmountIn(
        IBPool pool,
        address tokenIn,
        uint tokenAmountIn,
        uint minPoolAmountOut,
        uint8 flag
    ) payable external discountCHI(flag) {
        bool containsETH = false;
        if (transferFromAllAndApprove(tokenIn, tokenAmountIn, address(pool))) {
            containsETH = true;
        }
        require(msg.value == 0 || containsETH, "!invalid payable");

        uint poolAmountOut = pool.joinswapExternAmountIn(tokenIn, tokenAmountIn, minPoolAmountOut);
        IERC20(pool).safeTransfer(msg.sender, poolAmountOut);
    }

    function transferFromAllTo(address token, uint amount, address to) internal returns (bool containsETH) {
        if (isETH(IERC20(token))) {
            require(amount == msg.value, "!invalid amount");
            weth.deposit{value : amount}();
            weth.transfer(to,amount);
            containsETH = true;
        } else {
            IERC20(token).safeTransferFrom(msg.sender, to, amount);
        }
        return containsETH;
    }

    function transferFromAllAndApprove(address token, uint amount, address spender) internal returns (bool containsETH) {
        if (isETH(IERC20(token))) {
            require(amount == msg.value, "!invalid amount");
            weth.deposit{value : amount}();
            if (weth.allowance(address(this), spender) > 0) {
                IERC20(address(weth)).safeApprove(address(spender), 0);
            }
            IERC20(address(weth)).safeApprove(spender, amount);
            containsETH = true;
        } else {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            if (IERC20(token).allowance(address(this), spender) > 0) {
                IERC20(token).safeApprove(spender, 0);
            }
            IERC20(token).safeApprove(spender, amount);
        }
        return containsETH;
    }
}