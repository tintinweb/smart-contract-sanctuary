/**
 *Submitted for verification at polygonscan.com on 2021-10-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// Part: AggregatorV3Interface

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// Part: ICurveFi

interface ICurveFi {
    function coins(uint256) external view returns (address);

    function underlying_coins(uint256) external view returns (address);

    function get_virtual_price() external view returns (uint256);

    function calc_token_amount(uint256[3] calldata amounts, bool is_deposit)
        external
        view
        returns (uint256);

    function add_liquidity(
        // CRV 3 pool
        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        // wrapped aave pool
        uint256[3] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external;

    function calc_withdraw_one_coin(uint256 _amount, int128 i)
        external
        view
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount,
        bool use_underlying
    ) external;

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);
}

// Part: ICurveGauge

interface ICurveGauge {
    // function claimable_tokens(address user) external returns (uint256);

    function claimable_reward(address user, address token)
        external
        view
        returns (uint256);

    function claim_rewards(address user) external;

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function balanceOf(address arg0) external view returns (uint256);
}

// Part: IFund

interface IFund {
    function underlying() external view returns (address);

    function fundManager() external view returns (address);

    function relayer() external view returns (address);

    function deposit(uint256 amountWei) external;

    function depositFor(uint256 amountWei, address holder) external;

    function withdraw(uint256 numberOfShares) external;

    function getPricePerShare() external view returns (uint256);

    function totalValueLocked() external view returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address holder)
        external
        view
        returns (uint256);
}

// Part: IGovernable

interface IGovernable {
    function governance() external view returns (address);
}

// Part: IStrategy

interface IStrategy {
    function name() external pure returns (string memory);

    function version() external pure returns (string memory);

    function underlying() external view returns (address);

    function fund() external view returns (address);

    function creator() external view returns (address);

    function withdrawAllToFund() external;

    function withdrawToFund(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256);

    function doHardWork() external;
}

// Part: IUniswapV2Router01

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

// Part: OpenZeppelin/[email protected]/Address

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

// Part: OpenZeppelin/[email protected]/Context

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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/Math

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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

// Part: OpenZeppelin/[email protected]/SafeMath

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

// Part: IUniswapV2Router02

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

// Part: OpenZeppelin/[email protected]/ERC20

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// Part: OpenZeppelin/[email protected]/SafeERC20

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

// Part: PriceFeedLibrary

library PriceFeedLibrary {
    using Address for address;

    function _getDecimals(address priceFeed) internal view returns (uint8) {
        return AggregatorV3Interface(priceFeed).decimals();
    }

    /* solhint-disable no-unused-vars */
    function _getPrice(address priceFeed) internal view returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(priceFeed).latestRoundData();
        require(answeredInRound >= roundID, "Stale data from price feed");
        return price;
    }
    /* solhint-enable no-unused-vars */
}

// Part: SwapTokensLibrary

library SwapTokensLibrary {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    function _getPath(
        address _from,
        address _to,
        address _baseCurrency
    ) internal pure returns (address[] memory) {
        address[] memory path;
        if (_from == _baseCurrency || _to == _baseCurrency) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = _baseCurrency;
            path[2] = _to;
        }
        return path;
    }

    function _liquidateRewards(
        address rewardToken,
        address underlying,
        address _dEXRouter,
        address _baseCurrency,
        uint256 minUnderlyingExpected
    ) internal {
        uint256 rewardAmount = IERC20(rewardToken).balanceOf(address(this));
        if (rewardAmount != 0) {
            IUniswapV2Router02 dEXRouter = IUniswapV2Router02(_dEXRouter);
            address[] memory path =
                _getPath(rewardToken, underlying, _baseCurrency);
            uint256 underlyingAmountOut =
                dEXRouter.getAmountsOut(rewardAmount, path)[path.length - 1];
            if (underlyingAmountOut != 0) {
                IERC20(rewardToken).safeApprove(_dEXRouter, rewardAmount);
                uint256 underlyingBalanceBefore =
                    IERC20(underlying).balanceOf(address(this));
                dEXRouter.swapExactTokensForTokens(
                    rewardAmount,
                    minUnderlyingExpected,
                    path,
                    address(this),
                    // solhint-disable-next-line not-rely-on-time
                    now
                );
                uint256 underlyingBalanceAfter =
                    IERC20(underlying).balanceOf(address(this));
                require(
                    underlyingBalanceAfter.sub(underlyingBalanceBefore) >=
                        minUnderlyingExpected,
                    "Not liquidated properly"
                );
            }
        }
    }
}

// Part: CurveSingleAssetLendingStrategyBase

/**
 * This strategy takes an asset (DAI, USDC, USDT), lends to Curve Pool.
 */
abstract contract CurveSingleAssetLendingStrategyBase is IStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using SafeMath for int128;
    using SafeMath for uint8;

    address public immutable override underlying;
    address public immutable override fund;
    address public immutable override creator;

    // the curve pool corresponding to the underlying
    address public immutable crvPool;

    // the curve token corresponding to the crvPool
    address public immutable crvPoolToken;

    // Does the curve pool have wrapped tokens?
    bool public immutable isWrappedPool;

    // If it is wrapped, are we depositing underlying tokens or wrapped tokens?
    bool public immutable useUnderlying;

    // the  id corresponding to the underlying in crvPool
    uint8 public immutable crvId;

    // CRV Token
    // solhint-disable-next-line var-name-mixedcase
    address public immutable CRVToken;

    // Reward Token
    address public immutable rewardToken;

    // Price feed for reward token
    address public immutable rewardTokenPriceFeed;
    address public immutable crvEthPriceFeed;
    address public immutable usdcEthPriceFeed;

    // Gauge, for staking crvpool token, and claiming rewards
    address public crvPoolGauge;

    // Gauge type. Rewards: {1: Only CRV, 2: CRV + Reward, 3: Only Reward}
    uint8 public immutable crvPoolGaugeType;

    // DEX router to liquidate rewards to underlying
    address internal immutable _rewardDEXRouter;

    // DEX router to liquidate rewards to underlying
    address internal immutable _crvDEXRouter;

    // base currency serves as path to convert rewards to underlying
    address internal immutable _rewardBaseCurrency; // base Currency for RewardToken - USDC
    address internal immutable _crvBaseCurrency; // base Currency for CRV - USDC

    uint256 internal allowedSlippage = 500; // In BPS, can be changed

    uint256 internal constant MAX_BPS = 10000;

    uint256 internal constant PRECISION = 10**18;

    uint256 internal constant MAX_DECIMAL = 18;

    // these tokens cannot be claimed by the governance
    mapping(address => bool) public canNotSweep;

    bool public investActivated;

    constructor(
        address _fund,
        address _crvPool,
        address _crvPoolToken,
        address _crvPoolGauge,
        uint8 _crvPoolGaugeType,
        // solhint-disable-next-line var-name-mixedcase
        address[4] memory _rewardDetails,
        address[5] memory _crvDetails,
        bool _isWrappedPool,
        bool _useUnderlying
    ) public {
        require(_fund != address(0), "Fund cannot be empty");
        require(_crvPool != address(0), "Curve Pool cannot be empty");
        require(
            _crvPoolToken != address(0),
            "Curve Pool token cannot be empty"
        );
        require(
            _crvPoolGauge != address(0),
            "Curve Pool gauge cannot be empty"
        );

        fund = _fund;
        address _underlying = IFund(_fund).underlying();
        underlying = _underlying;
        uint8 _crvId = type(uint8).max;

        if (!(_isWrappedPool) || (_isWrappedPool && !(_useUnderlying))) {
            if (ICurveFi(_crvPool).coins(0) == _underlying) {
                _crvId = 0;
            } else if (ICurveFi(_crvPool).coins(1) == _underlying) {
                _crvId = 1;
            } else if (ICurveFi(_crvPool).coins(2) == _underlying) {
                _crvId = 2;
            }
        } else {
            if (ICurveFi(_crvPool).underlying_coins(0) == _underlying) {
                _crvId = 0;
            } else if (ICurveFi(_crvPool).underlying_coins(1) == _underlying) {
                _crvId = 1;
            } else if (ICurveFi(_crvPool).underlying_coins(2) == _underlying) {
                _crvId = 2;
            }
        }

        require(_crvId < 3, "Incorrect curve pool");

        crvId = _crvId;
        crvPool = _crvPool;
        crvPoolGaugeType = _crvPoolGaugeType;
        crvPoolToken = _crvPoolToken;
        isWrappedPool = _isWrappedPool;
        useUnderlying = _useUnderlying;
        crvPoolGauge = _crvPoolGauge;
        CRVToken = _crvDetails[0];
        rewardToken = _rewardDetails[0];
        rewardTokenPriceFeed = _rewardDetails[2];
        crvEthPriceFeed = _crvDetails[2];
        usdcEthPriceFeed = _crvDetails[3];
        _rewardDEXRouter = _rewardDetails[1];
        _crvDEXRouter = _crvDetails[1];
        _rewardBaseCurrency = _rewardDetails[3];
        _crvBaseCurrency = _crvDetails[4];
        creator = msg.sender;

        // restricted tokens, can not be swept
        canNotSweep[_underlying] = true;
        canNotSweep[_crvPoolToken] = true;
        canNotSweep[_crvPoolGauge] = true;
        canNotSweep[_crvDetails[0]] = true;
        canNotSweep[_rewardDetails[0]] = true;

        investActivated = true;
    }

    function _governance() internal view returns (address) {
        return IGovernable(fund).governance();
    }

    function _fundManager() internal view returns (address) {
        return IFund(fund).fundManager();
    }

    function _relayer() internal view returns (address) {
        return IFund(fund).relayer();
    }

    modifier onlyFund() {
        require(msg.sender == fund, "The sender has to be the fund");
        _;
    }

    modifier onlyFundOrGovernance() {
        require(
            msg.sender == fund || msg.sender == _governance(),
            "The sender has to be the governance or fund"
        );
        _;
    }

    modifier onlyFundManagerOrGovernance() {
        require(
            msg.sender == _fundManager() || msg.sender == _governance(),
            "The sender has to be the governance or fund manager"
        );
        _;
    }

    modifier onlyFundManagerOrRelayer() {
        require(
            msg.sender == _fundManager() || msg.sender == _relayer(),
            "The sender has to be the relayer or fund manager"
        );
        _;
    }

    function setInvestActivated(bool _investActivated)
        external
        onlyFundManagerOrGovernance
    {
        investActivated = _investActivated;
    }

    function _withdrawCrvPoolTokens(uint256 _requiredCrvPoolTokens) internal {
        if (_requiredCrvPoolTokens > 0) {
            ICurveGauge(crvPoolGauge).withdraw(_requiredCrvPoolTokens);
            uint256 expectedOut =
                ICurveFi(crvPool).calc_withdraw_one_coin(
                    _requiredCrvPoolTokens,
                    int128(crvId)
                );
            uint256 minOut =
                expectedOut.mul(MAX_BPS.sub(allowedSlippage)).div(MAX_BPS);

            if (!(isWrappedPool) || (isWrappedPool && !(useUnderlying))) {
                ICurveFi(crvPool).remove_liquidity_one_coin(
                    _requiredCrvPoolTokens,
                    int128(crvId),
                    minOut
                );
            } else {
                ICurveFi(crvPool).remove_liquidity_one_coin(
                    _requiredCrvPoolTokens,
                    int128(crvId),
                    minOut,
                    true
                );
            }
        }
    }

    /**
     * Allows Governance to withdraw partial shares to reduce slippage incurred
     *  and facilitate migration / withdrawal / strategy switch
     */
    function withdrawPartialShares(uint256 _crvPoolTokens)
        external
        onlyFundManagerOrGovernance
    {
        _withdrawCrvPoolTokens(_crvPoolTokens);
    }

    /**
     * Withdraws an underlying asset from the strategy to the fund in the specified amount.
     * It tries to withdraw from the strategy contract if this has enough balance.
     * Otherwise, we withdraw from Curve to the strategy and transfer required balance to fund
     */
    function withdrawToFund(uint256 underlyingAmount)
        external
        override
        onlyFund
    {
        uint256 underlyingBalanceBefore =
            IERC20(underlying).balanceOf(address(this));

        if (underlyingBalanceBefore >= underlyingAmount) {
            IERC20(underlying).safeTransfer(fund, underlyingAmount);
            return;
        }

        uint256[3] memory amounts;
        amounts[crvId] = underlyingAmount;
        uint256 _requiredCrvPoolTokens =
            ICurveFi(crvPool).calc_token_amount(amounts, false);
        uint256 _totalCrvPoolTokens =
            IERC20(crvPoolGauge).balanceOf(address(this));

        if (_requiredCrvPoolTokens > _totalCrvPoolTokens) {
            //can't withdraw more than we have
            _requiredCrvPoolTokens = _totalCrvPoolTokens;
        }

        _withdrawCrvPoolTokens(_requiredCrvPoolTokens);

        // we can transfer the asset to the fund
        uint256 underlyingBalance = IERC20(underlying).balanceOf(address(this));
        if (underlyingBalance > 0) {
            if (underlyingAmount < underlyingBalance) {
                IERC20(underlying).safeTransfer(fund, underlyingAmount);
                _investAllUnderlying();
            } else {
                IERC20(underlying).safeTransfer(fund, underlyingBalance);
            }
        }
    }

    /**
     * Withdraws all assets from the Curve Pool to fund.
     */
    function withdrawAllToFund() external override onlyFund {
        uint256 _crvPoolTokens = IERC20(crvPoolGauge).balanceOf(address(this));
        _withdrawCrvPoolTokens(_crvPoolTokens);

        uint256 underlyingBalance = IERC20(underlying).balanceOf(address(this));
        if (underlyingBalance > 0) {
            IERC20(underlying).safeTransfer(fund, underlyingBalance);
        }
    }

    /**
     * Invests all underlying assets into our curve.
     */
    function _investAllUnderlying() internal {
        if (!investActivated) {
            return;
        }

        uint256 underlyingBalance = IERC20(underlying).balanceOf(address(this));
        if (underlyingBalance > 0) {
            // approve amount per transaction
            IERC20(underlying).safeApprove(crvPool, 0);
            IERC20(underlying).safeApprove(crvPool, underlyingBalance);
            uint256[3] memory amounts;
            amounts[crvId] = underlyingBalance;
            uint256 expectedOut =
                ICurveFi(crvPool).calc_token_amount(amounts, true);
            uint256 minOut =
                expectedOut.mul(MAX_BPS.sub(allowedSlippage)).div(MAX_BPS);

            if (!(isWrappedPool) || (isWrappedPool && !(useUnderlying))) {
                ICurveFi(crvPool).add_liquidity(amounts, minOut);
            } else {
                ICurveFi(crvPool).add_liquidity(amounts, minOut, true);
            }
        }

        // deposit lptokens to the gauge
        uint256 crvPoolTokens = IERC20(crvPoolToken).balanceOf(address(this));
        if (crvPoolTokens > 0) {
            // approve amount per transaction
            IERC20(crvPoolToken).safeApprove(crvPoolGauge, 0);
            IERC20(crvPoolToken).safeApprove(crvPoolGauge, crvPoolTokens);
            ICurveGauge(crvPoolGauge).deposit(crvPoolTokens);
        }
    }

    /**
     * The hard work only invests all underlying assets
     */
    function doHardWork() external override onlyFund {
        _investAllUnderlying();
    }

    // no tokens apart from underlying should be sent to this contract. Any tokens that are sent here by mistake are recoverable by governance
    function sweep(address _token, address _sweepTo) external {
        require(_governance() == msg.sender, "Not governance");
        require(!canNotSweep[_token], "Token is restricted");
        require(_sweepTo != address(0), "can not sweep to zero");
        IERC20(_token).safeTransfer(
            _sweepTo,
            IERC20(_token).balanceOf(address(this))
        );
    }

    function _getCRVRewardsBalance() internal view returns (uint256) {
        uint256 crvRewardsBalance;
        if (crvPoolGaugeType == 1 || crvPoolGaugeType == 2) {
            crvRewardsBalance = ICurveGauge(crvPoolGauge).claimable_reward(
                address(this),
                CRVToken
            );
        }
        return crvRewardsBalance;
    }

    function getCRVRewardsBalance() external view returns (uint256) {
        return _getCRVRewardsBalance();
    }

    function _getRewardsBalance() internal view returns (uint256) {
        uint256 rewardsBalance;
        if (crvPoolGaugeType == 2 || crvPoolGaugeType == 3) {
            rewardsBalance = ICurveGauge(crvPoolGauge).claimable_reward(
                address(this),
                rewardToken
            );
        }
        return rewardsBalance;
    }

    // This will claim rewards, as it is called as a transaction
    function getRewardsBalance() external view returns (uint256) {
        return _getRewardsBalance();
    }

    function _claimRewards() internal {
        ICurveGauge(crvPoolGauge).claim_rewards(address(this));
    }

    // This function will claim both reward and Crv
    function claimRewards() external {
        _claimRewards();
    }

    function _getRewardPriceInUnderlying() internal view returns (uint256) {
        return uint256(PriceFeedLibrary._getPrice(rewardTokenPriceFeed));
    }

    function _getCRVPriceInUnderlying() internal view returns (uint256) {
        uint256 crvEthPrice =
            uint256(PriceFeedLibrary._getPrice(crvEthPriceFeed));
        uint256 usdcEthPrice =
            uint256(PriceFeedLibrary._getPrice(usdcEthPriceFeed));
        return
            crvEthPrice
                .mul(
                10**uint256(PriceFeedLibrary._getDecimals(usdcEthPriceFeed))
            )
                .div(usdcEthPrice); // if 1 USDC is more than 1 eth, then there will be data loss, but seems to be very unlikely situation
    }

    function updateSlippage(uint256 newSlippage)
        external
        onlyFundManagerOrGovernance
    {
        require(newSlippage > 0, "The slippage should be greater than 0");
        require(
            newSlippage < MAX_BPS,
            "The slippage should be less than 10000"
        );
        allowedSlippage = newSlippage;
    }

    function _getMinUnderlyingExpectedFromRewards()
        internal
        view
        returns (uint256)
    {
        uint256 rewardPriceInUnderlying = _getRewardPriceInUnderlying();
        uint256 rewardAmount = IERC20(rewardToken).balanceOf(address(this));
        uint256 minUnderlyingExpected =
            rewardPriceInUnderlying
                .mul(
                rewardAmount.sub(rewardAmount.mul(allowedSlippage).div(MAX_BPS))
            )
                .mul(10**uint256(ERC20(underlying).decimals()))
                .div(
                10**uint256(PriceFeedLibrary._getDecimals(rewardTokenPriceFeed))
            )
                .div(10**uint256(ERC20(rewardToken).decimals()));
        return minUnderlyingExpected;
    }

    function _getMinUnderlyingExpectedFromCRV()
        internal
        view
        returns (uint256)
    {
        uint256 rewardPriceInUnderlying = _getCRVPriceInUnderlying();
        uint256 crvAmount = IERC20(CRVToken).balanceOf(address(this));
        uint256 minUnderlyingExpected =
            rewardPriceInUnderlying
                .mul(crvAmount.sub(crvAmount.mul(allowedSlippage).div(MAX_BPS)))
                .mul(10**uint256(ERC20(underlying).decimals()))
                .div(
                10**uint256(PriceFeedLibrary._getDecimals(usdcEthPriceFeed))
            )
                .div(10**uint256(ERC20(CRVToken).decimals()));
        return minUnderlyingExpected;
    }

    function _liquidateCRVRewards() internal {
        uint256 minUnderlyingExpected = _getMinUnderlyingExpectedFromCRV(); // TODO
        SwapTokensLibrary._liquidateRewards(
            CRVToken,
            underlying,
            _crvDEXRouter,
            _crvBaseCurrency,
            minUnderlyingExpected
        );
    }

    function _liquidateRewards() internal {
        uint256 minUnderlyingExpected = _getMinUnderlyingExpectedFromRewards();
        SwapTokensLibrary._liquidateRewards(
            rewardToken,
            underlying,
            _rewardDEXRouter,
            _rewardBaseCurrency,
            minUnderlyingExpected
        );
    }

    /**
     * This claims the rewards, liquidates all the reward token to underlying and reinvests
     */
    function claimLiquidateAndReinvestRewards()
        external
        onlyFundManagerOrRelayer
    {
        _claimRewards();
        _liquidateCRVRewards();
        _liquidateRewards();
        _investAllUnderlying();
    }

    function _virtualPriceInUnderlying() internal view returns (uint256) {
        if (ERC20(underlying).decimals() < MAX_DECIMAL) {
            return
                ICurveFi(crvPool).get_virtual_price().div(
                    10 **
                        (
                            uint256(
                                uint8(MAX_DECIMAL) -
                                    ERC20(underlying).decimals()
                            )
                        )
                );
        } else {
            return ICurveFi(crvPool).get_virtual_price();
        }
    }

    /**
     * Returns the underlying invested balance. This is the underlying amount based on atoken balance,
     * plus the current balance of the underlying asset.
     */
    function investedUnderlyingBalance()
        external
        view
        override
        returns (uint256)
    {
        uint256 _crvPoolTokens = IERC20(crvPoolGauge).balanceOf(address(this));

        if (_crvPoolTokens == 0) {
            return 0;
        }

        //we want to choose lower value of virtual price and amount we really get out
        //this means we will always underestimate current assets.
        uint256 virtualOut =
            _virtualPriceInUnderlying().mul(_crvPoolTokens).div(PRECISION);

        uint256 realOut =
            ICurveFi(crvPool).calc_withdraw_one_coin(
                _crvPoolTokens,
                int128(crvId)
            );

        return
            Math.min(virtualOut, realOut).add(
                IERC20(underlying).balanceOf(address(this))
            );
    }
}

// File: CurveSingleAssetLendingStrategyPolygonMainnetAUSD.sol

/**
 * Adds the polygon mainnet addresses to the CurveSingleAssetLendingStrategyBase
 */
contract CurveSingleAssetLendingStrategyPolygonMainnetAUSD is
    CurveSingleAssetLendingStrategyBase
{
    string public constant override name =
        "CurveSingleAssetLendingStrategyPolygonMainnetAUSD";
    string public constant override version = "V1";

    // Required Curve Pool (aave USD)
    address internal constant _crvPool =
        address(0x445FE580eF8d70FF569aB36e80c647af338db351);

    // Corresponding curve pool token (am3crv)
    address internal constant _crvPoolToken =
        address(0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171);

    // Gauge for rewards
    address internal constant _crvPoolGauge =
        address(0x19793B454D3AfC7b454F206Ffe95aDE26cA6912c);

    // Gauge type. Rewards: {1: Only CRV, 2: CRV + Reward, 3: Only Reward}
    uint8 internal constant _crvPoolGaugeType = 2;

    // CRV token as rewards
    address internal constant _CRVToken =
        address(0x172370d5Cd63279eFa6d502DAB29171933a610AF);

    // MATIC token as rewards
    address internal constant MATIC =
        address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

    // Base currency for CRV-USDC route:
    address internal constant WETH =
        address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);

    // Extra reward token price feed
    address internal constant _rewardTokenPriceFeed =
        address(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);

    // Crv token price feed:
    // CRV-ETH Price Feed:
    address internal constant _crvEthPriceFeed =
        address(0x1CF68C76803c9A415bE301f50E82e44c64B7F1D4);

    // USDC-ETH Price Feed
    address internal constant _usdcEthPriceFeed =
        address(0xefb7e6be8356cCc6827799B6A7348eE674A80EaE);

    // Quickswap (Uniswap V2 fork) router to liquidate MATIC rewards to underlying
    address internal constant _quickswapRouter =
        address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

    // SushiSwap (Uniswap V2 fork) router to liquidate CRV rewards to underlying
    address internal constant _sushiswapRouter =
        address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    constructor(address _fund)
        public
        CurveSingleAssetLendingStrategyBase(
            _fund,
            _crvPool,
            _crvPoolToken,
            _crvPoolGauge,
            _crvPoolGaugeType,
            [MATIC, _quickswapRouter, _rewardTokenPriceFeed, MATIC],
            [
                _CRVToken,
                _sushiswapRouter,
                _crvEthPriceFeed,
                _usdcEthPriceFeed,
                WETH
            ],
            true, // AUSD is a wrapped pool
            true // we are depositing underlying coin (not aToken)
        )
    // solhint-disable-next-line no-empty-blocks
    {

    }
}