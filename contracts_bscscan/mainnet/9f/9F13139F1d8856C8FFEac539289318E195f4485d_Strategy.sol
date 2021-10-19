/**
 *Submitted for verification at BscScan.com on 2021-10-19
*/

// File: interfaces/flashloan/IFlashloanReceiver.sol


pragma solidity 0.6.12;

interface IFlashLoanReceiver {
  function executeOperation(address sender, address underlying, uint amount, uint fee, bytes calldata params) external;
}

interface ICTokenFlashloan {
  function flashLoan(address receiver, uint amount, bytes calldata params) external;
}
// File: interfaces/uniswap/IUniswapV2Router.sol


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

// File: interfaces/venus/InterestRateModel.sol


pragma solidity 0.6.12;

interface InterestRateModel {
  /**
   * @notice Calculates the current borrow interest rate per block
   * @param cash The total amount of cash the market has
   * @param borrows The total amount of borrows the market has outstanding
   * @param reserves The total amount of reserves the market has
   * @return The borrow rate per block (as a percentage, and scaled by 1e18)
   */
  function getBorrowRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) external view returns (uint256, uint256);

  /**
   * @notice Calculates the current supply interest rate per block
   * @param cash The total amount of cash the market has
   * @param borrows The total amount of borrows the market has outstanding
   * @param reserves The total amount of reserves the market has
   * @param reserveFactorMantissa The current reserve factor the market has
   * @return The supply rate per block (as a percentage, and scaled by 1e18)
   */
  function getSupplyRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves,
    uint256 reserveFactorMantissa
  ) external view returns (uint256);
}

// File: interfaces/venus/VTokenI.sol


pragma solidity 0.6.12;


interface VTokenI {
  event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);
  
  event Mint(address minter, uint mintAmount, uint mintTokens);
  
  event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);
  
  event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);
  
  event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);
  
  event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address vTokenCollateral, uint seizeTokens);
  
  event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
  
  event NewAdmin(address oldAdmin, address newAdmin);
  
  event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);
  
  event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);
  
  event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);
  
  event Transfer(address indexed from, address indexed to, uint amount);
  
  event Approval(address indexed owner, address indexed spender, uint amount);
  
  event Failure(uint error, uint info, uint detail);

  
  function transfer(address dst, uint amount) external returns (bool);
  
  function transferFrom(address src, address dst, uint amount) external returns (bool);
  
  function approve(address spender, uint amount) external returns (bool);
  
  function allowance(address owner, address spender) external view returns (uint);
  
  function balanceOf(address owner) external view returns (uint);
  
  function balanceOfUnderlying(address owner) external returns (uint);
  
  function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
  
  function borrowRatePerBlock() external view returns (uint);
  
  function supplyRatePerBlock() external view returns (uint);
  
  function totalBorrowsCurrent() external returns (uint);
  
  function borrowBalanceCurrent(address account) external returns (uint);
  
  function borrowBalanceStored(address account) external view returns (uint);

  function exchangeRateCurrent() external returns (uint);
  
  function exchangeRateStored() external view returns (uint);

  function getCash() external view returns (uint);

  function accrueInterest() external returns (uint);

  function totalReserves() external view returns (uint);

  function accrualBlockNumber() external view returns (uint);

  function interestRateModel() external view returns (InterestRateModel);

  function reserveFactorMantissa() external view returns (uint);

  function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);

  function totalBorrows() external view returns (uint);

  function totalSupply() external view returns (uint);
}
// File: interfaces/venus/UnitrollerI.sol


pragma solidity 0.6.12;


interface UnitrollerI {
  function enterMarkets(address [] calldata vTokens) external returns (uint[] memory);
  function exitMarket(address vToken) external returns (uint);

  function mintAllowed(address vToken, address minter, uint256 mintAmount) external returns (uint256);
  function mintVerify(address vToken, address minter, uint256 mintAmount, uint256 mintTokens) external;

  function redeemAllowed(address vToken, address redeemer, uint256 redeemTokens) external returns (uint256);
  function redeemVerify(address vToken, address redeemer, uint256 redeemAmount, uint256 redeemTokens) external;

  function borrowAllowed(address vToken, address borrower, uint256 borrowAmount) external returns (uint256);
  function borrowVerify(address vToken, address borrower, uint256 borrowAmount) external;

  function repayBorrowAllowed(address vToken, address payer, address borrower, uint256 repayAmount) external returns (uint256);
  function repayBorrowVerify(address vToken, address payer, address borrower, uint256 repayAmount, uint256 borrowerIndex) external;

  function liquidateBorrowAllowed(
    address vTokenBorrowed,
    address vTokenCollateral,
    address liquidator,
    address borrower,
    uint256 repayAmount
  ) external returns (uint256);

  function liquidateBorrowVerify(
    address vTokenBorrowed,
    address vTokenCollateral,
    address liquidator,
    address borrower,
    uint256 repayAmount,
    uint256 seizeTokens
  ) external;

  function seizeAllowed(
    address vTokenCollateral,
    address vTokenBorrowed,
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external returns (uint256);

  function seizeVerify(
    address vTokenCollateral,
    address vTokenBorrowed,
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external;

  function transferAllowed(
    address vToken,
    address src,
    address dst,
    uint256 transferTokens
  ) external returns (uint256);

  function transferVerify(
    address vToken,
    address src,
    address dst,
    uint256 transferTokens
  ) external;

  function liquidateCalculateSeizeTokens(
    address vTokenBorrowed,
    address vTokenCollateral,
    uint256 repayAmount
  ) external view returns (uint256, uint256);

  function getAccountLiquidity(address account) external view returns (uint256, uint256, uint256);

  function claimVenus(address holder) external;
  function claimVenus(address holder, VTokenI[] memory vTokens) external;

  function markets(address vToken) external view returns (bool, uint256, bool);

  function venusSpeeds(address vtoken) external view returns (uint256);
}

// File: interfaces/venus/VBep20I.sol


pragma solidity 0.6.12;


interface VBep20I is VTokenI {
  function mint(uint mintAmount) external returns (uint);
  function redeem(uint redeemTokens) external returns (uint);
  function redeemUnderlying(uint redeemAmount) external returns (uint);
  function borrow(uint borrowAmount) external returns (uint);
  function repayBorrow(uint repayAmount) external returns (uint);
  function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
  function liquidateBorrow(address borrower, uint repayAmount, VTokenI vTokenCollateral) external returns (uint);
}
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/utils/Address.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/math/SafeMath.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/token/ERC20/IERC20.sol



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

// File: interfaces/VaultAPI.sol


pragma solidity 0.6.12;


struct StrategyParams {
  uint256 performanceFee;
  uint256 activation;
  uint256 debtRatio;
  uint256 rateLimit;
  uint256 lastReport;
  uint256 totalDebt;
  uint256 totalGain;
  uint256 totalLoss;
}

interface VaultAPI is IERC20 {

  function apiVersion() external view returns (string memory);

  function withdraw(uint256 shares, address recipient, uint256 maxLoss) external;

  function token() external view returns (address);

  function strategies(address _strategy) external view returns (StrategyParams memory);

  function creditAvailable(address _strategy) external view returns (uint256);

  function debtOutstanding(address _strategy) external view returns (uint256);

  function expectedReturn(address _strategy) external view returns (uint256);

  function report(
    uint256 _gain,
    uint256 _loss,
    uint256 _debtPayment
  ) external returns (uint256);

  function revokeStrategy(address _strategy) external;

  function governance() external view returns (address);

}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/token/ERC20/SafeERC20.sol



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

// File: strategies/BaseStrategy.sol


pragma solidity 0.6.12;





/**
 *  BaseStrategy implements all of the required functionality to interoperate
 *  closely with the Vault contract. This contract should be inherited and the
 *  abstract methods implemented to adapt the Strategy to the particular needs
 *  it has to create a return.
 *
 *  Of special interest is the relationship between `harvest()` and
 *  `vault.report()'. `harvest()` may be called simply because enough time has
 *  elapsed since the last report, and not because any funds need to be moved
 *  or positions adjusted. This is critical so that the Vault may maintain an
 *  accurate picture of the Strategy's performance. See  `vault.report()`,
 *  `harvest()`, and `harvestTrigger()` for further details.
 */
abstract contract BaseStrategy {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  
  function apiVersion() public pure returns (string memory) {
    return '0.1.0';
  }

  function name() external virtual view returns (string memory);

  function delegatedAssets() external virtual pure returns (uint256) {
    return 0;
  }

  VaultAPI public immutable vault;
  
  address public strategist;
  address public rewards;
  address public keeper;


  IERC20 public immutable want;

  // The maximum number of seconds between harvest calls.
  uint256 public maxReportDelay = 86400;    // once a day

  // The minimum multiple that `callCost` must be above the credit/profit to
  // be "justifiable". See `setProfitFactor()` for more details.
  uint256 public profitFactor = 100;

  // Use this to adjust the threshold at which running a debt causes a
  // harvest trigger. See `setDebtThreshold()` for more details.
  uint256 public debtThreshold = 0;

  bool public emergencyExit;

  mapping (address => bool) public protected;
  
  event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);
  
  event UpdatedReportDelay(uint256 delay);
  
  event UpdatedProfitFactor(uint256 profitFactor);
  
  event UpdatedDebtThreshold(uint256 debtThreshold);
  
  event UpdatedStrategist(address newStrategist);

  event UpdatedKeeper(address newKeeper);

  event UpdatedRewards(address rewards);

  event EmergencyExitEnabled();

  modifier onlyKeepers() {
    require(msg.sender == keeper || msg.sender == strategist || msg.sender == governance(), "!keeper & !strategist & !governance");
    _;
  }

  modifier onlyAuthorized() {
    require(msg.sender == strategist || msg.sender == governance(), "!strategist & !governance");
    _;
  }

  modifier onlyGovernance() {
    require(msg.sender == governance(), "!authorized");
    _;
  }

  modifier onlyStrategist() {
    require(msg.sender == strategist, "!strategist");
    _;
  }

  constructor(address _vault) public {
    vault = VaultAPI(_vault);
    want = IERC20(VaultAPI(_vault).token());
    IERC20(VaultAPI(_vault).token()).safeApprove(_vault, uint256(-1));
    strategist = msg.sender;
    rewards = msg.sender;
    keeper = msg.sender;
  }

  function setStrategist(address _strategist) external onlyAuthorized {
    require(_strategist != address(0));
    strategist = _strategist;
    emit UpdatedStrategist(_strategist);
  }

  function setKeeper(address _keeper) external onlyAuthorized {
    require(_keeper != address(0));
    keeper = _keeper;
    emit UpdatedKeeper(_keeper);
  }

  function setRewards(address _rewards) external onlyStrategist {
    require(_rewards != address(0));
    rewards = _rewards;
    emit UpdatedRewards(_rewards);
  }

  function governance() internal view returns (address) {
    return vault.governance();
  }

  /**
   * @notice
   *  Provide an accurate estimate for the total amount of assets
   *  (principle + return) that this Strategy is currently managing,
   *  denominated in terms of `want` tokens.
   * @return The estimated total assets in this Strategy.
   */
  function estimatedTotalAssets() public virtual view returns (uint256);

  /**
   * @notice
   *  Provide an indication of whether this strategy is currently "active"
   *  in that it is managing an active position, or will manage a position in
   *  the future. This should correlate to `harvest()` activity, so that Harvest
   *  events can be tracked externally by indexing agents.
   * @return True if the strategy is actively managing a position.
   */
  function isActive() public view returns (bool) {
    return vault.strategies(address(this)).debtRatio > 0 || estimatedTotalAssets() > 0;
  }

  /**
   * Perform any Strategy unwinding or other calls necessary to capture the
   * "free return" this Strategy has generated since the last time its core
   * position(s) were adjusted. Examples include unwrapping extra rewards.
   * This call is only used during "normal operation" of a Strategy, and
   * should be optimized to minimize losses as much as possible.
   *
   * This method returns any realized profits and/or realized losses
   * incurred, and should return the total amounts of profits/losses/debt
   * payments (in `want` tokens) for the Vault's accounting (e.g.
   * `want.balanceOf(this) >= _debtPayment + _profit - _loss`).
   */
  function prepareReturn(uint256 _debtOutstanding) internal virtual returns (
    uint256 _profit,
    uint256 _loss,
    uint256 _debtPayment
  );

  /**
   * Perform any adjustments to the core position(s) of this Strategy given
   * what change the Vault made in the "investable capital" available to the
   * Strategy. Note that all "free capital" in the Strategy after the report
   * was made is available for reinvestment. Also note that this number
   * could be 0, and you should handle that scenario accordingly.
   */
  function adjustPosition(uint256 _debtOutstanding) internal virtual;

  /**
   * Liquidate up to `_amountNeeded` of `want` of this strategy's positions,
   * irregardless of slippage. Any excess will be re-invested with `adjustPosition()`.
   * This function should return the amount of `want` tokens made available by the
   * liquidation. If there is a difference between them, `_loss` indicates whether the
   * difference is due to a realized loss, or if there is some other sitution at play
   * (e.g. locked funds). This function is used during emergency exit instead of
   * `prepareReturn()` to liquidate all of the Strategy's positions back to the Vault.
   */
  function liquidatePosition(uint256 _amountNeeded) internal virtual returns (uint256 _liquidatedAmount, uint256 _loss);

  /**
   *  `Harvest()` calls this function after shares are created during
   *  `vault.report()`. You can customize this function to any share
   *  distribution mechanism you want.
   */
  function distributeRewards() internal virtual {
    uint256 balance = vault.balanceOf(address(this));
    if (balance > 0) {
      vault.transfer(rewards, balance);
    }
  }

  function tendTrigger(uint256 callCost) public virtual view returns (bool);

  /**
   * @notice
   *  Provide a signal to the keeper that `tend()` should be called. The
   *  keeper will provide the estimated gas cost that they would pay to call
   *  `tend()`, and this function should use that estimate to make a
   *  determination if calling it is "worth it" for the keeper. This is not
   *  the only consideration into issuing this trigger, for example if the
   *  position would be negatively affected if `tend()` is not called
   *  shortly, then this can return `true` even if the keeper might be
   *  "at a loss" (keepers are always reimbursed by Yearn).
   */
  function tend() external onlyKeepers {
    adjustPosition(vault.debtOutstanding(address(this)));
  }

  function harvestTrigger(uint256 callCost) public virtual view returns (bool) {
    StrategyParams memory params = vault.strategies(address(this));

    if (params.activation == 0) return false;

    if (block.timestamp.sub(params.lastReport) >= maxReportDelay) return true;

    uint256 outstanding = vault.debtOutstanding(address(this));
    if (outstanding > debtThreshold) return true;

    uint256 total = estimatedTotalAssets();

    if (total.add(debtThreshold) < params.totalDebt) return true;

    uint256 profit = 0;
    if (total > params.totalDebt) profit = total.sub(params.totalDebt);

    uint256 credit = vault.creditAvailable(address(this));
    return (profitFactor.mul(callCost) < credit.add(profit));
  }

  /** 
   * @notice
   * Harvest the strategy.
   * This function can be called only by governance, the strategist or the keeper
   * harvest function is called in order to take in profits, to borrow newly available funds from the vault, or adjust the position
   */

  function harvest() external onlyKeepers {
    _harvest();
  }

  function _harvest() internal {
    uint256 _profit = 0;
    uint256 _loss = 0;
    uint256 _debtOutstanding = vault.debtOutstanding(address(this));
    uint256 _debtPayment = 0;

    if (emergencyExit) {
      uint256 totalAssets = estimatedTotalAssets();     // accurated estimate for the total amount of assets that the strategy is managing in terms of want token.
      (_debtPayment, _loss) = liquidatePosition(totalAssets > _debtOutstanding ? totalAssets : _debtOutstanding);
      if (_debtPayment > _debtOutstanding) {
        _profit = _debtPayment.sub(_debtOutstanding);
        _debtPayment = _debtOutstanding;
      }
    } else {
      (_profit, _loss, _debtPayment) = prepareReturn(_debtOutstanding);
    }

    // returns available free tokens of this strategy
    // this debtOutstanding becomes prevDebtOutstanding - debtPayment
    _debtOutstanding = vault.report(_profit, _loss, _debtPayment);

    distributeRewards();
    adjustPosition(_debtOutstanding);

    emit Harvested(_profit, _loss, _debtPayment, _debtOutstanding);
  }

  // withdraw assets to the vault
  function withdraw(uint256 _amountNeeded) external returns (uint256 amountFreed, uint256 _loss) {
    require(msg.sender == address(vault), "!vault");
    (amountFreed, _loss) = liquidatePosition(_amountNeeded);
    want.safeTransfer(msg.sender, amountFreed);
  }

  /**
   * Do anything necessary to prepare this Strategy for migration, such as
   * transferring any reserve or LP tokens, CDPs, or other tokens or stores of
   * value.
   */
  function prepareMigration(address _newStrategy) internal virtual;

  
  /**
   * Transfer all assets from current strategy to new strategy
   */
  function migrate(address _newStrategy) external {
    require(msg.sender == address(vault) || msg.sender == governance());
    require(BaseStrategy(_newStrategy).vault() == vault);
    prepareMigration(_newStrategy);
    want.safeTransfer(_newStrategy, want.balanceOf(address(this)));
  }

  /**
   * @notice
   * Activates emergency exit. The strategy will be rovoked and withdraw all funds to the vault on the next harvest.
   * This may only be called by governance or the strategist.
   */

  function setEmergencyExit() external onlyAuthorized {
    emergencyExit = true;
    liquidatePosition(uint(-1));
    want.safeTransfer(address(vault), want.balanceOf(address(this)));
    vault.revokeStrategy(address(this));

    emit EmergencyExitEnabled();
  }

  function setProtectedTokens() internal virtual;

  // Removes tokens from this strategy that are not the type of tokens managed by this strategy
  function sweep(address _token) external onlyGovernance {
    require(_token != address(want), "!want");
    require(_token != address(vault), "!shares");
    require(!protected[_token], "!protected");

    IERC20(_token).safeTransfer(governance(), IERC20(_token).balanceOf(address(this)));
  }

  function setProfitFactor(uint256 _profitFactor) external onlyAuthorized {
    profitFactor = _profitFactor;
    emit UpdatedProfitFactor(_profitFactor);
  }

  function setDebtThreshold(uint256 _debtThreshold) external onlyAuthorized {
    debtThreshold = _debtThreshold;
    emit UpdatedDebtThreshold(_debtThreshold);
  }

  function setMaxReportDelay(uint256 _delay) external onlyAuthorized {
    maxReportDelay = _delay;
    emit UpdatedReportDelay(_delay);
  }
}
// File: strategies/strategyUgoHawkVenusUSDCFarm.sol


pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;









contract Strategy is BaseStrategy, IFlashLoanReceiver {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  UnitrollerI public constant venus = UnitrollerI(0xfD36E2c2a6789Db23113685031d7F16329158384);
  
  address public constant xvs = address(0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63);
  address public constant wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

  address public constant uniswapRouter = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
  address public constant crWant = address(0xD83C88DB3A6cA4a32FFf1603b0f7DDce01F5f727);

  uint256 public collateralTarget = 0.73 ether; // 73%
  uint256 public minWant = 1 ether;

  bool public flashLoanActive = true;

  bool public forceMigrate = false;

  VBep20I public vToken;
  uint256 immutable secondsPerBlock;     // approx seconds per block
  uint256 public immutable blocksToLiquidationDangerZone; // 7 days =  60*60*24*7/secondsPerBlock
  uint256 public minXvsToSell = 100000000;

  // @notice emitted when trying to do Flash Loan. flashLoan address is 0x00 when no flash loan used
  event Leverage(uint256 amountRequested, uint256 amountGiven, bool deficit, address flashLoan);

  modifier management(){
    require(msg.sender == governance() || msg.sender == strategist, "!management");
    _;
  }

  constructor(address _vault, address _vToken, uint8 _secondsPerBlock) public BaseStrategy(_vault) {
    vToken = VBep20I(_vToken);
    IERC20(VaultAPI(_vault).token()).safeApprove(address(vToken), uint256(-1));
    IERC20(xvs).safeApprove(uniswapRouter, uint256(-1));
    
    secondsPerBlock = _secondsPerBlock;
    blocksToLiquidationDangerZone = 60 * 60 * 24 * 7 / _secondsPerBlock;
    maxReportDelay = 3600 * 24;
    profitFactor = 100;
  }

  function name() external override view returns (string memory) {
    return "StrategyUgoHawkVenusUSDCFarm";
  }

  function delegatedAssets() external override pure returns (uint256) {
    return 0;
  }

  function setFlashLoan(bool active) external management {
    flashLoanActive = active;
  }

  function setForceMigrate(bool _force) external onlyGovernance {
    forceMigrate = _force;
  }

  function setMinXvsToSell(uint256 _minXvsToSell) external management {
    minXvsToSell = _minXvsToSell;
  }

  function setMinWant(uint256 _minWant) external management {
    minWant = _minWant;
  }

  function setCollateralTarget(uint256 _collateralTarget) external management {
    (, uint256 collateralFactorMantissa, ) = venus.markets(address(vToken));
    require(collateralFactorMantissa > _collateralTarget, "!danagerous collateral");
    collateralTarget = _collateralTarget;
  }

  /**
   * Provide an accurate estimate for the total number of assets (principle + return) that this strategy 
   * is currently managing.
   */
  function estimatedTotalAssets() public override view returns (uint256) {
    (uint256 deposits, uint256 borrows) = getCurrentPosition();
    uint256 _claimableXVS = predictXvsAccrued();
    uint256 currentXvs = IERC20(xvs).balanceOf(address(this));

    uint256 estimatedWant = priceCheck(xvs, address(want), _claimableXVS.add(currentXvs));
    uint256 conservativeWant = estimatedWant.mul(9).div(10);      // remainig 10% will be used for compensate offset

    return want.balanceOf(address(this)).add(deposits).add(conservativeWant).sub(borrows);
  }

  /**
   * View how much the vault expect this strategy to return at the current block, based on its present performance (since its last report)
   */
  function expectedReturn() public view returns (uint256) {
    uint256 estimatedAssets = estimatedTotalAssets();

    uint256 debt = vault.strategies(address(this)).totalDebt;
    if (debt > estimatedAssets) {
      return 0;
    } else {
      return estimatedAssets - debt;
    }
  }

  /**
   * Provide a signal to the keeper that 'tend()' should be called.
   */
  function tendTrigger(uint256 gasCost) public override view returns (bool) {
    if (harvestTrigger(gasCost)) {
      return false;
    }

    if (getblocksUntilLiquidation() <= blocksToLiquidationDangerZone) {
      return true;
    }
  }

  /**
   * Calcuate how many blocks until we are in liquidation based on current interest rates
   */
  function getblocksUntilLiquidation() public view returns (uint256) {
    (, uint256 collateralFactorMantissa, ) = venus.markets(address(vToken));
    
    (uint256 deposits, uint256 borrows) = getCurrentPosition();
    
    uint256 borrowRate = vToken.borrowRatePerBlock();
    uint256 supplyRate = vToken.supplyRatePerBlock();

    uint256 collateralisedDeposit1 = deposits.mul(collateralFactorMantissa).div(1e18);
    uint256 collateralisedDeposit = collateralisedDeposit1;

    uint256 denom1 = borrows.mul(borrowRate);
    uint256 denom2 = collateralisedDeposit.mul(supplyRate);

    if (denom2 >= denom1) {
      return uint256(-1);
    } else {
      uint256 numer = collateralisedDeposit.sub(borrows);
      uint256 denom = denom1 - denom2;
      return numer.mul(1e18).div(denom);
    }
  }

  // Return the current position
  function getCurrentPosition() public view returns (uint256 deposits, uint256 borrows) {
    (, uint256 vTokenBalance, uint256 borrowBalance, uint256 exchangeRate) = vToken.getAccountSnapshot(address(this));
    borrows = borrowBalance;

    deposits = vTokenBalance.mul(exchangeRate).div(1e18);
  }

  function netBalanceLent() public view returns (uint256) {
    (uint256 deposits, uint256 borrows) = getCurrentPosition();
    return deposits.sub(borrows);
  }

  /**
   * @notice
   *  Provide a signal to the keeper that harvest should be called.
   *  The keeper will provide the estimated gas cost that they would pay to call
   *  harvest() function.
   */
  function harvestTrigger(uint256 gasCost) public override view returns (bool) {
    StrategyParams memory params = vault.strategies(address(this));

    if (params.activation == 0) return false;

    uint256 wantGasCost = priceCheck(wbnb, address(want), gasCost);
    uint256 venusGasCost = priceCheck(wbnb, xvs, gasCost);

    uint256 _claimableXVS = predictXvsAccrued();

    if (_claimableXVS > minXvsToSell) {
      if (_claimableXVS.add(IERC20(xvs).balanceOf(address(this))) > venusGasCost.mul(profitFactor)) {
        return true;
      }
    }

    // trigger if hadn't been called in a while
    if (block.timestamp.sub(params.lastReport) >= maxReportDelay) return true;

    uint256 outstanding = vault.debtOutstanding(address(this));
    if (outstanding > profitFactor.mul(wantGasCost)) return true;

    uint256 total = estimatedTotalAssets();

    uint256 profit = 0;
    if (total > params.totalDebt) profit = total.sub(params.totalDebt);

    uint256 credit = vault.creditAvailable(address(this)).add(profit);
    return (profitFactor.mul(wantGasCost) < credit);
  }

  /**
   * @notice
   *  This function makes a prediction on how much xvs is accrued
   *  It is not 100% accurate as it uses current balances in Venus to predict into the past
   * @return XVS token amount available to claim
   */
  function predictXvsAccrued() public view returns (uint256) {
    (uint256 deposits, uint256 borrows) = getCurrentPosition();
    if (deposits == 0) {
      return 0;
    }

    uint256 distributionPerBlock = venus.venusSpeeds(address(vToken));
    uint256 totalBorrow = vToken.totalBorrows();
    uint256 totalSupplyVToken = vToken.totalSupply();
    uint256 totalSupply = totalSupplyVToken.mul(vToken.exchangeRateStored()).div(1e18);

    uint256 blockShareSupply = 0;
    if (totalSupply > 0) {
      blockShareSupply = deposits.mul(distributionPerBlock).div(totalSupply);
    }
    uint256 blockShareBorrow = 0;
    if (totalBorrow > 0) {
      blockShareBorrow = borrows.mul(distributionPerBlock).div(totalBorrow);
    }

    uint256 blockShare = blockShareSupply.add(blockShareBorrow);

    uint256 lastReport = vault.strategies(address(this)).lastReport;
    uint256 blocksSinceLast = (block.timestamp.sub(lastReport)).div(secondsPerBlock);

    return blocksSinceLast.mul(blockShare);
  }

  /**
   * Do anything necessary to prepare this Strategy for migration, such as transferring any reserve.
   */
  function prepareMigration(address _newStrategy) internal override {
    if (!forceMigrate) {
      (uint256 deposits, uint256 borrows) = getLivePosition();
      _withdrawSome(deposits.sub(borrows));

      (, , uint256 borrowBalance, ) = vToken.getAccountSnapshot(address(this));

      require(borrowBalance < 10_000, "DELEVERAGE_FIRST");

      IERC20 _xvs = IERC20(xvs);
      uint _xvsBalance = _xvs.balanceOf(address(this));
      if (_xvsBalance > 0) {
        _xvs.safeTransfer(_newStrategy, _xvsBalance);
      }
    }
  }

  function distributeRewards() internal override {}

  function priceCheck(address start, address end, uint256 _amount) public view returns (uint256) {
    if (_amount == 0) {
      return 0;
    }

    address[] memory path;
    if (start == wbnb) {
      path = new address[](2);
      path[0] = wbnb;
      path[1] = end;
    } else {
      path = new address[](3);
      path[0] = start;
      path[1] = wbnb;
      path[2] = end;
    }

    uint256[] memory amounts = IUniswapV2Router02(uniswapRouter).getAmountsOut(_amount, path);
    
    return amounts[amounts.length - 1];
  }

  // debtPayment is token amount to return to vault
  // debtOutstanding is token amount that the vault ask to return
  function prepareReturn(uint256 _debtOutstanding) internal override returns (
    uint256 _profit,
    uint256 _loss,
    uint256 _debtPayment
  ) {
    _profit = 0;
    _loss = 0;

    if (vToken.balanceOf(address(this)) == 0) {
      uint256 wantBalance = want.balanceOf(address(this));
      _debtPayment = _min(wantBalance, _debtOutstanding);
      return (_profit, _loss, _debtPayment);
    }

    (uint256 deposits, uint256 borrows) = getLivePosition();

    _claimXvs();          // claim xvs tokens
    _disposeOfXvs();      // sell xvs tokens

    uint256 wantBalance = want.balanceOf(address(this));

    uint256 investedBalance = deposits.sub(borrows);
    uint256 balance = investedBalance.add(wantBalance);

    uint256 debt = vault.strategies(address(this)).totalDebt; 

    // `balance` - `total debt` is profit
    if (balance > debt) {
      _profit = balance - debt;
      if (wantBalance < _profit) {
        // all reserve is profit in case `profit` is greater than `wantBalance`
        _profit = wantBalance;
      } else if (wantBalance > _profit.add(_debtOutstanding)) {
        _debtPayment = _debtOutstanding;
      } else {
        _debtPayment = wantBalance - _profit;
      }
    } else {
      _loss = debt - balance;
      _debtPayment = _min(wantBalance, _debtOutstanding);
    }
  }

  // adjustPosition is called after report call
  // adjust the position using free available tokens
  /**
   * @notice
   *  adjustPosition is called after report call
   *  adjust the position using free available tokens
   * @param _debtOutstanding the amount to withdraw from strategy to vault
   */
  function adjustPosition(uint256 _debtOutstanding) internal override {
    if (emergencyExit) {
      return;
    }

    uint256 _wantBal = want.balanceOf(address(this));
    if (_wantBal < _debtOutstanding) {
      if (vToken.balanceOf(address(this)) > 1) {
        _withdrawSome(_debtOutstanding - _wantBal);
      }

      return;
    }

    (uint256 position, bool deficit) = _calculateDesiredPosition(_wantBal - _debtOutstanding, true);

    if (position > minWant) {
      if (!flashLoanActive) {
        uint i = 0;
        while(position > 0) {
          position = position.sub(_noFlashLoan(position, deficit));
          if (i >= 6) {
            break;
          }
          i++;
        }
      } else {
        if (position > want.balanceOf(crWant)) {
          position = position.sub(_noFlashLoan(position, deficit));
        }

        if (position > minWant) {
          doFlashLoan(deficit, position);
        }
      }
    }
  }

  /**
   * @notice
   *  withdraw tokens from venus to adjust position
   * @param _amount we wanna withdraw and whether 
   */
  function _withdrawSome(uint256 _amount) internal returns (bool notAll) {
    (uint256 position, bool deficit) = _calculateDesiredPosition(_amount, false);

    if (deficit && position > minWant) {
      position = position.sub(doFlashLoan(deficit, position));
      
      uint8 i = 0;
      while (position > minWant.add(100)) {
        position = position.sub(_noFlashLoan(position, true));
        i++;

        if (i >= 5) {
          notAll = true;
          break;
        }
      }
    }

    (uint256 depositBalance, uint256 borrowBalance) = getCurrentPosition();
    uint256 tempColla = collateralTarget;

    uint256 reservedAmount = 0;
    if (tempColla == 0) {
      tempColla = 1e15;   // 0.001 * 1e18. minimum collateralTarget
    }

    reservedAmount = borrowBalance.mul(1e18).div(tempColla);

    if (depositBalance >= reservedAmount) {
      uint256 redeemable = depositBalance.sub(reservedAmount);

      if (redeemable < _amount) {
        vToken.redeemUnderlying(redeemable);
      } else {
        vToken.redeemUnderlying(_amount);
      }
    }

    if (collateralTarget == 0 && want.balanceOf(address(this)) > borrowBalance) {
      vToken.repayBorrow(borrowBalance);
    }

    _disposeOfXvs();
  }

  /**
   * @notice
   *  This function calculate the borrow position(the amount to add or remove) based on lending balance.
   * @param balance. the amount we're going to deposit or withdraw to venus platform
   * @param dep. flag(True/False) to deposit or withdraw
   * @return position the amount we want to change current borrow position
   * @return deficit flag(True/False). if reducing the borrow size, true
   */
  
  function _calculateDesiredPosition(uint256 balance, bool dep) internal returns(uint256 position, bool deficit) {
    (uint256 deposits, uint256 borrows) = getLivePosition();
    uint256 unwoundDeposit = deposits.sub(borrows);   // available token amount on lending platform. i.e. lended amount - borrowed amount

    uint256 desiredSupply = 0;
    if (dep) {
      desiredSupply = unwoundDeposit.add(balance);
    } else {
      if (balance > unwoundDeposit) balance = unwoundDeposit;
      desiredSupply = unwoundDeposit.sub(balance);
    }

    // db = (ds * c) / (1 - c)
    uint256 num = desiredSupply.mul(collateralTarget);
    uint256 den = uint256(1e18).sub(collateralTarget);

    uint256 desiredBorrow = num.div(den);
    if (desiredBorrow > 1e5) {
      //stop us going right up to the wire
      desiredBorrow = desiredBorrow - 1e5;
    }
    
    if (desiredBorrow < borrows) {
      deficit = true;
      position = borrows - desiredBorrow;
    } else {
      deficit = false;
      position = desiredBorrow - borrows;
    }
  }

  /**
   * do flash loan with desired amount
   */
  function doFlashLoan(bool deficit, uint256 amountDesired) internal returns (uint256) {
    if (amountDesired == 0) {
      return 0;
    }

    uint256 amount = amountDesired;
    bytes memory data = abi.encode(deficit, amount);

    ICTokenFlashloan(crWant).flashLoan(address(this), amount, data);
    emit Leverage(amountDesired, amount, deficit, crWant);

    return amount;
    
  }

  /**
   * @notice
   *  Three functions covering normal leverage and deleverage situations
   * @param max the max amount we want to increase our borrowed balance
   * @param deficit True if we are reducing the position size
   * @return amount actually did
   */
  function _noFlashLoan(uint256 max, bool deficit) internal returns (uint256 amount) {
    (uint256 lent, uint256 borrowed) = getCurrentPosition();
    // if we have nothing borrowed, can't deleverage any more(can't reduce borrow size)
    if (borrowed == 0 && deficit) {
      return 0;
    }
    (, uint256 collateralFactorMantissa, ) = venus.markets(address(vToken));

    if (deficit) {
      amount = _normalDeleverage(max, lent, borrowed, collateralFactorMantissa);
    } else {
      amount = _normalLeverage(max, lent, borrowed, collateralFactorMantissa);
    }

    emit Leverage(max, amount, deficit, address(0));
  }

  /**
   * @param maxDeleverage how much we want to reduce by
   * @param lent the amount we lent to the venus
   * @param borrowed the amount we borrowed from the venus
   * @param collatRatio collateral ratio of token in venus
   */
  function _normalDeleverage(
    uint256 maxDeleverage,
    uint256 lent,
    uint256 borrowed,
    uint256 collatRatio
  ) internal returns (uint256 deleveragedAmount) {
    uint256 theoreticalLent = 0;
    if (collatRatio != 0) {
      theoreticalLent = borrowed.mul(1e18).div(collatRatio);
    }
    deleveragedAmount = lent.sub(theoreticalLent);

    if (deleveragedAmount >= borrowed) {
      deleveragedAmount = borrowed;
    }
    if (deleveragedAmount >= maxDeleverage) {
      deleveragedAmount = maxDeleverage;
    }

    uint256 exchangeRateStored = vToken.exchangeRateStored();

    if (deleveragedAmount.mul(1e18) >= exchangeRateStored && deleveragedAmount > 10) {
      deleveragedAmount = deleveragedAmount - 10;
      vToken.redeemUnderlying(deleveragedAmount);

      vToken.repayBorrow(deleveragedAmount);
    }
  }

  /**
   * @param maxLeverage how much we want to increase by
   * @param lent the amount we lent to the venus
   * @param borrowed the amount we borrowed from the venus
   * @param collatRatio collateral ratio of token in venus
   */
  function _normalLeverage(
    uint256 maxLeverage,
    uint256 lent,
    uint256 borrowed,
    uint256 collatRatio
  ) internal returns (uint256 leveragedAmount) {
    uint256 theoreticalBorrow = lent.mul(collatRatio).div(1e18);
    leveragedAmount = theoreticalBorrow.sub(borrowed);

    if (leveragedAmount >= maxLeverage) {
      leveragedAmount = maxLeverage;
    }
    if (leveragedAmount > 10) {
      leveragedAmount = leveragedAmount - 10;
      require(vToken.borrow(leveragedAmount) == 0, "got collateral?");
      require(vToken.mint(want.balanceOf(address(this))) == 0, "supply error");
    }
  }

  //Cream calls this function after doing flash loan
  /**
   * @notice
   *  called by cream flash loan contract
   * @param sender the address of flash loan caller
   * @param underlying the address of token we borrowed
   * @param amount the amount borrowed
   * @param fee flash loan fee
   * @param params param data sent when loaning
   */
  function executeOperation(address sender, address underlying, uint amount, uint fee, bytes calldata params) override external {
    // uint currentBalance = IERC20(underlying).balanceOf(address(this));
    require(sender == address(this), "caller is not this contract");
    require(msg.sender == crWant, "Not Flash Loan Provider");
    (bool deficit, ) = abi.decode(params, (bool, uint256));

    _loanLogic(deficit, amount, amount + fee);
    IERC20(underlying).safeTransfer(crWant, amount + fee);
    
  }

  /**
   * @notice
   *  logic after getting flash-loaned assets, called by executeOperation
   * @param deficit true if redeem, false if borrow
   * @param amount the amount to borrow
   * @param repayAmount the amount to repay
   */
  function _loanLogic(bool deficit, uint256 amount, uint256 repayAmount) internal returns (uint) {
    uint256 bal = want.balanceOf(address(this));
    require(bal >= amount, "Invalid balance, was the flashloan successful?");

    if (deficit) {
      vToken.repayBorrow(amount);
      vToken.redeemUnderlying(repayAmount);
    } else {
      require(vToken.mint(bal) == 0, "mint error");

      address[] memory vTokens = new address[](1);
      vTokens[0] = address(vToken);
      
      uint256[] memory errors = venus.enterMarkets(vTokens);
      if (errors[0] != 0) {
        revert("Comptroller.enterMarkets failed.");
      }
      
      (uint256 error, uint256 liquidity, uint256 shortfall) = venus.getAccountLiquidity(address(this));
      if (error != 0) {
        revert("Comptroller.getAccountLiquidity failed.");
      }
      require(shortfall == 0, "account underwater");
      require(liquidity > 0, "account has excess collateral");
      require(vToken.borrow(repayAmount) == 0, "borrow error");
    }
  }

  /**
   * @notice
   *  get the current position of strategy
   * @return deposits the amount lent
   * @return borrows the amount borrowed
   */
  function getLivePosition() public returns (uint256 deposits, uint256 borrows) {
    deposits = vToken.balanceOfUnderlying(address(this));
    borrows = vToken.borrowBalanceStored(address(this));
  }

  // claims XVS reward token
  function _claimXvs() internal {
    VTokenI[] memory tokens = new VTokenI[](1);
    tokens[0] = vToken;
    venus.claimVenus(address(this), tokens);
  }

  // sell harvested XVS tokens
  function _disposeOfXvs() internal {
    uint256 _xvs = IERC20(xvs).balanceOf(address(this));

    if (_xvs > minXvsToSell) {
      address[] memory path = new address[](3);
      path[0] = xvs;
      path[1] = wbnb;
      path[2] = address(want);

      IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(_xvs, uint256(0), path, address(this), now);
    }
  }

  /**
   * @notice
   *  Liquidate up to _amountNeeded of asset of this strategy's position
   *  irregardless of slippage.
   * @param _amountNeeded the amount to liquidate
   * @return _amountFreed the amount freed
   * @return _loss the amount lost
   */
  function liquidatePosition(uint256 _amountNeeded) internal override returns (uint256 _amountFreed, uint256 _loss) {
    uint256 _balance = want.balanceOf(address(this));
    uint256 assets = netBalanceLent().add(_balance);

    uint256 debtOutstanding = vault.debtOutstanding(address(this));

    if (debtOutstanding > assets) {
      _loss = debtOutstanding - assets;
    }

    if (assets < _amountNeeded) {
      (uint256 deposits, uint256 borrows) = getLivePosition();
      if (vToken.balanceOf(address(this)) > 1) {
        _withdrawSome(deposits.sub(borrows));
      }

      _amountFreed = _min(_amountNeeded, want.balanceOf(address(this)));
    } else {
      if (_balance < _amountNeeded) {
        _withdrawSome(_amountNeeded.sub(_balance));
        _amountFreed = _min(_amountNeeded, want.balanceOf(address(this)));
      } else {
        _amountFreed = _amountNeeded;
      }
    }
  }

  function setProtectedTokens() internal override {
    protected[xvs] = true;
  }

  function _min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

}