/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

// SPDX-License-Identifier:  AGPL-3.0-or-later // hevm: flattened sources of contracts/PoolFactory.sol
pragma solidity =0.6.11 >=0.6.7 >=0.6.0 <0.8.0 >=0.6.2 <0.8.0;

////// contracts/interfaces/IBPool.sol
/* pragma solidity 0.6.11; */

interface IBPool {

    function transfer(address, uint256) external returns (bool);

    function INIT_POOL_SUPPLY() external view returns (uint256);

    function MAX_OUT_RATIO() external view returns (uint256);

    function bind(address, uint256, uint256) external;

    function balanceOf(address) external view returns (uint256);

    function finalize() external;

    function gulp(address) external;

    function isFinalized() external view returns (bool);

    function isBound(address) external view returns (bool);

    function getNumTokens() external view returns (uint256);

    function getBalance(address) external view returns (uint256);

    function getNormalizedWeight(address) external view returns (uint256);

    function getDenormalizedWeight(address) external view returns (uint256);

    function getTotalDenormalizedWeight() external view returns (uint256);

    function getSwapFee() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getFinalTokens() external view returns (address[] memory);

    function calcSingleOutGivenPoolIn(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountIn,
        uint256 swapFee
    ) external pure returns (uint256);

    function calcPoolInGivenSingleOut(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external pure returns (uint256);

    function exitswapExternAmountOut(
        address tokenOut,
        uint tokenAmountOut,
        uint maxPoolAmountIn
    ) external returns (uint poolAmountIn);

}

////// contracts/interfaces/IDebtLocker.sol
/* pragma solidity 0.6.11; */

interface IDebtLocker {
    function pool() external returns (address);

    function liquidityAsset() external returns (address);

    function claim() external returns(uint256[7] memory);
    
    function triggerDefault() external;
}

////// contracts/interfaces/IGlobals.sol
/* pragma solidity 0.6.11; */

interface IGlobals {
    function governor() external view returns (address);

    function admin() external view returns (address);

    function mpl() external view returns (address);

    function mapleTreasury() external view returns (address);

    function isExemptFromTransferRestriction(address) external view returns (bool);

    function isValidBalancerPool(address) external view returns (bool);

    function treasuryFee() external view returns (uint256);

    function investorFee() external view returns (uint256);

    function defaultGracePeriod() external view returns (uint256);

    function fundingPeriod() external view returns (uint256);

    function swapOutRequired() external view returns (uint256);

    function isValidLiquidityAsset(address) external view returns (bool);

    function isValidCollateralAsset(address) external view returns (bool);

    function isValidPoolDelegate(address) external view returns (bool);

    function validLiquidityAssets() external view returns (address[] memory);

    function validCollateralAssets() external view returns (address[] memory);

    function loanFactory() external view returns (address);

    function poolFactory() external view returns (address);

    function getPrice(address) external view returns (uint256);

    function isValidCalc(address, uint8) external view returns (bool);

    function isValidLoanFactory(address) external view returns (bool);

    function isValidSubFactory(address, address, uint8) external view returns (bool);

    function isValidPoolFactory(address) external view returns (bool);
    
    function getLatestPrice(address) external view returns (uint256);
    
    function defaultUniswapPath(address, address) external view returns (address);

    function minLoanEquity() external view returns (uint256);
    
    function maxSwapSlippage() external view returns (uint256);

    function protocolPaused() external view returns (bool);

    function stakerCooldownPeriod() external view returns(uint256);

    function lpCooldownPeriod() external view returns(uint256);

    function stakerUnstakeWindow() external view returns(uint256);

    function lpWithdrawWindow() external view returns(uint256);
}

////// contracts/interfaces/ILiquidityLocker.sol
/* pragma solidity >=0.6.7; */

interface ILiquidityLocker {
    function fundLoan(address, address, uint256) external;

    function transfer(address, uint256) external;

    function pool() external view returns(address);
}

////// contracts/interfaces/ILiquidityLockerFactory.sol
/* pragma solidity 0.6.11; */

interface ILiquidityLockerFactory {
    function newLocker(address) external returns (address);

    function owner(address) external returns (address);
    
    function isLocker(address) external returns (bool);
}

////// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

/* pragma solidity >=0.6.0 <0.8.0; */

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

////// contracts/interfaces/ILoan.sol
/* pragma solidity 0.6.11; */

/* import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol"; */

interface ILoan is IERC20 {
    
    // State Variables
    function fundsTokenBalance() external view returns (uint256);
    
    function liquidityAsset() external view returns (address);
    
    function collateralAsset() external view returns (address);
    
    function fundingLocker() external view returns (address);
    
    function flFactory() external view returns (address);
    
    function collateralLocker() external view returns (address);
    
    function clFactory() external view returns (address);
    
    function borrower() external view returns (address);
    
    function repaymentCalc() external view returns (address);
    
    function lateFeeCalc() external view returns (address);
    
    function premiumCalc() external view returns (address);
    
    function loanState() external view returns (uint256);
    
    function globals() external view returns (address);
    
    function collateralRequiredForDrawdown(uint256) external view returns(uint256);
    

    // Loan Specifications
    function apr() external view returns (uint256);
    
    function paymentsRemaining() external view returns (uint256);
    
    function paymentIntervalSeconds() external view returns (uint256);
    
    function requestAmount() external view returns (uint256);
    
    function collateralRatio() external view returns (uint256);
    
    function fundingPeriod() external view returns (uint256);

    function defaultGracePeriod() external view returns (uint256);
    
    function createdAt() external view returns (uint256);
    
    function principalOwed() external view returns (uint256);
    
    function principalPaid() external view returns (uint256);
    
    function interestPaid() external view returns (uint256);
    
    function feePaid() external view returns (uint256);
    
    function excessReturned() external view returns (uint256);
    
    function getNextPayment() external view returns (uint256, uint256, uint256, uint256);
    
    function superFactory() external view returns (address);
    
    function termDays() external view returns (uint256);
    
    function nextPaymentDue() external view returns (uint256);
    

    // Liquidations
    function defaultSuffered() external view returns (uint256);
    
    function amountRecovered() external view returns (uint256);
    
    function getExpectedAmountRecovered() external view returns(uint256);
    

    // Functions
    function fundLoan(address, uint256) external;
    
    function makePayment() external;
    
    function drawdown(uint256) external;
    
    function makeFullPayment() external;
    
    function triggerDefault() external;
    
    function unwind() external;
    

    // FDT
    function updateFundsReceived() external;
    
    function withdrawFunds() external;

    function withdrawableFundsOf(address) external view returns(uint256);

    // Security 
    function pause() external;

    function unpause() external;
}

////// contracts/interfaces/ILoanFactory.sol
/* pragma solidity 0.6.11; */

interface ILoanFactory {
    function isLoan(address) external view returns (bool);

    function loans(uint256)  external view returns (address);

    function globals() external view returns (address);
    
    function createLoan(address, address, address, address, uint256[5] memory, address[3] memory) external returns (address);
}

////// contracts/interfaces/IPoolFactory.sol
/* pragma solidity 0.6.11; */

interface IPoolFactory {
    function isPool(address) external view returns (bool);

    function createPool(address, address, address, address,uint256, uint256, uint256) external returns (address);

    function pools(uint256) external view returns (address);

    function globals() external view returns (address);
}

////// contracts/interfaces/IStakeLocker.sol
/* pragma solidity 0.6.11; */

/* import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol"; */

interface IStakeLocker is IERC20 {

    function stakeDate(address) external returns (uint256);

    function stake(uint256) external;

    function unstake(uint256) external;

    function withdrawUnstaked(uint256) external returns (uint256);

    function withdrawInterest() external returns (uint256);

    function updateFundsReceived() external;

    function withdrawableFundsOf(address) external view returns(uint256);

    function pull(address, uint256) external;

    function setAllowlist(address, bool) external;

    function openStakeLockerToPublic() external;

    function openToPublic() external view returns (bool);

    function allowed(address) external view returns (bool);

    function updateLosses(uint256) external;

    function bptLosses() external view returns(uint256);

    function recognizableLossesOf(address) external view returns(uint256);

    function intendToUnstake() external;

    function unstakeCooldown(address) external view returns(uint256);

    function lockupPeriod() external view returns(uint256);

}

////// contracts/interfaces/IStakeLockerFactory.sol
/* pragma solidity 0.6.11; */

interface IStakeLockerFactory {
    function newLocker(address, address) external returns (address);

    function owner(address) external returns (address);

    function isLocker(address) external returns (bool);
}

////// contracts/interfaces/IDebtLockerFactory.sol
/* pragma solidity 0.6.11; */

interface IDebtLockerFactory {
    function newLocker(address) external returns (address);

    function owner(address) external returns (address);

    function isLocker(address) external returns (bool);
}

////// contracts/interfaces/IERC20Details.sol
/* pragma solidity 0.6.11; */

/* import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol"; */

interface IERC20Details is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);
}

////// lib/openzeppelin-contracts/contracts/math/SafeMath.sol

/* pragma solidity >=0.6.0 <0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/utils/Address.sol

/* pragma solidity >=0.6.2 <0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC20/SafeERC20.sol

/* pragma solidity >=0.6.0 <0.8.0; */

/* import "./IERC20.sol"; */
/* import "../../math/SafeMath.sol"; */
/* import "../../utils/Address.sol"; */

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

////// contracts/library/PoolLib.sol
/* pragma solidity 0.6.11; */

/* import "lib/openzeppelin-contracts/contracts/math/SafeMath.sol"; */
/* import "lib/openzeppelin-contracts/contracts/token/ERC20/SafeERC20.sol"; */
/* import "../interfaces/ILoan.sol"; */
/* import "../interfaces/IBPool.sol"; */
/* import "../interfaces/IGlobals.sol"; */
/* import "../interfaces/ILiquidityLocker.sol"; */
/* import "../interfaces/IERC20Details.sol"; */
/* import "../interfaces/ILoanFactory.sol"; */
/* import "../interfaces/IStakeLocker.sol"; */
/* import "../interfaces/IDebtLockerFactory.sol"; */

/// @title PoolLib is a library of utility functions used by Pool.
library PoolLib {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant MAX_UINT256 = uint256(-1);
    uint256 public constant WAD         = 10 ** 18;
    uint8   public constant DL_FACTORY  = 1;         // Factory type of `DebtLockerFactory`

    event         LoanFunded(address indexed loan, address debtLocker, uint256 amountFunded);
    event DepositDateUpdated(address indexed lp, uint256 depositDate);
    event           Cooldown(address indexed lp, uint256 cooldown);

    /***************************************/
    /*** Pool Delegate Utility Functions ***/
    /***************************************/

    /** 
        @dev Conducts sanity checks for Pools in the constructor
        @param globals        Address of MapleGlobals
        @param liquidityAsset Asset used by Pool for liquidity to fund loans
        @param stakeAsset     Asset escrowed in StakeLocker
        @param stakingFee     Fee that `stakers` earn on interest, in basis points
        @param delegateFee    Fee that `_poolDelegate` earns on interest, in basis points
    */
    function poolSanityChecks(
        IGlobals globals, 
        address liquidityAsset, 
        address stakeAsset, 
        uint256 stakingFee, 
        uint256 delegateFee
    ) external {
        require(globals.isValidLiquidityAsset(liquidityAsset), "Pool:INVALID_LIQ_ASSET");
        require(stakingFee.add(delegateFee) <= 10_000,         "Pool:INVALID_FEES");
        require(
            globals.isValidBalancerPool(address(stakeAsset)) &&
            IBPool(stakeAsset).isBound(globals.mpl())        && 
            IBPool(stakeAsset).isBound(liquidityAsset)       &&
            IBPool(stakeAsset).isFinalized(), 
            "Pool:INVALID_BALANCER_POOL"
        );
    }

    /**
        @dev Fund a loan for amt, utilize the supplied debtLockerFactory for debt lockers.
        @param  debtLockers     Mapping contains the `debtLocker` contract address corresponds to the `dlFactory` and `loan`.
        @param  superFactory    Address of the `PoolFactory`
        @param  liquidityLocker Address of the `liquidityLocker` contract attached with this Pool
        @param  loan            Address of the loan to fund
        @param  dlFactory       The debt locker factory to utilize
        @param  amt             Amount to fund the loan
    */
    function fundLoan(
        mapping(address => mapping(address => address)) storage debtLockers,
        address superFactory,
        address liquidityLocker,
        address loan,
        address dlFactory,
        uint256 amt
    ) external {
        IGlobals globals    = _globals(superFactory);
        address loanFactory = ILoan(loan).superFactory();

        // Auth checks
        require(globals.isValidLoanFactory(loanFactory),                        "Pool:INVALID_LOAN_FACTORY");
        require(ILoanFactory(loanFactory).isLoan(loan),                         "Pool:INVALID_LOAN");
        require(globals.isValidSubFactory(superFactory, dlFactory, DL_FACTORY), "Pool:INVALID_DL_FACTORY");

        address _debtLocker = debtLockers[loan][dlFactory];

        // Instantiate locker if it doesn't exist with this factory type
        if (_debtLocker == address(0)) {
            address debtLocker = IDebtLockerFactory(dlFactory).newLocker(loan);
            debtLockers[loan][dlFactory] = debtLocker;
            _debtLocker = debtLocker;
        }
    
        // Fund loan
        ILiquidityLocker(liquidityLocker).fundLoan(loan, _debtLocker, amt);
        
        emit LoanFunded(loan, _debtLocker, amt);
    }

    /**
        @dev Helper function for claim() if a default has occurred.
        @param  liquidityAsset  IERC20 of liquidityAsset
        @param  stakeLocker     Address of stakeLocker
        @param  stakeAsset      Address of BPTs
        @param  loan            Address of loan
        @param  defaultSuffered Amount of shortfall in defaulted loan after liquidation
        @return bptsBurned                      Amount of BPTs burned to cover shortfall
        @return postBurnBptBal                  Amount of BPTs returned to stakeLocker after burn
        @return liquidityAssetRecoveredFromBurn Amount of liquidityAsset recovered from burn
     */
    function handleDefault(
        IERC20  liquidityAsset,
        address stakeLocker,
        address stakeAsset,
        address loan,
        uint256 defaultSuffered
    ) 
        external
        returns (
            uint256 bptsBurned,
            uint256 postBurnBptBal,
            uint256 liquidityAssetRecoveredFromBurn
        ) 
    {

        IBPool bPool = IBPool(stakeAsset);  // stakeAsset == Balancer Pool Tokens

        // Check amount of liquidityAsset coverage that exists in the StakeLocker
        uint256 availableSwapOut = getSwapOutValueLocker(stakeAsset, address(liquidityAsset), stakeLocker);

        // Pull BPTs from StakeLocker
        IStakeLocker(stakeLocker).pull(address(this), bPool.balanceOf(stakeLocker));

        // To maintain accounting, account for direct transfers into Pool
        uint256 preBurnLiquidityAssetBal = liquidityAsset.balanceOf(address(this));
        uint256 preBurnBptBal            = bPool.balanceOf(address(this));

        // Burn enough BPTs for liquidityAsset to cover defaultSuffered
        bPool.exitswapExternAmountOut(
            address(liquidityAsset), 
            availableSwapOut >= defaultSuffered ? defaultSuffered : availableSwapOut,  // Burn BPTs up to defaultSuffered amount
            preBurnBptBal
        );

        // Return remaining BPTs to stakeLocker
        postBurnBptBal = bPool.balanceOf(address(this));
        bptsBurned     = preBurnBptBal.sub(postBurnBptBal);
        bPool.transfer(stakeLocker, postBurnBptBal);
        liquidityAssetRecoveredFromBurn = liquidityAsset.balanceOf(address(this)).sub(preBurnLiquidityAssetBal);
        IStakeLocker(stakeLocker).updateLosses(bptsBurned);  // Update StakeLocker FDT loss accounting for BPTs
    }

    /**
        @dev Calculate portions of claim from DebtLocker to be used by Pool claim function.
        @param claimInfo   [0] = Total Claimed
                           [1] = Interest Claimed
                           [2] = Principal Claimed
                           [3] = Fee Claimed
                           [4] = Excess Returned Claimed
                           [5] = Amount Recovered (from Liquidation)
                           [6] = Default Suffered
        @param delegateFee Portion of interest (basis points) that goes to the Pool Delegate
        @param stakingFee  Portion of interest (basis points) that goes to the StakeLocker
        @return poolDelegatePortion Total funds to send to Pool Delegate
        @return stakeLockerPortion  Total funds to send to StakeLocker
        @return principalClaim      Total principal claim
        @return interestClaim       Total interest claim
    */
    function calculateClaimAndPortions(
        uint256[7] calldata claimInfo,
        uint256 delegateFee,
        uint256 stakingFee
    ) 
        external
        returns (
            uint256 poolDelegatePortion,
            uint256 stakeLockerPortion,
            uint256 principalClaim,
            uint256 interestClaim
        ) 
    { 
        poolDelegatePortion = claimInfo[1].mul(delegateFee).div(10_000).add(claimInfo[3]);  // PD portion of interest plus fee
        stakeLockerPortion  = claimInfo[1].mul(stakingFee).div(10_000);                     // SL portion of interest

        principalClaim = claimInfo[2].add(claimInfo[4]).add(claimInfo[5]);                                     // Principal + excess + amountRecovered
        interestClaim  = claimInfo[1].sub(claimInfo[1].mul(delegateFee).div(10_000)).sub(stakeLockerPortion);  // Leftover interest
    }

    /**
        @dev Check whether the deactivation is allowed or not.
        @param  globals        Globals contract interface
        @param  principalOut   Amount of funds that is already funded to loans.
        @param  liquidityAsset Liquidity Asset of the pool 
     */
    function validateDeactivation(IGlobals globals, uint256 principalOut, address liquidityAsset) public view {
        require(principalOut <= convertFromUsd(globals, liquidityAsset, 100), "Pool:PRINCIPAL_OUTSTANDING");
    }

    /********************************************/
    /*** Liquidity Provider Utility Functions ***/
    /********************************************/

    /**
        @dev Update the effective deposit date based on how much new capital has been added.
             If more capital is added, the depositDate moves closer to the current timestamp.
        @param  depositDate Weighted timestamp representing effective deposit date
        @param  balance     Balance of PoolFDT tokens of user
        @param  amt         Total deposit amount
        @param  who         Address of user depositing
    */
    function updateDepositDate(mapping(address => uint256) storage depositDate, uint256 balance, uint256 amt, address who) internal {
        uint256 prevDate = depositDate[who];
        uint256 newDate = block.timestamp;
        if (prevDate == uint256(0)) {
            depositDate[who] = newDate;
        } else {
            uint256 dTime    = block.timestamp.sub(prevDate);
            newDate          = prevDate.add(dTime.mul(amt).div(balance + amt));  // prevDate + (now - prevDate) * (amt / (balance + amt))
            depositDate[who] = newDate;
        }
        emit DepositDateUpdated(who, newDate);
    }

    /**
        @dev View function to indicate if msg.sender is within their withdraw window
    */
    function isWithdrawAllowed(uint256 withdrawCooldown, IGlobals globals) public view returns (bool) {
        return block.timestamp - (withdrawCooldown + globals.lpCooldownPeriod()) <= globals.lpWithdrawWindow();
    }

    /**
        @dev View function to indicate if recipient is allowed to receive a transfer.
        This is only possible if they have zero cooldown or they are passed their withdraw window.
    */
    function isReceiveAllowed(uint256 withdrawCooldown, IGlobals globals) public view returns (bool) {
        return block.timestamp > withdrawCooldown + globals.lpCooldownPeriod() + globals.lpWithdrawWindow();
    }

    /**
        @dev Performing some checks before doing actual transfers.
    */
    function prepareTransfer(
        mapping(address => uint256) storage withdrawCooldown,
        mapping(address => uint256) storage depositDate,
        address from,
        address to,
        uint256 wad,
        IGlobals globals,
        uint256 toBalance,
        uint256 recognizableLosses
    ) external {
        // If transferring in or out of yield farming contract, do not update depositDate or cooldown
        if (!globals.isExemptFromTransferRestriction(from) && !globals.isExemptFromTransferRestriction(to)) {
            require(isReceiveAllowed(withdrawCooldown[to], globals), "Pool:RECIPIENT_NOT_ALLOWED");  // Recipient must not be currently withdrawing
            require(recognizableLosses == uint256(0),                "Pool:RECOG_LOSSES");           // If an LP has unrecognized losses, they must recognize losses through withdraw
            updateDepositDate(depositDate, toBalance, wad, to);                                      // Update deposit date of recipient
        }
    }

    /**
        @dev Activates the cooldown period to withdraw. It can't be called if the user is not an LP.
     */
    function intendToWithdraw(mapping(address => uint256) storage withdrawCooldown, uint256 balance) external {
        require(balance != uint256(0), "Pool:ZERO_BALANCE");
        withdrawCooldown[msg.sender] = block.timestamp;
        emit Cooldown(msg.sender, block.timestamp);
    }

    /**
        @dev Cancel an initiated withdrawal.
     */
    function cancelWithdraw(mapping(address => uint256) storage withdrawCooldown) external {
        require(withdrawCooldown[msg.sender] != uint256(0), "Pool:NOT_WITHDRAWING");
        withdrawCooldown[msg.sender] = uint256(0);
        emit Cooldown(msg.sender, uint256(0));
    }

    /**********************************/
    /*** Governor Utility Functions ***/
    /**********************************/

    /**
        @dev Transfer any locked funds to the governor.
        @param token Address of the token that need to reclaimed.
        @param liquidityAsset Address of liquidity asset that is supported by the pool.
        @param globals Instance of the `MapleGlobals` contract.
     */
    function reclaimERC20(address token, address liquidityAsset, IGlobals globals) external {
        require(msg.sender == globals.governor(), "Pool:UNAUTHORIZED");
        require(token != liquidityAsset && token != address(0), "Pool:INVALID_TOKEN");
        IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    /************************/
    /*** Getter Functions ***/
    /************************/

    /// @dev Official balancer pool bdiv() function, does synthetic float with 10^-18 precision
    function bdiv(uint256 a, uint256 b) public pure returns (uint256) {
        require(b != 0, "ERR_DIV_ZERO");
        uint256 c0 = a * WAD;
        require(a == 0 || c0 / a == WAD, "ERR_DIV_INTERNAL"); // bmul overflow
        uint256 c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint256 c2 = c1 / b;
        return c2;
    }

    /** 
        @dev Calculates the value of BPT in units of liquidityAsset.
        @param _bPool         Address of Balancer pool
        @param liquidityAsset Asset used by Pool for liquidity to fund loans
        @param staker         Address that deposited BPTs to stakeLocker
        @param stakeLocker    Escrows BPTs deposited by staker
        @return USDC value of staker BPTs
    */
    function BPTVal(
        address _bPool,
        address liquidityAsset,
        address staker,
        address stakeLocker
    ) public view returns (uint256) {

        // Create interfaces for the balancerPool as a Pool and as an ERC-20 token
        IBPool bPool      = IBPool(_bPool);
        IERC20 bPoolERC20 = IERC20(_bPool);

        // FDTs are minted 1:1 (in wei) in the StakeLocker when staking BPTs, thus representing stake amount.
        // These are burned when withdrawing staked BPTs, thus representing the current stake amount.
        uint256 amountStakedBPT       = IERC20(stakeLocker).balanceOf(staker);
        uint256 totalSupplyBPT        = bPoolERC20.totalSupply();
        uint256 liquidityAssetBalance = bPool.getBalance(liquidityAsset);
        uint256 liquidityAssetWeight  = bPool.getNormalizedWeight(liquidityAsset);

        // liquidityAsset value = (amountStaked/totalSupply) * (liquidityAssetBalance/liquidityAssetWeight)
        return bdiv(amountStakedBPT, totalSupplyBPT).mul(bdiv(liquidityAssetBalance, liquidityAssetWeight)).div(WAD);
    }

    /** 
        @dev Calculate liquidityAsset swap out value of staker BPT balance escrowed in stakeLocker.
        @param _bPool          Balancer pool that issues the BPTs
        @param liquidityAsset  Swap out asset (e.g. USDC) to receive when burning BPTs
        @param staker          Address that deposited BPTs to stakeLocker
        @param stakeLocker     Escrows BPTs deposited by staker
        @return liquidityAsset Swap out value of staker BPTs
    */
    function getSwapOutValue(
        address _bPool,
        address liquidityAsset,
        address staker,
        address stakeLocker
    ) public view returns (uint256) {
        return _getSwapOutValue(_bPool, liquidityAsset, IERC20(stakeLocker).balanceOf(staker));
    }

    /** 
        @dev Calculate liquidityAsset swap out value of entire BPT balance escrowed in stakeLocker.
        @param _bPool          Balancer pool that issues the BPTs
        @param liquidityAsset  Swap out asset (e.g. USDC) to receive when burning BPTs
        @param stakeLocker     Escrows BPTs deposited by staker
        @return liquidityAsset Swap out value of StakeLocker BPTs
    */
    function getSwapOutValueLocker(
        address _bPool,
        address liquidityAsset,
        address stakeLocker
    ) public view returns (uint256) {
        return _getSwapOutValue(_bPool, liquidityAsset, IBPool(_bPool).balanceOf(stakeLocker));
    }

    function _getSwapOutValue(
        address _bPool,
        address liquidityAsset,
        uint256 poolAmountIn
    ) internal view returns (uint256) {
        // Fetch balancer pool token information
        IBPool bPool            = IBPool(_bPool);
        uint256 tokenBalanceOut = bPool.getBalance(liquidityAsset);
        uint256 tokenWeightOut  = bPool.getDenormalizedWeight(liquidityAsset);
        uint256 poolSupply      = bPool.totalSupply();
        uint256 totalWeight     = bPool.getTotalDenormalizedWeight();
        uint256 swapFee         = bPool.getSwapFee();

        // Returns the amount of liquidityAsset that can be recovered from BPT burning
        uint256 tokenAmountOut = bPool.calcSingleOutGivenPoolIn(
            tokenBalanceOut,
            tokenWeightOut,
            poolSupply,
            totalWeight,
            poolAmountIn,
            swapFee
        );

        // Max amount that can be swapped based on amount of liquidtyAsset in the Balancer Pool
        uint256 maxSwapOut = tokenBalanceOut.mul(bPool.MAX_OUT_RATIO()).div(WAD);  

        return tokenAmountOut <= maxSwapOut ? tokenAmountOut : maxSwapOut;
    }

    /**
        @dev Calculates BPTs required if burning BPTs for liquidityAsset, given supplied tokenAmountOutRequired.
        @param  _bPool                       Balancer pool that issues the BPTs
        @param  liquidityAsset               Swap out asset (e.g. USDC) to receive when burning BPTs
        @param  staker                       Address that deposited BPTs to stakeLocker
        @param  stakeLocker                  Escrows BPTs deposited by staker
        @param  liquidityAssetAmountRequired Amount of liquidityAsset required to recover
        @return [0] = poolAmountIn required
                [1] = poolAmountIn currently staked
    */
    function getPoolSharesRequired(
        address _bPool,
        address liquidityAsset,
        address staker,
        address stakeLocker,
        uint256 liquidityAssetAmountRequired
    ) public view returns (uint256, uint256) {

        IBPool bPool = IBPool(_bPool);

        uint256 tokenBalanceOut = bPool.getBalance(liquidityAsset);
        uint256 tokenWeightOut  = bPool.getDenormalizedWeight(liquidityAsset);
        uint256 poolSupply      = bPool.totalSupply();
        uint256 totalWeight     = bPool.getTotalDenormalizedWeight();
        uint256 swapFee         = bPool.getSwapFee();

        // Fetch amount of BPTs required to burn to receive liquidityAssetAmountRequired
        uint256 poolAmountInRequired = bPool.calcPoolInGivenSingleOut(
            tokenBalanceOut,
            tokenWeightOut,
            poolSupply,
            totalWeight,
            liquidityAssetAmountRequired,
            swapFee
        );

        // Fetch amount staked in stakeLocker by staker
        uint256 stakerBalance = IERC20(stakeLocker).balanceOf(staker);

        return (poolAmountInRequired, stakerBalance);
    }

    /**
        @dev Returns information on the stake requirements.
        @param  globals        Interface of MapleGlobals
        @param  balancerPool   Address of Balancer pool
        @param  liquidityAsset Address of liquidityAsset, to be returned from swap out
        @param  poolDelegate   Address of Pool Delegate
        @param  stakeLocker    Address of StakeLocker
        @return swapOutAmountRequired      Min amount of liquidityAsset coverage from staking required (in liquidityAsset units)
        @return currentPoolDelegateCover   Present amount of liquidityAsset coverage from Pool Delegate stake (in liquidityAsset units)
        @return enoughStakeForFinalization If enough stake is present from Pool Delegate for Pool finalization
        @return poolAmountInRequired       BPTs required for minimum liquidityAsset coverage
        @return poolAmountPresent          Current staked BPTs
    */
    function getInitialStakeRequirements(IGlobals globals, address balancerPool, address liquidityAsset, address poolDelegate, address stakeLocker) public view returns (
        uint256 swapOutAmountRequired,
        uint256 currentPoolDelegateCover,
        bool    enoughStakeForFinalization,
        uint256 poolAmountInRequired,
        uint256 poolAmountPresent
    ) {
        swapOutAmountRequired = convertFromUsd(globals, liquidityAsset, globals.swapOutRequired());
        (
            poolAmountInRequired,
            poolAmountPresent
        ) = getPoolSharesRequired(balancerPool, liquidityAsset, poolDelegate, stakeLocker, swapOutAmountRequired);

        currentPoolDelegateCover   = getSwapOutValue(balancerPool, liquidityAsset, poolDelegate, stakeLocker);
        enoughStakeForFinalization = poolAmountPresent >= poolAmountInRequired;
    }

    /**
        @dev View claimable balance from LiqudityLocker (reflecting deposit + gain/loss).
        @param  withdrawableFundsOfLp  FDT withdrawableFundsOf LP
        @param  depositDateForLp       LP deposit date
        @param  lockupPeriod           Pool lockup period
        @param  balanceOfLp            LP FDT balance
        @param  liquidityAssetDecimals Decimals of liquidityAsset
        @return total     Total     amount claimable
        @return principal Principal amount claimable
        @return interest  Interest  amount claimable
    */
    // TODO: Consider renaming this - could be mistaken for Pool claimable funds, not LP claimable
    function claimableFunds(
        uint256 withdrawableFundsOfLp,
        uint256 depositDateForLp,
        uint256 lockupPeriod,
        uint256 balanceOfLp,
        uint256 liquidityAssetDecimals
    ) 
        public
        view
        returns(
            uint256 total,
            uint256 principal,
            uint256 interest
        ) 
    {
        interest = withdrawableFundsOfLp;
        // Deposit is still within lockupPeriod, user has 0 claimable principal under this condition.
        if (depositDateForLp.add(lockupPeriod) > block.timestamp) total = interest; 
        else {
            principal = fromWad(balanceOfLp, liquidityAssetDecimals);
            total     = principal.add(interest);
        }
    }

    /************************/
    /*** Helper Functions ***/
    /************************/

    /**
        @dev Utility to convert from WAD precision to liquidtyAsset precision.
        @param amt Amount to convert
        @param liquidityAssetDecimals Liquidity asset decimal
    */
    function fromWad(uint256 amt, uint256 liquidityAssetDecimals) public view returns(uint256) {
        return amt.mul(10 ** liquidityAssetDecimals).div(WAD);
    }

    /** 
        @dev Internal helper function to return an interface of MapleGlobals.
        @param  poolFactory Factory that deployed the Pool,  stores MapleGlobals
        @return Interface of MapleGlobals
    */
    function _globals(address poolFactory) internal view returns (IGlobals) {
        return IGlobals(ILoanFactory(poolFactory).globals());
    }

    /** 
        @dev Function to return liquidityAsset in liquidityAsset units when given integer USD (E.g., $100 = 100).
        @param  globals        Globals contract interface
        @param  liquidityAsset Liquidity Asset of the pool 
        @param  usdAmount      USD amount to convert, in integer units (e.g., $100 = 100)
        @return usdAmount worth of liquidityAsset, in liquidityAsset units
    */
    function convertFromUsd(IGlobals globals, address liquidityAsset, uint256 usdAmount) internal view returns (uint256) {
        return usdAmount
            .mul(10 ** 8)                                         // Cancel out 10 ** 8 decimals from oracle
            .mul(10 ** IERC20Details(liquidityAsset).decimals())  // Convert to liquidityAsset precision
            .div(globals.getLatestPrice(liquidityAsset));         // Convert to liquidityAsset value
    }
}

////// contracts/math/SafeMathInt.sol
/* pragma solidity 0.6.11; */

library SafeMathInt {
    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

////// contracts/math/SafeMathUint.sol
/* pragma solidity 0.6.11; */

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

////// contracts/token/IFDT.sol
/* pragma solidity 0.6.11; */

interface IFDT {
    /**
        @dev Returns the total amount of funds a given address is able to withdraw currently.
        @param owner Address of FDT holder
        @return A uint256 representing the available funds for a given account
    */
    function withdrawableFundsOf(address owner) external view returns (uint256);

    /**
        @dev Withdraws all available funds for a FDT holder.
    */
    function withdrawFunds() external;

    /**
        @dev This event emits when new funds are distributed
        @param by the address of the sender who distributed funds
        @param fundsDistributed the amount of funds received for distribution
    */
    event FundsDistributed(address indexed by, uint256 fundsDistributed);

    /**
        @dev This event emits when distributed funds are withdrawn by a token holder.
        @param by the address of the receiver of funds
        @param fundsWithdrawn the amount of funds that were withdrawn
        @param totalWithdrawn the total amount of funds that were withdrawn
    */
    event FundsWithdrawn(address indexed by, uint256 fundsWithdrawn, uint256 totalWithdrawn);
}

////// lib/openzeppelin-contracts/contracts/math/SignedSafeMath.sol

/* pragma solidity >=0.6.0 <0.8.0; */

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

////// lib/openzeppelin-contracts/contracts/GSN/Context.sol

/* pragma solidity >=0.6.0 <0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol

/* pragma solidity >=0.6.0 <0.8.0; */

/* import "../../GSN/Context.sol"; */
/* import "./IERC20.sol"; */
/* import "../../math/SafeMath.sol"; */

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
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
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
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function _setupDecimals(uint8 decimals_) internal {
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

////// contracts/token/BasicFDT.sol
/* pragma solidity 0.6.11; */

/* import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol"; */
/* import "lib/openzeppelin-contracts/contracts/math/SafeMath.sol"; */
/* import "lib/openzeppelin-contracts/contracts/math/SignedSafeMath.sol"; */
/* import "./IFDT.sol"; */
/* import "../math/SafeMathUint.sol"; */
/* import "../math/SafeMathInt.sol"; */

/// @title BasicFDT implements base level FDT functionality for accounting for revenues
abstract contract BasicFDT is IFDT, ERC20 {
    using SafeMath       for uint256;
    using SafeMathUint   for uint256;
    using SignedSafeMath for  int256;
    using SafeMathInt    for  int256;

    uint256 internal constant pointsMultiplier = 2 ** 128;
    uint256 internal pointsPerShare;

    mapping(address => int256)  internal pointsCorrection;
    mapping(address => uint256) internal withdrawnFunds;

    event PointsPerShareUpdated(uint256 pointsPerShare);
    event PointsCorrectionUpdated(address account, int256 pointsCorrection);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) public { }

    /**
        @dev Distributes funds to token holders.
        @dev It reverts if the total supply of tokens is 0.
        It emits the `FundsDistributed` event if the amount of received ether is greater than 0.
        About undistributed funds:
            In each distribution, there is a small amount of funds which does not get distributed,
                which is `(value  pointsMultiplier) % totalSupply()`.
            With a well-chosen `pointsMultiplier`, the amount funds that are not getting distributed
                in a distribution can be less than 1 (base unit).
            We can actually keep track of the undistributed ether in a distribution
                and try to distribute it in the next distribution.
     */
    function _distributeFunds(uint256 value) internal {
        require(totalSupply() > 0, "FDT:SUPPLY_EQ_ZERO");

        if (value > 0) {
            pointsPerShare = pointsPerShare.add(value.mul(pointsMultiplier) / totalSupply());
            emit FundsDistributed(msg.sender, value);
            emit PointsPerShareUpdated(pointsPerShare);
        }
    }

    /**
        @dev Prepares funds withdrawal
        @dev It emits a `FundsWithdrawn` event if the amount of withdrawn ether is greater than 0.
    */
    function _prepareWithdraw() internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableFundsOf(msg.sender);

        withdrawnFunds[msg.sender] = withdrawnFunds[msg.sender].add(_withdrawableDividend);

        emit FundsWithdrawn(msg.sender, _withdrawableDividend, withdrawnFunds[msg.sender]);

        return _withdrawableDividend;
    }

    /**
        @dev View the amount of funds that an address can withdraw.
        @param _owner The address of a token holder.
        @return The amount funds that `_owner` can withdraw.
    */
    function withdrawableFundsOf(address _owner) public view override returns (uint256) {
        return accumulativeFundsOf(_owner).sub(withdrawnFunds[_owner]);
    }

    /**
        @dev View the amount of funds that an address has withdrawn.
        @param _owner The address of a token holder.
        @return The amount of funds that `_owner` has withdrawn.
    */
    function withdrawnFundsOf(address _owner) public view returns (uint256) {
        return withdrawnFunds[_owner];
    }

    /**
        @dev View the amount of funds that an address has earned in total.
        @dev accumulativeFundsOf(_owner) = withdrawableFundsOf(_owner) + withdrawnFundsOf(_owner)
        = (pointsPerShare * balanceOf(_owner) + pointsCorrection[_owner]) / pointsMultiplier
        @param _owner The address of a token holder.
        @return The amount of funds that `_owner` has earned in total.
    */
    function accumulativeFundsOf(address _owner) public view returns (uint256) {
        return
            pointsPerShare
                .mul(balanceOf(_owner))
                .toInt256Safe()
                .add(pointsCorrection[_owner])
                .toUint256Safe() / pointsMultiplier;
    }

    /**
        @dev Internal function that transfer tokens from one address to another.
        Update pointsCorrection to keep funds unchanged.
        @param from  The address to transfer from.
        @param to    The address to transfer to.
        @param value The amount to be transferred.
    */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        super._transfer(from, to, value);

        int256 _magCorrection = pointsPerShare.mul(value).toInt256Safe();
        pointsCorrection[from] = pointsCorrection[from].add(_magCorrection);
        pointsCorrection[to] = pointsCorrection[to].sub(_magCorrection);

        emit PointsCorrectionUpdated(from, pointsCorrection[from]);
        emit PointsCorrectionUpdated(to,   pointsCorrection[to]);
    }

    /**
        @dev Internal function that mints tokens to an account.
        Update pointsCorrection to keep funds unchanged.
        @param account The account that will receive the created tokens.
        @param value   The amount that will be created.
    */
    function _mint(address account, uint256 value) internal virtual override {
        super._mint(account, value);

        pointsCorrection[account] = pointsCorrection[account].sub(
            (pointsPerShare.mul(value)).toInt256Safe()
        );

        emit PointsCorrectionUpdated(account, pointsCorrection[account]);
    }

    /**
        @dev Internal function that burns an amount of the token of a given account.
        Update pointsCorrection to keep funds unchanged.
        @param account The account whose tokens will be burnt.
        @param value   The amount that will be burnt.
    */
    function _burn(address account, uint256 value) internal virtual override {
        super._burn(account, value);

        pointsCorrection[account] = pointsCorrection[account].add(
            (pointsPerShare.mul(value)).toInt256Safe()
        );
        emit PointsCorrectionUpdated(account, pointsCorrection[account]);
    }

    /**
        @dev Withdraws all available funds for a token holder
    */
    function withdrawFunds() public virtual override {}

    /**
        @dev Updates the current funds token balance
        and returns the difference of new and previous funds token balances
        @return A int256 representing the difference of the new and previous funds token balance
    */
    function _updateFundsTokenBalance() internal virtual returns (int256) {}

    /**
        @dev Register a payment of funds in tokens. May be called directly after a deposit is made.
        @dev Calls _updateFundsTokenBalance(), whereby the contract computes the delta of the new and the previous
        funds token balance and increments the total received funds (cumulative) by delta by calling _registerFunds()
    */
    function updateFundsReceived() public virtual {
        int256 newFunds = _updateFundsTokenBalance();

        if (newFunds > 0) {
            _distributeFunds(newFunds.toUint256Safe());
        }
    }
}

////// contracts/token/ExtendedFDT.sol
/* pragma solidity 0.6.11; */

/* import "./BasicFDT.sol"; */

/// @title ExtendedFDT implements FDT functionality for accounting for losses
abstract contract ExtendedFDT is BasicFDT {
    using SafeMath       for uint256;
    using SafeMathUint   for uint256;
    using SignedSafeMath for  int256;
    using SafeMathInt    for  int256;

    uint256 internal lossesPerShare;

    mapping(address => int256)  internal lossesCorrection;
    mapping(address => uint256) internal recognizedLosses;

    event   LossesPerShareUpdated(uint256 lossesPerShare);
    event LossesCorrectionUpdated(address account, int256 lossesCorrection);

    /**
        @dev This event emits when new losses are distributed
        @param by                The address of the sender who distributed losses
        @param lossesDistributed The amount of losses received for distribution
     */
    event LossesDistributed(address indexed by, uint256 lossesDistributed);

    /**
        @dev This event emits when distributed losses are recognized by a token holder.
        @param by                    The address of the receiver of losses
        @param lossesRecognized      The amount of losses that were recognized
        @param totalLossesRecognized The total amount of losses that were recognized
     */
    event LossesRecognized(address indexed by, uint256 lossesRecognized, uint256 totalLossesRecognized);

    constructor(string memory name, string memory symbol) BasicFDT(name, symbol) public { }

    /**
        @dev Distributes losses to token holders.
        @dev It reverts if the total supply of tokens is 0.
        It emits the `LossesDistributed` event if the amount of received losses is greater than 0.
        About undistributed losses:
            In each distribution, there is a small amount of losses which does not get distributed,
            which is `(value * pointsMultiplier) % totalSupply()`.
        With a well-chosen `pointsMultiplier`, the amount losses that are not getting distributed
            in a distribution can be less than 1 (base unit).
        We can actually keep track of the undistributed losses in a distribution
            and try to distribute it in the next distribution
    */
    function _distributeLosses(uint256 value) internal {
        require(totalSupply() > 0, "FDT:SUPPLY_EQ_ZERO");

        if (value > 0) {
            lossesPerShare = lossesPerShare.add(value.mul(pointsMultiplier) / totalSupply());
            emit LossesDistributed(msg.sender, value);
            emit LossesPerShareUpdated(lossesPerShare);
        }
    }

    /**
        @dev Prepares losses withdrawal
        @dev It emits a `LossesWithdrawn` event if the amount of withdrawn losses is greater than 0.
    */
    function _prepareLossesWithdraw() internal returns (uint256) {
        uint256 _recognizableDividend = recognizableLossesOf(msg.sender);

        recognizedLosses[msg.sender] = recognizedLosses[msg.sender].add(_recognizableDividend);

        emit LossesRecognized(msg.sender, _recognizableDividend, recognizedLosses[msg.sender]);

        return _recognizableDividend;
    }

    /**
        @dev View the amount of losses that an address can withdraw.
        @param _owner The address of a token holder
        @return The amount of losses that `_owner` can withdraw
    */
    function recognizableLossesOf(address _owner) public view returns (uint256) {
        return accumulativeLossesOf(_owner).sub(recognizedLosses[_owner]);
    }

    /**
        @dev View the amount of losses that an address has recognized.
        @param _owner The address of a token holder
        @return The amount of losses that `_owner` has recognized
    */
    function recognizedLossesOf(address _owner) public view returns (uint256) {
        return recognizedLosses[_owner];
    }

    /**
        @dev View the amount of losses that an address has earned in total.
        @dev accumulativeLossesOf(_owner) = withdrawableLossesOf(_owner) + withdrawnLossesOf(_owner)
        = (pointsPerShare * balanceOf(_owner) + pointsCorrection[_owner]) / pointsMultiplier
        @param _owner The address of a token holder
        @return The amount of losses that `_owner` has earned in total
    */
    function accumulativeLossesOf(address _owner) public view returns (uint256) {
        return
            lossesPerShare
                .mul(balanceOf(_owner))
                .toInt256Safe()
                .add(lossesCorrection[_owner])
                .toUint256Safe() / pointsMultiplier;
    }

    /**
        @dev Internal function that transfer tokens from one address to another.
        Update pointsCorrection to keep funds unchanged.
        @param from  The address to transfer from
        @param to    The address to transfer to
        @param value The amount to be transferred
    */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        super._transfer(from, to, value);

        int256 _lossesCorrection = lossesPerShare.mul(value).toInt256Safe();
        lossesCorrection[from]   = lossesCorrection[from].add(_lossesCorrection);
        lossesCorrection[to]     = lossesCorrection[to].sub(_lossesCorrection);

        emit LossesCorrectionUpdated(from, lossesCorrection[from]);
        emit LossesCorrectionUpdated(to,   lossesCorrection[to]);
    }

    /**
        @dev Internal function that mints tokens to an account.
        Update lossesCorrection to keep losses unchanged.
        @param account The account that will receive the created tokens.
        @param value   The amount that will be created.
    */
    function _mint(address account, uint256 value) internal virtual override {
        super._mint(account, value);

        lossesCorrection[account] = lossesCorrection[account].sub(
            (lossesPerShare.mul(value)).toInt256Safe()
        );

        emit LossesCorrectionUpdated(account, lossesCorrection[account]);
    }

    /**
        @dev Internal function that burns an amount of the token of a given account.
        Update lossesCorrection to keep losses unchanged.
        @param account The account whose tokens will be burnt.
        @param value   The amount that will be burnt.
    */
    function _burn(address account, uint256 value) internal virtual override {
        super._burn(account, value);

        lossesCorrection[account] = lossesCorrection[account].add(
            (lossesPerShare.mul(value)).toInt256Safe()
        );

        emit LossesCorrectionUpdated(account, lossesCorrection[account]);
    }

    /**
        @dev Register a loss. May be called directly after a shortfall after BPT burning occurs.
        @dev Calls _updateLossesTokenBalance(), whereby the contract computes the delta of the new and the previous
        losses and increments the total losses (cumulative) by delta by calling _distributeLosses()
    */
    function updateLossesReceived() public virtual {
        int256 newLosses = _updateLossesBalance();

        if (newLosses > 0) {
            _distributeLosses(newLosses.toUint256Safe());
        }
    }

    /**
        @dev Recognizes all recognizable losses for a user using loss accounting.
    */
    function recognizeLosses() internal virtual returns (uint256 losses) { }

    /**
        @dev Updates the current losses balance and returns the difference of new and previous losses balances.
        @return A int256 representing the difference of the new and previous losses balance.
    */
    function _updateLossesBalance() internal virtual returns (int256) { }
}

////// contracts/token/PoolFDT.sol
/* pragma solidity 0.6.11; */

/* import "./ExtendedFDT.sol"; */

/// @title PoolFDT inherits ExtendedFDT and accounts for gains/losses for Liquidity Providers.
abstract contract PoolFDT is ExtendedFDT {
    using SafeMath       for uint256;
    using SafeMathUint   for uint256;
    using SignedSafeMath for  int256;
    using SafeMathInt    for  int256;

    uint256 public interestSum;  // Sum of all withdrawable interest
    uint256 public poolLosses;   // Sum of all unrecognized losses

    uint256 public interestBalance;  // The amount of earned interest present and accounted for in this contract.
    uint256 public lossesBalance;    // The amount of losses present and accounted for in this contract.

    constructor(string memory name, string memory symbol) ExtendedFDT(name, symbol) public { }

    /**
        @dev Realizes losses incurred to LPs
    */
    function recognizeLosses() internal override returns (uint256 losses) {
        losses = _prepareLossesWithdraw();

        poolLosses = poolLosses.sub(losses);

        _updateLossesBalance();
    }

    /**
        @dev Updates the current losses balance and returns the difference of new and previous losses balances.
        @return A int256 representing the difference of the new and previous losses balance.
    */
    function _updateLossesBalance() internal override returns (int256) {
        uint256 _prevLossesTokenBalance = lossesBalance;

        lossesBalance = poolLosses;

        return int256(lossesBalance).sub(int256(_prevLossesTokenBalance));
    }

    /**
        @dev Updates the current interest balance and returns the difference of new and previous interest balances.
        @return A int256 representing the difference of the new and previous interest balance.
    */
    function _updateFundsTokenBalance() internal override returns (int256) {
        uint256 _prevFundsTokenBalance = interestBalance;

        interestBalance = interestSum;

        return int256(interestBalance).sub(int256(_prevFundsTokenBalance));
    }
}

////// contracts/Pool.sol
/* pragma solidity 0.6.11; */

/* import "./token/PoolFDT.sol"; */

/* import "./interfaces/IBPool.sol"; */
/* import "./interfaces/IDebtLocker.sol"; */
/* import "./interfaces/IGlobals.sol"; */
/* import "./interfaces/ILiquidityLocker.sol"; */
/* import "./interfaces/ILiquidityLockerFactory.sol"; */
/* import "./interfaces/ILoan.sol"; */
/* import "./interfaces/ILoanFactory.sol"; */
/* import "./interfaces/IPoolFactory.sol"; */
/* import "./interfaces/IStakeLocker.sol"; */
/* import "./interfaces/IStakeLockerFactory.sol"; */

/* import "./library/PoolLib.sol"; */

/* import "lib/openzeppelin-contracts/contracts/token/ERC20/SafeERC20.sol"; */

/// @title Pool maintains all accounting and functionality related to Pools.
contract Pool is PoolFDT {

    using SafeMath  for uint256;
    using SafeERC20 for IERC20;

    uint256 constant WAD = 10 ** 18;

    uint8 public constant DL_FACTORY = 1;  // Factory type of `DebtLockerFactory`

    IERC20  public immutable liquidityAsset;  // The asset deposited by lenders into the LiquidityLocker, for funding Loans

    address public immutable poolDelegate;     // Pool Delegate address, maintains full authority over the Pool
    address public immutable liquidityLocker;  // The LiquidityLocker owned by this contract
    address public immutable stakeAsset;       // The asset deposited by stakers into the StakeLocker (BPTs), for liquidation during default events
    address public immutable stakeLocker;      // Address of the StakeLocker, escrowing stakeAsset
    address public immutable superFactory;     // The factory that deployed this Loan

    uint256 private immutable liquidityAssetDecimals;  // decimals() precision for the liquidityAsset

    uint256 public           stakingFee;   // Fee for stakers   (in basis points)
    uint256 public immutable delegateFee;  // Fee for delegates (in basis points)

    uint256 public principalOut;  // Sum of all outstanding principal on Loans
    uint256 public liquidityCap;  // Amount of liquidity tokens accepted by the Pool
    uint256 public lockupPeriod;  // Period of time from a user's depositDate that they cannot withdraw any funds

    bool public openToPublic;  // Boolean opening Pool to public for LP deposits

    enum State { Initialized, Finalized, Deactivated }
    State public poolState;

    mapping(address => uint256)                     public depositDate;                // Used for withdraw penalty calculation
    mapping(address => mapping(address => address)) public debtLockers;                // Address of the `DebtLocker` contract corresponds to [Loan][DebtLockerFactory].
    mapping(address => bool)                        public admins;                     // Admin addresses who have permission to do certain operations in case of disaster mgt.
    mapping(address => bool)                        public allowedLiquidityProviders;  // Map that contains the list of address to enjoy the early access of the pool.
    mapping(address => uint256)                     public withdrawCooldown;           // Timestamp of when LP calls `intendToWithdraw()`

    event       LoanFunded(address indexed loan, address debtLocker, uint256 amountFunded);
    event            Claim(address indexed loan, uint256 interest, uint256 principal, uint256 fee);
    event   BalanceUpdated(address indexed who,  address token, uint256 balance);
    event  LPStatusChanged(address indexed user, bool status);
    event  LiquidityCapSet(uint256 newLiquidityCap);
    event  LockupPeriodSet(uint256 newLockupPeriod);
    event    StakingFeeSet(uint256 newStakingFee);
    event PoolStateChanged(State state);
    event         Cooldown(address indexed lp, uint256 cooldown);
    event  DefaultSuffered(
        address indexed loan,
        uint256 defaultSuffered,
        uint256 bptsBurned,
        uint256 bptsReturned,
        uint256 liquidityAssetRecoveredFromBurn
    );
    event  PoolOpenedToPublic(bool isOpen);

    /**
        Universal accounting law: fdtTotalSupply = liquidityLockerBal + principalOut - interestSum + poolLosses
               liquidityLockerBal + principalOut = fdtTotalSupply + interestSum - poolLosses
    */

    /**
        @dev Constructor for a Pool.
        @param  _poolDelegate   Address that has manager privileges of the Pool
        @param  _liquidityAsset Asset used to fund the Pool, It gets escrowed in `LiquidityLocker`
        @param  _stakeAsset     Asset escrowed in StakeLocker
        @param  _slFactory      Factory used to instantiate StakeLocker
        @param  _llFactory      Factory used to instantiate LiquidityLocker
        @param  _stakingFee     Fee that `stakers` earn on interest, in basis points
        @param  _delegateFee    Fee that `_poolDelegate` earns on interest, in basis points
        @param  _liquidityCap   Max amount of liquidityAsset accepted by the Pool
        @param  name            Name of Pool token
        @param  symbol          Symbol of Pool token
    */
    constructor(
        address _poolDelegate,
        address _liquidityAsset,
        address _stakeAsset,
        address _slFactory,
        address _llFactory,
        uint256 _stakingFee,
        uint256 _delegateFee,
        uint256 _liquidityCap,
        string memory name,
        string memory symbol
    ) PoolFDT(name, symbol) public {

        // Conduct sanity checks on Pool params
        PoolLib.poolSanityChecks(_globals(msg.sender), _liquidityAsset, _stakeAsset, _stakingFee, _delegateFee);

        // Assign variables relating to liquidityAsset
        liquidityAsset         = IERC20(_liquidityAsset);
        liquidityAssetDecimals = ERC20(_liquidityAsset).decimals();

        // Assign state variables
        stakeAsset   = _stakeAsset;
        poolDelegate = _poolDelegate;
        stakingFee   = _stakingFee;
        delegateFee  = _delegateFee;
        superFactory = msg.sender;
        liquidityCap = _liquidityCap;

        // Initialize the LiquidityLocker and StakeLocker
        stakeLocker     = address(IStakeLockerFactory(_slFactory).newLocker(_stakeAsset, _liquidityAsset));
        liquidityLocker = address(ILiquidityLockerFactory(_llFactory).newLocker(_liquidityAsset));

        lockupPeriod = 180 days;

        emit PoolStateChanged(State.Initialized);
    }

    /*******************************/
    /*** Pool Delegate Functions ***/
    /*******************************/

    /**
        @dev Finalize the Pool, enabling deposits. Checks Pool Delegate amount deposited to StakeLocker.
    */
    function finalize() external {
        _isValidDelegateAndProtocolNotPaused();
        _isValidState(State.Initialized);
        (,, bool stakeSufficient,,) = getInitialStakeRequirements();
        require(stakeSufficient, "Pool:INSUFFICIENT_STAKE");
        poolState = State.Finalized;
        emit PoolStateChanged(poolState);
    }

    /**
        @dev Fund a loan for amt, utilize the supplied dlFactory for debt lockers.
        @param  loan      Address of the loan to fund
        @param  dlFactory The DebtLockerFactory to utilize
        @param  amt       Amount to fund the loan
    */
    function fundLoan(address loan, address dlFactory, uint256 amt) external {
        _isValidDelegateAndProtocolNotPaused();
        _isValidState(State.Finalized);
        principalOut = principalOut.add(amt);
        PoolLib.fundLoan(debtLockers, superFactory, liquidityLocker, loan, dlFactory, amt);
        _emitBalanceUpdatedEvent();
    }

    /**
        @dev Liquidate the loan. Pool delegate could liquidate a loan only when loan completes its grace period.
        Pool delegate can claim its proportion of recovered funds from liquidation using the `claim()` function.
        @param loan      Address of the loan contract to liquidate
        @param dlFactory Address of the debt locker factory that is used to pull corresponding debt locker
     */
    function triggerDefault(address loan, address dlFactory) external {
        _isValidDelegateAndProtocolNotPaused();
        IDebtLocker(debtLockers[loan][dlFactory]).triggerDefault();
    }

    /**
        @dev Claim available funds for loan through specified DebtLockerFactory.
        @param  loan      Address of the loan to claim from
        @param  dlFactory The DebtLockerFactory (always maps to a single debt locker)
        @return [0] = Total amount claimed
                [1] = Interest  portion claimed
                [2] = Principal portion claimed
                [3] = Fee       portion claimed
                [4] = Excess    portion claimed
                [5] = Recovered portion claimed (from liquidations)
                [6] = Default suffered
    */
    function claim(address loan, address dlFactory) external returns(uint256[7] memory) {
        _whenProtocolNotPaused();
        _isValidDelegateOrAdmin();
        uint256[7] memory claimInfo = IDebtLocker(debtLockers[loan][dlFactory]).claim();

        (uint256 poolDelegatePortion, uint256 stakeLockerPortion, uint256 principalClaim, uint256 interestClaim) = PoolLib.calculateClaimAndPortions(claimInfo, delegateFee, stakingFee);

        // Subtract outstanding principal by principal claimed plus excess returned
        // Considers possible principalClaim overflow if liquidityAsset is transferred directly into Loan
        if (principalClaim <= principalOut) {
            principalOut = principalOut - principalClaim;
        } else {
            interestClaim  = interestClaim.add(principalClaim - principalOut);  // Distribute principalClaim overflow as interest to LPs
            principalClaim = principalOut;                                      // Set principalClaim to principalOut so correct amount gets transferred
            principalOut   = 0;                                                 // Set principalOut to zero to avoid subtraction overflow
        }

        // Accounts for rounding error in stakeLocker/poolDelegate/liquidityLocker interest split
        interestSum = interestSum.add(interestClaim);

        _transferLiquidityAsset(poolDelegate, poolDelegatePortion);  // Transfer fee and portion of interest to pool delegate
        _transferLiquidityAsset(stakeLocker,  stakeLockerPortion);   // Transfer portion of interest to stakeLocker

        // Transfer remaining claim (remaining interest + principal + excess + recovered) to liquidityLocker
        // Dust will accrue in Pool, but this ensures that state variables are in sync with liquidityLocker balance updates
        // Not using balanceOf in case of external address transferring liquidityAsset directly into Pool
        // Ensures that internal accounting is exactly reflective of balance change.
        _transferLiquidityAsset(liquidityLocker, principalClaim.add(interestClaim));

        // Handle default if defaultSuffered > 0
        if (claimInfo[6] > 0) _handleDefault(loan, claimInfo[6]);

        // Update funds received for StakeLockerFDTs
        IStakeLocker(stakeLocker).updateFundsReceived();

        // Update funds received for PoolFDTs
        updateFundsReceived();

        _emitBalanceUpdatedEvent();
        emit BalanceUpdated(stakeLocker, address(liquidityAsset), liquidityAsset.balanceOf(stakeLocker));

        emit Claim(loan, interestClaim, principalClaim, claimInfo[3]);  // TODO: Discuss with offchain team about requirements for event

        return claimInfo;  // TODO: Discuss with offchain team about requirements for return
    }

    /**
        @dev Helper function if a claim has been made and there is a non-zero defaultSuffered amount.
        @param loan            Address of loan that has defaulted
        @param defaultSuffered Losses suffered from default after liquidation
    */
    function _handleDefault(address loan, uint256 defaultSuffered) internal {

        (uint256 bptsBurned, uint256 postBurnBptBal, uint256 liquidityAssetRecoveredFromBurn) = PoolLib.handleDefault(liquidityAsset, stakeLocker, stakeAsset, loan, defaultSuffered);

        // If BPT burn is not enough to cover full default amount, pass on losses to LPs with PoolFDT loss accounting
        if (defaultSuffered > liquidityAssetRecoveredFromBurn) {
            poolLosses = poolLosses.add(defaultSuffered - liquidityAssetRecoveredFromBurn);
            updateLossesReceived();
        }

        // Transfer liquidityAsset from burn to liquidityLocker
        liquidityAsset.safeTransfer(liquidityLocker, liquidityAssetRecoveredFromBurn);

        principalOut = principalOut.sub(defaultSuffered);  // Subtract rest of Loan's principal from principalOut

        emit DefaultSuffered(
            loan,                            // Which loan defaultSuffered is from
            defaultSuffered,                 // Total default suffered from loan by Pool after liquidation
            bptsBurned,                      // Amount of BPTs burned from stakeLocker
            postBurnBptBal,                  // Remaining BPTs in stakeLocker post-burn
            liquidityAssetRecoveredFromBurn  // Amount of liquidityAsset recovered from burning BPTs
        );
    }

    /**
        @dev Pool Delegate triggers deactivation, permanently shutting down the pool. Must have less than 100 USD worth of liquidityAsset principalOut.
    */
    function deactivate() external {
        _isValidDelegateAndProtocolNotPaused();
        _isValidState(State.Finalized);
        PoolLib.validateDeactivation(_globals(superFactory), principalOut, address(liquidityAsset));
        poolState = State.Deactivated;
        emit PoolStateChanged(poolState);
    }

    /**************************************/
    /*** Pool Delegate Setter Functions ***/
    /**************************************/

    /**
        @dev Set `liquidityCap`, Only allowed by the Pool Delegate or the admin.
        @param newLiquidityCap New liquidityCap value
    */
    function setLiquidityCap(uint256 newLiquidityCap) external {
        _whenProtocolNotPaused();
        _isValidDelegateOrAdmin();
        liquidityCap = newLiquidityCap;
        emit LiquidityCapSet(newLiquidityCap);
    }

    /**
        @dev Set the lockup period. Only Pool Delegate can call this function.
        @param newLockupPeriod New lockup period used to restrict the withdrawals.
     */
    function setLockupPeriod(uint256 newLockupPeriod) external {
        _isValidDelegateAndProtocolNotPaused();
        require(newLockupPeriod <= lockupPeriod, "Pool:INVALID_VALUE");
        lockupPeriod = newLockupPeriod;
        emit LockupPeriodSet(newLockupPeriod);
    }

    /**
        @dev Update staking fee. Only Pool Delegate can call this function.
        @param newStakingFee New staking fee.
    */
    function setStakingFee(uint256 newStakingFee) external {
        _isValidDelegateAndProtocolNotPaused();
        require(newStakingFee.add(delegateFee) <= 10_000, "Pool:INVALID_FEE");
        stakingFee = newStakingFee;
        emit StakingFeeSet(newStakingFee);
    }

    /**
        @dev Update user status on Pool allowlist. Only Pool Delegate can call this function.
        @param user   The address to set status for.
        @param status The status of user on allowlist.
    */
    function setAllowList(address user, bool status) external {
        _isValidDelegateAndProtocolNotPaused();
        allowedLiquidityProviders[user] = status;
        emit LPStatusChanged(user, status);
    }

    /**
        @dev Update user status on StakeLocker allowlist. Only Pool Delegate can call this function.
        @param user   The address to set status for.
        @param status The status of user on allowlist.
    */
    function setAllowlistStakeLocker(address user, bool status) external {
        _isValidDelegateAndProtocolNotPaused();
        IStakeLocker(stakeLocker).setAllowlist(user, status);
    }

    /**
        @dev Set admin
        @param newAdmin new admin address.
        @param allowed Status of an admin.
    */
    function setAdmin(address newAdmin, bool allowed) external {
        _isValidDelegateAndProtocolNotPaused();
        admins[newAdmin] = allowed;
    }

    /**
        @dev Set public pool access. Only Pool Delegate can call this function.
        @param open Public pool access status.
    */
    function setOpenToPublic(bool open) external {
        _isValidDelegateAndProtocolNotPaused();
        openToPublic = open;
        emit PoolOpenedToPublic(open);
    }

    /************************************/
    /*** Liquidity Provider Functions ***/
    /************************************/

    /**
        @dev Liquidity providers can deposit liquidityAsset into the LiquidityLocker, minting FDTs.
        @param amt Amount of liquidityAsset to deposit
    */
    function deposit(uint256 amt) external {
        _whenProtocolNotPaused();
        _isValidState(State.Finalized);
        require(isDepositAllowed(amt), "Pool:NOT_ALLOWED");

        withdrawCooldown[msg.sender] = uint256(0);  // Reset withdrawCooldown if LP had previously intended to withdraw

        uint256 wad = _toWad(amt);
        PoolLib.updateDepositDate(depositDate, balanceOf(msg.sender), wad, msg.sender);

        liquidityAsset.safeTransferFrom(msg.sender, liquidityLocker, amt);
        _mint(msg.sender, wad);

        _emitBalanceUpdatedEvent();
        emit Cooldown(msg.sender, uint256(0));
    }

    /**
        @dev Activates the cooldown period to withdraw. It can't be called if the user is not providing liquidity.
    **/
    function intendToWithdraw() external {
        PoolLib.intendToWithdraw(withdrawCooldown, balanceOf(msg.sender));
    }

    /**
        @dev Cancels an initiated withdrawal by resetting withdrawCooldown.
    **/
    function cancelWithdraw() external {
        PoolLib.cancelWithdraw(withdrawCooldown);
    }

    /**
        @dev Liquidity providers can withdraw liquidityAsset from the LiquidityLocker, burning PoolFDTs.
        @param amt Amount of liquidityAsset to withdraw
    */
    function withdraw(uint256 amt) external {
        _whenProtocolNotPaused();
        uint256 wad = _toWad(amt);
        require(PoolLib.isWithdrawAllowed(withdrawCooldown[msg.sender], _globals(superFactory)), "Pool:WITHDRAW_NOT_ALLOWED");
        require(depositDate[msg.sender].add(lockupPeriod) <= block.timestamp,                    "Pool:FUNDS_LOCKED");

        _burn(msg.sender, wad);  // Burn the corresponding FDT balance
        withdrawFunds();         // Transfer full entitled interest, decrement `interestSum`

        // Transfer amount that is due after realized losses are accounted for.
        // recognizedLosses are absorbed by the LP.
        _transferLiquidityLockerFunds(msg.sender, amt.sub(recognizeLosses()));

        // TODO: Do we need PoolFDT BalanceUpdated events?
        _emitBalanceUpdatedEvent();
    }

    /**
        @dev Transfer PoolFDTs.
        @param from Address sending   PoolFDTs
        @param to   Address receiving PoolFDTs
        @param wad  Amount of PoolFDTs to transfer
    */
    function _transfer(address from, address to, uint256 wad) internal override {
        _whenProtocolNotPaused();
        PoolLib.prepareTransfer(withdrawCooldown, depositDate, from, to, wad, _globals(superFactory), balanceOf(to), recognizableLossesOf(from));
        super._transfer(from, to, wad);
    }

    /**
        @dev Withdraws all claimable interest from the `liquidityLocker` for a user using `interestSum` accounting.
    */
    function withdrawFunds() public override {
        _whenProtocolNotPaused();
        uint256 withdrawableFunds = _prepareWithdraw();

        if (withdrawableFunds > uint256(0)) {
            _transferLiquidityLockerFunds(msg.sender, withdrawableFunds);
            _emitBalanceUpdatedEvent();

            interestSum = interestSum.sub(withdrawableFunds);

            _updateFundsTokenBalance();
        }
    }

    /**************************/
    /*** Governor Functions ***/
    /**************************/

    /**
        @dev Transfer any locked funds to the governor.
        @param token Address of the token to reclaim.
    */
    function reclaimERC20(address token) external {
        PoolLib.reclaimERC20(token, address(liquidityAsset), _globals(superFactory));
    }

    /*************************/
    /*** Getter Functions ***/
    /*************************/

    /**
        @dev View claimable balance from LiqudityLocker (reflecting deposit + gain/loss).
        @param lp Liquidity Provider to check claimableFunds for
        @return total     Total     amount claimable
        @return principal Principal amount claimable
        @return interest  Interest  amount claimable
    */
    function claimableFunds(address lp) public view returns(uint256 total, uint256 principal, uint256 interest) {
        (total, principal, interest) =
            PoolLib.claimableFunds(
                withdrawableFundsOf(lp),
                depositDate[lp],
                lockupPeriod,
                balanceOf(lp),
                liquidityAssetDecimals
            );
    }

    /**
        @dev Calculates the value of BPT in units of liquidityAsset.
        @param _bPool          Address of Balancer pool
        @param _liquidityAsset Asset used by Pool for liquidity to fund loans
        @param _staker         Address that deposited BPTs to stakeLocker
        @param _stakeLocker    Escrows BPTs deposited by staker
        @return USDC value of staker BPTs
    */
    function BPTVal(
        address _bPool,
        address _liquidityAsset,
        address _staker,
        address _stakeLocker
    ) public view returns (uint256) {
        return PoolLib.BPTVal(_bPool, _liquidityAsset, _staker, _stakeLocker);
    }

    /**
        @dev Check whether the given `depositAmt` is acceptable based on current liquidityCap.
        @param depositAmt Amount of tokens (i.e liquidityAsset type) user is trying to deposit
    */
    function isDepositAllowed(uint256 depositAmt) public view returns(bool) {
        bool isValidLP = openToPublic || allowedLiquidityProviders[msg.sender];
        return _balanceOfLiquidityLocker().add(principalOut).add(depositAmt) <= liquidityCap && isValidLP;
    }

    /**
        @dev Returns information on the stake requirements.
        @return [0] = Min amount of liquidityAsset coverage from staking required
                [1] = Present amount of liquidityAsset coverage from Pool Delegate stake
                [2] = If enough stake is present from Pool Delegate for finalization
                [3] = Staked BPTs required for minimum liquidityAsset coverage
                [4] = Current staked BPTs
    */
    function getInitialStakeRequirements() public view returns (uint256, uint256, bool, uint256, uint256) {
        return PoolLib.getInitialStakeRequirements(_globals(superFactory), stakeAsset, address(liquidityAsset), poolDelegate, stakeLocker);
    }

    /**
        @dev Calculates BPTs required if burning BPTs for liquidityAsset, given supplied tokenAmountOutRequired.
        @param  _bPool                        Balancer pool that issues the BPTs
        @param  _liquidityAsset               Swap out asset (e.g. USDC) to receive when burning BPTs
        @param  _staker                       Address that deposited BPTs to stakeLocker
        @param  _stakeLocker                  Escrows BPTs deposited by staker
        @param  _liquidityAssetAmountRequired Amount of liquidityAsset required to recover
        @return [0] = poolAmountIn required
                [1] = poolAmountIn currently staked
    */
    function getPoolSharesRequired(
        address _bPool,
        address _liquidityAsset,
        address _staker,
        address _stakeLocker,
        uint256 _liquidityAssetAmountRequired
    ) external view returns (uint256, uint256) {
        return PoolLib.getPoolSharesRequired(_bPool, _liquidityAsset, _staker, _stakeLocker, _liquidityAssetAmountRequired);
    }

    /**
      @dev Checks whether pool state is `Finalized`?
      @return bool Boolean value indicating if Pool is in a Finalized state.
     */
    function isPoolFinalized() external view returns(bool) {
        return poolState == State.Finalized;
    }

    /************************/
    /*** Helper Functions ***/
    /************************/

    /**
        @dev Utility to convert to WAD precision.
        @param amt Amount to convert
    */
    function _toWad(uint256 amt) internal view returns(uint256) {
        return amt.mul(WAD).div(10 ** liquidityAssetDecimals);
    }

    /**
        @dev Fetch the balance of this Pool's LiquidityLocker.
        @return Balance of LiquidityLocker
    */
    function _balanceOfLiquidityLocker() internal view returns(uint256) {
        return liquidityAsset.balanceOf(liquidityLocker);
    }

    /**
        @dev Utility to check current state of Pool againt provided state.
        @param _state Enum of desired Pool state
    */
    function _isValidState(State _state) internal view {
        require(poolState == _state, "Pool:INVALID_STATE");
    }

    /**
        @dev Utility to return if msg.sender is the Pool Delegate.
    */
    function _isValidDelegate() internal view {
        require(msg.sender == poolDelegate, "Pool:INVALID_DELEGATE");
    }

    /**
        @dev Utility to return MapleGlobals interface.
    */
    function _globals(address poolFactory) internal view returns (IGlobals) {
        return IGlobals(IPoolFactory(poolFactory).globals());
    }

    /**
        @dev Utility to emit BalanceUpdated event for LiquidityLocker.
    */
    function _emitBalanceUpdatedEvent() internal {
        emit BalanceUpdated(liquidityLocker, address(liquidityAsset), _balanceOfLiquidityLocker());
    }

    /**
        @dev Transfers liquidity asset from address(this) to given `to` address.
        @param to    Address to transfer liquidityAsset
        @param value Amount of liquidity asset that gets transferred
    */
    function _transferLiquidityAsset(address to, uint256 value) internal {
        liquidityAsset.safeTransfer(to, value);
    }

    /**
        @dev Function to determine if msg.sender is eligible to setLiquidityCap for security reasons.
    */
    function _isValidDelegateOrAdmin() internal {
        require(msg.sender == poolDelegate || admins[msg.sender], "Pool:UNAUTHORIZED");
    }

    /**
        @dev Function to block functionality of functions when protocol is in a paused state.
    */
    function _whenProtocolNotPaused() internal {
        require(!_globals(superFactory).protocolPaused(), "Pool:PROTOCOL_PAUSED");
    }

    function _isValidDelegateAndProtocolNotPaused() internal {
        _isValidDelegate();
        _whenProtocolNotPaused();
    }

    function _transferLiquidityLockerFunds(address to, uint256 value) internal {
        ILiquidityLocker(liquidityLocker).transfer(to, value);
    }
}

////// lib/openzeppelin-contracts/contracts/utils/Pausable.sol

/* pragma solidity >=0.6.0 <0.8.0; */

/* import "../GSN/Context.sol"; */

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

////// contracts/PoolFactory.sol
/* pragma solidity 0.6.11; */

/* import "./Pool.sol"; */

/* import "lib/openzeppelin-contracts/contracts/utils/Pausable.sol"; */

/// @title PoolFactory instantiates Pools.
contract PoolFactory is Pausable {

    uint8 public constant LL_FACTORY = 3;  // Factory type of `LiquidityLockerFactory`
    uint8 public constant SL_FACTORY = 4;  // Factory type of `StakeLockerFactory`

    uint256  public poolsCreated;  // Incrementor for number of Pools created
    IGlobals public globals;       // MapleGlobals contract

    mapping(uint256 => address) public pools;   // Map to keep `Pool` contract corresponds to its index.
    mapping(address => bool)    public isPool;  // Used to check if a `Pool` was instantiated from this factory.
    mapping(address => bool)    public admins;  // Admin addresses that have permission to do certain operations in case of disaster mgt

    event PoolCreated(
        address indexed pool,
        address indexed delegate,
        address liquidityAsset,
        address stakeAsset,
        address liquidityLocker,
        address stakeLocker,
        uint256 stakingFee,
        uint256 delegateFee,
        uint256 liquidityCap,
        string  name,
        string  symbol
    );

    constructor(address _globals) public {
        globals = IGlobals(_globals);
    }

    /**
        @dev Update the MapleGlobals contract
        @param newGlobals Address of new MapleGlobals contract
    */
    function setGlobals(address newGlobals) external {
        _isValidGovernor();
        globals = IGlobals(newGlobals);
    }

    /**
        @dev Instantiates a Pool contract.
        @param  liquidityAsset The asset escrowed in LiquidityLocker
        @param  stakeAsset     The asset escrowed in StakeLocker
        @param  slFactory      The factory to instantiate a StakeLocker from
        @param  llFactory      The factory to instantiate a LiquidityLocker from
        @param  stakingFee     Fee that stakers earn on interest, in basis points
        @param  delegateFee    Fee that pool delegate earns on interest, in basis points
        @param  liquidityCap   Amount of liquidityAsset accepted by the pool
    */
    function createPool(
        address liquidityAsset,
        address stakeAsset,
        address slFactory,
        address llFactory,
        uint256 stakingFee,
        uint256 delegateFee,
        uint256 liquidityCap
    ) public whenNotPaused returns (address) {
        _whenProtocolNotPaused();
        {
            IGlobals _globals = globals;
            require(_globals.isValidSubFactory(address(this), llFactory, LL_FACTORY), "PF:INVALID_LL_FACTORY");
            require(_globals.isValidSubFactory(address(this), slFactory, SL_FACTORY), "PF:INVALID_SL_FACTORY");
            require(_globals.isValidPoolDelegate(msg.sender),                         "PF:INVALID_DELEGATE");
        }

        string memory name   = string(abi.encodePacked("Maple Pool Token"));
        string memory symbol = string(abi.encodePacked("MPL-LP"));

        Pool pool =
            new Pool(
                msg.sender,
                liquidityAsset,
                stakeAsset,
                slFactory,
                llFactory,
                stakingFee,
                delegateFee,
                liquidityCap,
                name,
                symbol
            );

        pools[poolsCreated]   = address(pool);
        isPool[address(pool)] = true;
        poolsCreated++;

        emit PoolCreated(
            address(pool),
            msg.sender,
            liquidityAsset,
            stakeAsset,
            pool.liquidityLocker(),
            pool.stakeLocker(),
            stakingFee,
            delegateFee,
            liquidityCap,
            name,
            symbol
        );
        return address(pool);
    }

    /**
        @dev Set admin.
        @param newAdmin New admin address
        @param allowed  Status of an admin
    */
    function setAdmin(address newAdmin, bool allowed) external {
        _isValidGovernor();
        admins[newAdmin] = allowed;
    }

    /**
        @dev Triggers paused state. Halts functionality for certain functions. Only Governor can call this function.
    */
    function pause() external {
        _isValidGovernorOrAdmin();
        super._pause();
    }

    /**
        @dev Triggers unpaused state. Returns functionality for certain functions. Only Governor can call this function.
    */
    function unpause() external {
        _isValidGovernorOrAdmin();
        super._unpause();
    }

    /**
        @dev Function to determine if msg.sender is eligible to trigger pause/unpause.
    */
    function _isValidGovernor() internal view {
        require(msg.sender == globals.governor(), "PF:INVALID_GOVERNOR");
    }

    /**
        @dev Function to determine if msg.sender is eligible to trigger pause/unpause.
    */
    function _isValidGovernorOrAdmin() internal {
        require(msg.sender == globals.governor() || admins[msg.sender], "PF:UNAUTHORIZED");
    }

    /**
        @dev Function to determine if msg.sender is eligible to trigger pause/unpause.
    */
    function _whenProtocolNotPaused() internal {
        require(!globals.protocolPaused(), "PF:PROTOCOL_PAUSED");
    }
}