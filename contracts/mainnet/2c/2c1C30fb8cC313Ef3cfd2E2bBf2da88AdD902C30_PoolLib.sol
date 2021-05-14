/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

// SPDX-License-Identifier:  AGPL-3.0-or-later // hevm: flattened sources of contracts/library/PoolLib.sol
pragma solidity =0.6.11 >=0.6.0 <0.8.0 >=0.6.2 <0.8.0;

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
        uint256 tokenAmountOut,
        uint256 maxPoolAmountIn
    ) external returns (uint256 poolAmountIn);

}

////// contracts/interfaces/IDebtLockerFactory.sol
/* pragma solidity 0.6.11; */

interface IDebtLockerFactory {

    function owner(address) external view returns (address);

    function isLocker(address) external view returns (bool);

    function factoryType() external view returns (uint8);

    function newLocker(address) external returns (address);

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

////// contracts/interfaces/IERC20Details.sol
/* pragma solidity 0.6.11; */

/* import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol"; */

interface IERC20Details is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

}

////// contracts/interfaces/ILiquidityLocker.sol
/* pragma solidity 0.6.11; */

interface ILiquidityLocker {

    function pool() external view returns (address);

    function liquidityAsset() external view returns (address);

    function transfer(address, uint256) external;

    function fundLoan(address, address, uint256) external;

}

////// contracts/token/interfaces/IBaseFDT.sol
/* pragma solidity 0.6.11; */

interface IBaseFDT {

    /**
        @dev    Returns the total amount of funds a given address is able to withdraw currently.
        @param  owner Address of FDT holder.
        @return A uint256 representing the available funds for a given account.
    */
    function withdrawableFundsOf(address owner) external view returns (uint256);

    /**
        @dev Withdraws all available funds for a FDT holder.
    */
    function withdrawFunds() external;

    /**
        @dev   This event emits when new funds are distributed.
        @param by               The address of the sender that distributed funds.
        @param fundsDistributed The amount of funds received for distribution.
    */
    event FundsDistributed(address indexed by, uint256 fundsDistributed);

    /**
        @dev   This event emits when distributed funds are withdrawn by a token holder.
        @param by             The address of the receiver of funds.
        @param fundsWithdrawn The amount of funds that were withdrawn.
        @param totalWithdrawn The total amount of funds that were withdrawn.
    */
    event FundsWithdrawn(address indexed by, uint256 fundsWithdrawn, uint256 totalWithdrawn);

}

////// contracts/token/interfaces/IBasicFDT.sol
/* pragma solidity 0.6.11; */

/* import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol"; */

/* import "./IBaseFDT.sol"; */

interface IBasicFDT is IBaseFDT, IERC20 {

    event PointsPerShareUpdated(uint256);

    event PointsCorrectionUpdated(address indexed, int256);

    function withdrawnFundsOf(address) external view returns (uint256);

    function accumulativeFundsOf(address) external view returns (uint256);

    function updateFundsReceived() external;

}

////// contracts/token/interfaces/ILoanFDT.sol
/* pragma solidity 0.6.11; */

/* import "./IBasicFDT.sol"; */

interface ILoanFDT is IBasicFDT {

    function fundsToken() external view returns (address);

    function fundsTokenBalance() external view returns (uint256);

}

////// contracts/interfaces/ILoan.sol
/* pragma solidity 0.6.11; */

/* import "../token/interfaces/ILoanFDT.sol"; */

interface ILoan is ILoanFDT {
    
    // State Variables
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
    
    function collateralRequiredForDrawdown(uint256) external view returns (uint256);
    

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

    function getFullPayment() external view returns (uint256, uint256, uint256);
    

    // Liquidations
    function amountLiquidated() external view returns (uint256);

    function defaultSuffered() external view returns (uint256);
    
    function amountRecovered() external view returns (uint256);
    
    function getExpectedAmountRecovered() external view returns (uint256);

    function liquidationExcess() external view returns (uint256);
    

    // Functions
    function fundLoan(address, uint256) external;
    
    function makePayment() external;
    
    function drawdown(uint256) external;
    
    function makeFullPayment() external;
    
    function triggerDefault() external;
    
    function unwind() external;
    

    // Security 
    function pause() external;

    function unpause() external;

    function loanAdmins(address) external view returns (address);

    function setLoanAdmin(address, bool) external;


    // Misc
    function reclaimERC20(address) external;

}

////// contracts/interfaces/ILoanFactory.sol
/* pragma solidity 0.6.11; */

interface ILoanFactory {

    function CL_FACTORY() external view returns (uint8);

    function FL_FACTORY() external view returns (uint8);

    function INTEREST_CALC_TYPE() external view returns (uint8);

    function LATEFEE_CALC_TYPE() external view returns (uint8);

    function PREMIUM_CALC_TYPE() external view returns (uint8);

    function globals() external view returns (address);

    function loansCreated() external view returns (uint256);

    function loans(uint256) external view returns (address);

    function isLoan(address) external view returns (bool);

    function loanFactoryAdmins(address) external view returns (bool);

    function setGlobals(address) external;
    
    function createLoan(address, address, address, address, uint256[5] memory, address[3] memory) external returns (address);

    function setLoanFactoryAdmin(address, bool) external;

    function pause() external;

    function unpause() external;

}

////// contracts/interfaces/IMapleGlobals.sol
/* pragma solidity 0.6.11; */

interface IMapleGlobals {

    function pendingGovernor() external view returns (address);

    function governor() external view returns (address);

    function globalAdmin() external view returns (address);

    function mpl() external view returns (address);

    function mapleTreasury() external view returns (address);

    function isValidBalancerPool(address) external view returns (bool);

    function treasuryFee() external view returns (uint256);

    function investorFee() external view returns (uint256);

    function defaultGracePeriod() external view returns (uint256);

    function fundingPeriod() external view returns (uint256);

    function swapOutRequired() external view returns (uint256);

    function isValidLiquidityAsset(address) external view returns (bool);

    function isValidCollateralAsset(address) external view returns (bool);

    function isValidPoolDelegate(address) external view returns (bool);

    function validCalcs(address) external view returns (bool);

    function isValidCalc(address, uint8) external view returns (bool);

    function getLpCooldownParams() external view returns (uint256, uint256);

    function isValidLoanFactory(address) external view returns (bool);

    function isValidSubFactory(address, address, uint8) external view returns (bool);

    function isValidPoolFactory(address) external view returns (bool);
    
    function getLatestPrice(address) external view returns (uint256);
    
    function defaultUniswapPath(address, address) external view returns (address);

    function minLoanEquity() external view returns (uint256);
    
    function maxSwapSlippage() external view returns (uint256);

    function protocolPaused() external view returns (bool);

    function stakerCooldownPeriod() external view returns (uint256);

    function lpCooldownPeriod() external view returns (uint256);

    function stakerUnstakeWindow() external view returns (uint256);

    function lpWithdrawWindow() external view returns (uint256);

    function oracleFor(address) external view returns (address);

    function validSubFactories(address, address) external view returns (bool);

    function setStakerCooldownPeriod(uint256) external;

    function setLpCooldownPeriod(uint256) external;

    function setStakerUnstakeWindow(uint256) external;

    function setLpWithdrawWindow(uint256) external;

    function setMaxSwapSlippage(uint256) external;

    function setGlobalAdmin(address) external;

    function setValidBalancerPool(address, bool) external;

    function setProtocolPause(bool) external;

    function setValidPoolFactory(address, bool) external;

    function setValidLoanFactory(address, bool) external;

    function setValidSubFactory(address, address, bool) external;

    function setDefaultUniswapPath(address, address, address) external;

    function setPoolDelegateAllowlist(address, bool) external;

    function setCollateralAsset(address, bool) external;

    function setLiquidityAsset(address, bool) external;

    function setCalc(address, bool) external;

    function setInvestorFee(uint256) external;

    function setTreasuryFee(uint256) external;

    function setMapleTreasury(address) external;

    function setDefaultGracePeriod(uint256) external;

    function setMinLoanEquity(uint256) external;

    function setFundingPeriod(uint256) external;

    function setSwapOutRequired(uint256) external;

    function setPriceOracle(address, address) external;

    function setPendingGovernor(address) external;

    function acceptGovernor() external;

}

////// contracts/token/interfaces/IExtendedFDT.sol
/* pragma solidity 0.6.11; */

/* import "./IBasicFDT.sol"; */

interface IExtendedFDT is IBasicFDT {

    event LossesPerShareUpdated(uint256);

    event LossesCorrectionUpdated(address indexed, int256);

    event LossesDistributed(address indexed, uint256);

    event LossesRecognized(address indexed, uint256, uint256);

    function lossesPerShare() external view returns (uint256);

    function recognizableLossesOf(address) external view returns (uint256);

    function recognizedLossesOf(address) external view returns (uint256);

    function accumulativeLossesOf(address) external view returns (uint256);

    function updateLossesReceived() external;

}

////// contracts/token/interfaces/IStakeLockerFDT.sol
/* pragma solidity 0.6.11; */

/* import "./IExtendedFDT.sol"; */

interface IStakeLockerFDT is IExtendedFDT {

    function fundsToken() external view returns (address);

    function fundsTokenBalance() external view returns (uint256);

    function bptLosses() external view returns (uint256);

    function lossesBalance() external view returns (uint256);

}

////// contracts/interfaces/IStakeLocker.sol
/* pragma solidity 0.6.11; */

/* import "../token/interfaces/IStakeLockerFDT.sol"; */

interface IStakeLocker is IStakeLockerFDT {

    function stakeDate(address) external returns (uint256);

    function stake(uint256) external;

    function unstake(uint256) external;

    function pull(address, uint256) external;

    function setAllowlist(address, bool) external;

    function openStakeLockerToPublic() external;

    function openToPublic() external view returns (bool);

    function allowed(address) external view returns (bool);

    function updateLosses(uint256) external;

    function intendToUnstake() external;

    function unstakeCooldown(address) external view returns (uint256);

    function lockupPeriod() external view returns (uint256);

    function stakeAsset() external view returns (address);

    function liquidityAsset() external view returns (address);

    function pool() external view returns (address);

    function setLockupPeriod(uint256) external;

    function cancelUnstake() external;

    function increaseCustodyAllowance(address, uint256) external;

    function transferByCustodian(address, address, uint256) external;

    function pause() external;

    function unpause() external;

    function isUnstakeAllowed(address) external view returns (bool);

    function isReceiveAllowed(uint256) external view returns (bool);

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
/* import "../interfaces/IMapleGlobals.sol"; */
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
    uint8   public constant DL_FACTORY  = 1;         // Factory type of DebtLockerFactory

    event         LoanFunded(address indexed loan, address debtLocker, uint256 amountFunded);
    event DepositDateUpdated(address indexed liquidityProvider, uint256 depositDate);

    /***************************************/
    /*** Pool Delegate Utility Functions ***/
    /***************************************/

    /** 
        @dev   Conducts sanity checks for Pools in the constructor.
        @param globals        Instance of a MapleGlobals.
        @param liquidityAsset Asset used by Pool for liquidity to fund loans.
        @param stakeAsset     Asset escrowed in StakeLocker.
        @param stakingFee     Fee that the Stakers earn on interest, in basis points.
        @param delegateFee    Fee that the Pool Delegate earns on interest, in basis points.
    */
    function poolSanityChecks(
        IMapleGlobals globals, 
        address liquidityAsset, 
        address stakeAsset, 
        uint256 stakingFee, 
        uint256 delegateFee
    ) external view {
        IBPool bPool = IBPool(stakeAsset);

        require(globals.isValidLiquidityAsset(liquidityAsset), "P:INVALID_LIQ_ASSET");
        require(stakingFee.add(delegateFee) <= 10_000,         "P:INVALID_FEES");
        require(
            globals.isValidBalancerPool(address(stakeAsset)) &&
            bPool.isBound(globals.mpl())                     && 
            bPool.isBound(liquidityAsset)                    &&
            bPool.isFinalized(), 
            "P:INVALID_BALANCER_POOL"
        );
    }

    /**
        @dev   Funds a Loan for an amount, utilizing the supplied DebtLockerFactory for DebtLockers.
        @dev   It emits a `LoanFunded` event.
        @param debtLockers     Mapping contains the DebtLocker contract address corresponding to the DebtLockerFactory and Loan.
        @param superFactory    Address of the PoolFactory.
        @param liquidityLocker Address of the LiquidityLocker contract attached with this Pool.
        @param loan            Address of the Loan to fund.
        @param dlFactory       The DebtLockerFactory to utilize.
        @param amt             Amount to fund the Loan.
    */
    function fundLoan(
        mapping(address => mapping(address => address)) storage debtLockers,
        address superFactory,
        address liquidityLocker,
        address loan,
        address dlFactory,
        uint256 amt
    ) external {
        IMapleGlobals globals = IMapleGlobals(ILoanFactory(superFactory).globals());
        address loanFactory   = ILoan(loan).superFactory();

        // Auth checks.
        require(globals.isValidLoanFactory(loanFactory),                        "P:INVALID_LF");
        require(ILoanFactory(loanFactory).isLoan(loan),                         "P:INVALID_L");
        require(globals.isValidSubFactory(superFactory, dlFactory, DL_FACTORY), "P:INVALID_DLF");

        address debtLocker = debtLockers[loan][dlFactory];

        // Instantiate DebtLocker if it doesn't exist withing this factory
        if (debtLocker == address(0)) {
            debtLocker = IDebtLockerFactory(dlFactory).newLocker(loan);
            debtLockers[loan][dlFactory] = debtLocker;
        }
    
        // Fund the Loan.
        ILiquidityLocker(liquidityLocker).fundLoan(loan, debtLocker, amt);
        
        emit LoanFunded(loan, debtLocker, amt);
    }

    /**
        @dev    Helper function used by Pool `claim` function, for when if a default has occurred.
        @param  liquidityAsset                  IERC20 of Liquidity Asset.
        @param  stakeLocker                     Address of StakeLocker.
        @param  stakeAsset                      Address of BPTs.
        @param  defaultSuffered                 Amount of shortfall in defaulted Loan after liquidation.
        @return bptsBurned                      Amount of BPTs burned to cover shortfall.
        @return postBurnBptBal                  Amount of BPTs returned to StakeLocker after burn.
        @return liquidityAssetRecoveredFromBurn Amount of Liquidity Asset recovered from burn.
    */
    function handleDefault(
        IERC20  liquidityAsset,
        address stakeLocker,
        address stakeAsset,
        uint256 defaultSuffered
    ) 
        external
        returns (
            uint256 bptsBurned,
            uint256 postBurnBptBal,
            uint256 liquidityAssetRecoveredFromBurn
        ) 
    {

        IBPool bPool = IBPool(stakeAsset);  // stakeAsset = Balancer Pool Tokens

        // Check amount of Liquidity Asset coverage that exists in the StakeLocker.
        uint256 availableSwapOut = getSwapOutValueLocker(stakeAsset, address(liquidityAsset), stakeLocker);

        // Pull BPTs from StakeLocker.
        IStakeLocker(stakeLocker).pull(address(this), bPool.balanceOf(stakeLocker));

        // To maintain accounting, account for direct transfers into Pool.
        uint256 preBurnLiquidityAssetBal = liquidityAsset.balanceOf(address(this));
        uint256 preBurnBptBal            = bPool.balanceOf(address(this));

        // Burn enough BPTs for Liquidity Asset to cover default suffered.
        bPool.exitswapExternAmountOut(
            address(liquidityAsset), 
            availableSwapOut >= defaultSuffered ? defaultSuffered : availableSwapOut,  // Burn BPTs up to defaultSuffered amount
            preBurnBptBal
        );

        // Return remaining BPTs to StakeLocker.
        postBurnBptBal = bPool.balanceOf(address(this));
        bptsBurned     = preBurnBptBal.sub(postBurnBptBal);
        bPool.transfer(stakeLocker, postBurnBptBal);
        liquidityAssetRecoveredFromBurn = liquidityAsset.balanceOf(address(this)).sub(preBurnLiquidityAssetBal);
        IStakeLocker(stakeLocker).updateLosses(bptsBurned);  // Update StakeLockerFDT loss accounting for BPTs
    }

    /**
        @dev    Calculates portions of claim from DebtLocker to be used by Pool `claim` function.
        @param  claimInfo           [0] = Total Claimed
                                    [1] = Interest Claimed
                                    [2] = Principal Claimed
                                    [3] = Fee Claimed
                                    [4] = Excess Returned Claimed
                                    [5] = Amount Recovered (from Liquidation)
                                    [6] = Default Suffered
        @param  delegateFee         Portion of interest (basis points) that goes to the Pool Delegate.
        @param  stakingFee          Portion of interest (basis points) that goes to the StakeLocker.
        @return poolDelegatePortion Total funds to send to the Pool Delegate.
        @return stakeLockerPortion  Total funds to send to the StakeLocker.
        @return principalClaim      Total principal claim.
        @return interestClaim       Total interest claim.
    */
    function calculateClaimAndPortions(
        uint256[7] calldata claimInfo,
        uint256 delegateFee,
        uint256 stakingFee
    ) 
        external
        pure
        returns (
            uint256 poolDelegatePortion,
            uint256 stakeLockerPortion,
            uint256 principalClaim,
            uint256 interestClaim
        ) 
    { 
        poolDelegatePortion = claimInfo[1].mul(delegateFee).div(10_000).add(claimInfo[3]);  // Pool Delegate portion of interest plus fee.
        stakeLockerPortion  = claimInfo[1].mul(stakingFee).div(10_000);                     // StakeLocker portion of interest.

        principalClaim = claimInfo[2].add(claimInfo[4]).add(claimInfo[5]);                                     // principal + excess + amountRecovered
        interestClaim  = claimInfo[1].sub(claimInfo[1].mul(delegateFee).div(10_000)).sub(stakeLockerPortion);  // leftover interest
    }

    /**
        @dev   Checks that the deactivation is allowed.
        @param globals        Instance of a MapleGlobals.
        @param principalOut   Amount of funds that are already funded to Loans.
        @param liquidityAsset Liquidity Asset of the Pool.
    */
    function validateDeactivation(IMapleGlobals globals, uint256 principalOut, address liquidityAsset) external view {
        require(principalOut <= _convertFromUsd(globals, liquidityAsset, 100), "P:PRINCIPAL_OUTSTANDING");
    }

    /********************************************/
    /*** Liquidity Provider Utility Functions ***/
    /********************************************/

    /**
        @dev   Updates the effective deposit date based on how much new capital has been added.
               If more capital is added, the deposit date moves closer to the current timestamp.
        @dev   It emits a `DepositDateUpdated` event.
        @param amt     Total deposit amount.
        @param account Address of account depositing.
    */
    function updateDepositDate(mapping(address => uint256) storage depositDate, uint256 balance, uint256 amt, address account) internal {
        uint256 prevDate = depositDate[account];

        // prevDate + (now - prevDate) * (amt / (balance + amt))
        // NOTE: prevDate = 0 implies balance = 0, and equation reduces to now
        uint256 newDate = (balance + amt) > 0
            ? prevDate.add(block.timestamp.sub(prevDate).mul(amt).div(balance + amt))
            : prevDate;

        depositDate[account] = newDate;
        emit DepositDateUpdated(account, newDate);
    }

    /**
        @dev Performs all necessary checks for a `transferByCustodian` call.
        @dev From and to must always be equal.
    */
    function transferByCustodianChecks(address from, address to, uint256 amount) external pure {
        require(to == from,                 "P:INVALID_RECEIVER");
        require(amount != uint256(0),       "P:INVALID_AMT");
    }

    /**
        @dev Performs all necessary checks for an `increaseCustodyAllowance` call.
    */
    function increaseCustodyAllowanceChecks(address custodian, uint256 amount, uint256 newTotalAllowance, uint256 fdtBal) external pure {
        require(custodian != address(0),     "P:INVALID_CUSTODIAN");
        require(amount    != uint256(0),     "P:INVALID_AMT");
        require(newTotalAllowance <= fdtBal, "P:INSUF_BALANCE");
    }

    /**********************************/
    /*** Governor Utility Functions ***/
    /**********************************/

    /**
        @dev   Transfers any locked funds to the Governor. Only the Governor can call this function.
        @param token          Address of the token to be reclaimed.
        @param liquidityAsset Address of Liquidity Asset that is supported by the Pool.
        @param globals        Instance of a MapleGlobals.
    */
    function reclaimERC20(address token, address liquidityAsset, IMapleGlobals globals) external {
        require(msg.sender == globals.governor(), "P:NOT_GOV");
        require(token != liquidityAsset && token != address(0), "P:INVALID_TOKEN");
        IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    /************************/
    /*** Getter Functions ***/
    /************************/

    /**
        @dev Official Balancer pool bdiv() function. Does synthetic float with 10^-18 precision.
    */
    function _bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "P:DIV_ZERO");
        uint256 c0 = a * WAD;
        require(a == 0 || c0 / a == WAD, "P:DIV_INTERNAL");  // bmul overflow
        uint256 c1 = c0 + (b / 2);
        require(c1 >= c0, "P:DIV_INTERNAL");  //  badd require
        return c1 / b;
    }

    /**
        @dev    Calculates the value of BPT in units of Liquidity Asset.
        @dev    Vulnerable to flash-loan attacks where the attacker can artificially inflate the BPT price by swapping a large amount
                of Liquidity Asset into the Pool and swapping back after this function is called.
        @param  _bPool         Address of Balancer pool.
        @param  liquidityAsset Asset used by Pool for liquidity to fund Loans.
        @param  staker         Address that deposited BPTs to StakeLocker.
        @param  stakeLocker    Escrows BPTs deposited by Staker.
        @return USDC value of Staker BPTs.
    */
    function BPTVal(
        address _bPool,
        address liquidityAsset,
        address staker,
        address stakeLocker
    ) external view returns (uint256) {
        IBPool bPool = IBPool(_bPool);

        // StakeLockerFDTs are minted 1:1 (in wei) in the StakeLocker when staking BPTs, thus representing stake amount.
        // These are burned when withdrawing staked BPTs, thus representing the current stake amount.
        uint256 amountStakedBPT       = IERC20(stakeLocker).balanceOf(staker);
        uint256 totalSupplyBPT        = IERC20(_bPool).totalSupply();
        uint256 liquidityAssetBalance = bPool.getBalance(liquidityAsset);
        uint256 liquidityAssetWeight  = bPool.getNormalizedWeight(liquidityAsset);

        // liquidityAsset value = (amountStaked/totalSupply) * (liquidityAssetBalance/liquidityAssetWeight)
        return _bdiv(amountStakedBPT, totalSupplyBPT).mul(_bdiv(liquidityAssetBalance, liquidityAssetWeight)).div(WAD);
    }

    /** 
        @dev    Calculates Liquidity Asset swap out value of staker BPT balance escrowed in StakeLocker.
        @param  _bPool         Balancer pool that issues the BPTs.
        @param  liquidityAsset Swap out asset (e.g. USDC) to receive when burning BPTs.
        @param  staker         Address that deposited BPTs to StakeLocker.
        @param  stakeLocker    Escrows BPTs deposited by Staker.
        @return liquidityAsset Swap out value of staker BPTs.
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
        @dev    Calculates Liquidity Asset swap out value of entire BPT balance escrowed in StakeLocker.
        @param  _bPool         Balancer pool that issues the BPTs.
        @param  liquidityAsset Swap out asset (e.g. USDC) to receive when burning BPTs.
        @param  stakeLocker    Escrows BPTs deposited by Staker.
        @return liquidityAsset Swap out value of StakeLocker BPTs.
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
        // Fetch Balancer pool token information
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

        // Max amount that can be swapped based on amount of liquidityAsset in the Balancer Pool
        uint256 maxSwapOut = tokenBalanceOut.mul(bPool.MAX_OUT_RATIO()).div(WAD);  

        return tokenAmountOut <= maxSwapOut ? tokenAmountOut : maxSwapOut;
    }

    /**
        @dev    Calculates BPTs required if burning BPTs for liquidityAsset, given supplied tokenAmountOutRequired.
        @dev    Vulnerable to flash-loan attacks where the attacker can artificially inflate the BPT price by swapping a large amount
                of liquidityAsset into the pool and swapping back after this function is called.
        @param  _bPool                       Balancer pool that issues the BPTs.
        @param  liquidityAsset               Swap out asset (e.g. USDC) to receive when burning BPTs.
        @param  staker                       Address that deposited BPTs to stakeLocker.
        @param  stakeLocker                  Escrows BPTs deposited by staker.
        @param  liquidityAssetAmountRequired Amount of liquidityAsset required to recover.
        @return poolAmountInRequired         poolAmountIn required.
        @return stakerBalance                poolAmountIn currently staked.
    */
    function getPoolSharesRequired(
        address _bPool,
        address liquidityAsset,
        address staker,
        address stakeLocker,
        uint256 liquidityAssetAmountRequired
    ) public view returns (uint256 poolAmountInRequired, uint256 stakerBalance) {
        // Fetch Balancer pool token information.
        IBPool bPool = IBPool(_bPool);

        uint256 tokenBalanceOut = bPool.getBalance(liquidityAsset);
        uint256 tokenWeightOut  = bPool.getDenormalizedWeight(liquidityAsset);
        uint256 poolSupply      = bPool.totalSupply();
        uint256 totalWeight     = bPool.getTotalDenormalizedWeight();
        uint256 swapFee         = bPool.getSwapFee();

        // Fetch amount of BPTs required to burn to receive Liquidity Asset amount required.
        poolAmountInRequired = bPool.calcPoolInGivenSingleOut(
            tokenBalanceOut,
            tokenWeightOut,
            poolSupply,
            totalWeight,
            liquidityAssetAmountRequired,
            swapFee
        );

        // Fetch amount staked in StakeLocker by Staker.
        stakerBalance = IERC20(stakeLocker).balanceOf(staker);
    }

    /**
        @dev    Returns information on the stake requirements.
        @param  globals                    Instance of a MapleGlobals.
        @param  balancerPool               Address of Balancer pool.
        @param  liquidityAsset             Address of Liquidity Asset, to be returned from swap out.
        @param  poolDelegate               Address of Pool Delegate.
        @param  stakeLocker                Address of StakeLocker.
        @return swapOutAmountRequired      Min amount of Liquidity Asset coverage from staking required (in Liquidity Asset units).
        @return currentPoolDelegateCover   Present amount of Liquidity Asset coverage from Pool Delegate stake (in Liquidity Asset units).
        @return enoughStakeForFinalization If enough stake is present from Pool Delegate for Pool finalization.
        @return poolAmountInRequired       BPTs required for minimum Liquidity Asset coverage.
        @return poolAmountPresent          Current staked BPTs.
    */
    function getInitialStakeRequirements(IMapleGlobals globals, address balancerPool, address liquidityAsset, address poolDelegate, address stakeLocker) external view returns (
        uint256 swapOutAmountRequired,
        uint256 currentPoolDelegateCover,
        bool    enoughStakeForFinalization,
        uint256 poolAmountInRequired,
        uint256 poolAmountPresent
    ) {
        swapOutAmountRequired = _convertFromUsd(globals, liquidityAsset, globals.swapOutRequired());
        (
            poolAmountInRequired,
            poolAmountPresent
        ) = getPoolSharesRequired(balancerPool, liquidityAsset, poolDelegate, stakeLocker, swapOutAmountRequired);

        currentPoolDelegateCover   = getSwapOutValue(balancerPool, liquidityAsset, poolDelegate, stakeLocker);
        enoughStakeForFinalization = poolAmountPresent >= poolAmountInRequired;
    }

    /************************/
    /*** Helper Functions ***/
    /************************/

    /**
        @dev   Converts from WAD precision to Liquidity Asset precision.
        @param amt                    Amount to convert.
        @param liquidityAssetDecimals Liquidity Asset decimal.
    */
    function fromWad(uint256 amt, uint256 liquidityAssetDecimals) external pure returns (uint256) {
        return amt.mul(10 ** liquidityAssetDecimals).div(WAD);
    }

    /** 
        @dev    Returns Liquidity Asset in Liquidity Asset units when given integer USD (E.g., $100 = 100).
        @param  globals        Instance of a MapleGlobals.
        @param  liquidityAsset Liquidity Asset of the pool.
        @param  usdAmount      USD amount to convert, in integer units (e.g., $100 = 100).
        @return usdAmount worth of Liquidity Asset, in Liquidity Asset units.
    */
    function _convertFromUsd(IMapleGlobals globals, address liquidityAsset, uint256 usdAmount) internal view returns (uint256) {
        return usdAmount
            .mul(10 ** 8)                                         // Cancel out 10 ** 8 decimals from oracle.
            .mul(10 ** IERC20Details(liquidityAsset).decimals())  // Convert to Liquidity Asset precision.
            .div(globals.getLatestPrice(liquidityAsset));         // Convert to Liquidity Asset value.
    }
}