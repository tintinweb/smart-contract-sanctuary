/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

// SPDX-License-Identifier:  AGPL-3.0-or-later // hevm: flattened sources of contracts/Pool.sol
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

    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external;

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

////// contracts/interfaces/IDebtLocker.sol
/* pragma solidity 0.6.11; */

interface IDebtLocker {

    function loan() external view returns (address);

    function liquidityAsset() external view returns (address);

    function pool() external view returns (address);

    function lastPrincipalPaid() external view returns (uint256);

    function lastInterestPaid() external view returns (uint256);

    function lastFeePaid() external view returns (uint256);

    function lastExcessReturned() external view returns (uint256);

    function lastDefaultSuffered() external view returns (uint256);

    function lastAmountRecovered() external view returns (uint256);

    function claim() external returns (uint256[7] memory);
    
    function triggerDefault() external;

}

////// contracts/interfaces/ILiquidityLocker.sol
/* pragma solidity 0.6.11; */

interface ILiquidityLocker {

    function pool() external view returns (address);

    function liquidityAsset() external view returns (address);

    function transfer(address, uint256) external;

    function fundLoan(address, address, uint256) external;

}

////// contracts/interfaces/ILiquidityLockerFactory.sol
/* pragma solidity 0.6.11; */

interface ILiquidityLockerFactory {

    function owner(address) external view returns (address);
    
    function isLocker(address) external view returns (bool);

    function factoryType() external view returns (uint8);

    function newLocker(address) external returns (address);

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

////// contracts/interfaces/IPoolFactory.sol
/* pragma solidity 0.6.11; */

interface IPoolFactory {

    function LL_FACTORY() external view returns (uint8);

    function SL_FACTORY() external view returns (uint8);

    function poolsCreated() external view returns (uint256);

    function globals() external view returns (address);

    function pools(uint256) external view returns (address);

    function isPool(address) external view returns (bool);

    function poolFactoryAdmins(address) external view returns (bool);

    function setGlobals(address) external;

    function createPool(address, address, address, address, uint256, uint256, uint256) external returns (address);

    function setPoolFactoryAdmin(address, bool) external;

    function pause() external;

    function unpause() external;

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

////// contracts/interfaces/IStakeLockerFactory.sol
/* pragma solidity 0.6.11; */

interface IStakeLockerFactory {

    function owner(address) external returns (address);

    function isLocker(address) external returns (bool);

    function factoryType() external returns (uint8);

    function newLocker(address, address) external returns (address);

}

////// contracts/interfaces/IDebtLockerFactory.sol
/* pragma solidity 0.6.11; */

interface IDebtLockerFactory {

    function owner(address) external view returns (address);

    function isLocker(address) external view returns (bool);

    function factoryType() external view returns (uint8);

    function newLocker(address) external returns (address);

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

////// contracts/math/SafeMathInt.sol
/* pragma solidity 0.6.11; */

library SafeMathInt {
    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0, "SMI:NEG");
        return uint256(a);
    }
}

////// contracts/math/SafeMathUint.sol
/* pragma solidity 0.6.11; */

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256 b) {
        b = int256(a);
        require(b >= 0, "SMU:OOB");
    }
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
/* import "./interfaces/IBaseFDT.sol"; */
/* import "../math/SafeMathUint.sol"; */
/* import "../math/SafeMathInt.sol"; */

/// @title BasicFDT implements base level FDT functionality for accounting for revenues.
abstract contract BasicFDT is IBaseFDT, ERC20 {
    using SafeMath       for uint256;
    using SafeMathUint   for uint256;
    using SignedSafeMath for  int256;
    using SafeMathInt    for  int256;

    uint256 internal constant pointsMultiplier = 2 ** 128;
    uint256 internal pointsPerShare;

    mapping(address => int256)  internal pointsCorrection;
    mapping(address => uint256) internal withdrawnFunds;

    event   PointsPerShareUpdated(uint256 pointsPerShare);
    event PointsCorrectionUpdated(address indexed account, int256 pointsCorrection);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) public { }

    /**
        @dev Distributes funds to token holders.
        @dev It reverts if the total supply of tokens is 0.
        @dev It emits a `FundsDistributed` event if the amount of received funds is greater than 0.
        @dev It emits a `PointsPerShareUpdated` event if the amount of received funds is greater than 0.
             About undistributed funds:
                In each distribution, there is a small amount of funds which do not get distributed,
                   which is `(value  pointsMultiplier) % totalSupply()`.
                With a well-chosen `pointsMultiplier`, the amount funds that are not getting distributed
                   in a distribution can be less than 1 (base unit).
                We can actually keep track of the undistributed funds in a distribution
                   and try to distribute it in the next distribution.
    */
    function _distributeFunds(uint256 value) internal {
        require(totalSupply() > 0, "FDT:ZERO_SUPPLY");

        if (value == 0) return;

        pointsPerShare = pointsPerShare.add(value.mul(pointsMultiplier) / totalSupply());
        emit FundsDistributed(msg.sender, value);
        emit PointsPerShareUpdated(pointsPerShare);
    }

    /**
        @dev    Prepares the withdrawal of funds.
        @dev    It emits a `FundsWithdrawn` event if the amount of withdrawn funds is greater than 0.
        @return withdrawableDividend The amount of dividend funds that can be withdrawn.
    */
    function _prepareWithdraw() internal returns (uint256 withdrawableDividend) {
        withdrawableDividend       = withdrawableFundsOf(msg.sender);
        uint256 _withdrawnFunds    = withdrawnFunds[msg.sender].add(withdrawableDividend);
        withdrawnFunds[msg.sender] = _withdrawnFunds;

        emit FundsWithdrawn(msg.sender, withdrawableDividend, _withdrawnFunds);
    }

    /**
        @dev    Returns the amount of funds that an account can withdraw.
        @param  _owner The address of a token holder.
        @return The amount funds that `_owner` can withdraw.
    */
    function withdrawableFundsOf(address _owner) public view override returns (uint256) {
        return accumulativeFundsOf(_owner).sub(withdrawnFunds[_owner]);
    }

    /**
        @dev    Returns the amount of funds that an account has withdrawn.
        @param  _owner The address of a token holder.
        @return The amount of funds that `_owner` has withdrawn.
    */
    function withdrawnFundsOf(address _owner) external view returns (uint256) {
        return withdrawnFunds[_owner];
    }

    /**
        @dev    Returns the amount of funds that an account has earned in total.
        @dev    accumulativeFundsOf(_owner) = withdrawableFundsOf(_owner) + withdrawnFundsOf(_owner)
                                         = (pointsPerShare * balanceOf(_owner) + pointsCorrection[_owner]) / pointsMultiplier
        @param  _owner The address of a token holder.
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
        @dev   Transfers tokens from one account to another. Updates pointsCorrection to keep funds unchanged.
        @dev   It emits two `PointsCorrectionUpdated` events, one for the sender and one for the receiver.
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

        int256 _magCorrection       = pointsPerShare.mul(value).toInt256Safe();
        int256 pointsCorrectionFrom = pointsCorrection[from].add(_magCorrection);
        pointsCorrection[from]      = pointsCorrectionFrom;
        int256 pointsCorrectionTo   = pointsCorrection[to].sub(_magCorrection);
        pointsCorrection[to]        = pointsCorrectionTo;

        emit PointsCorrectionUpdated(from, pointsCorrectionFrom);
        emit PointsCorrectionUpdated(to,   pointsCorrectionTo);
    }

    /**
        @dev   Mints tokens to an account. Updates pointsCorrection to keep funds unchanged.
        @param account The account that will receive the created tokens.
        @param value   The amount that will be created.
    */
    function _mint(address account, uint256 value) internal virtual override {
        super._mint(account, value);

        int256 _pointsCorrection = pointsCorrection[account].sub(
            (pointsPerShare.mul(value)).toInt256Safe()
        );

        pointsCorrection[account] = _pointsCorrection;

        emit PointsCorrectionUpdated(account, _pointsCorrection);
    }

    /**
        @dev   Burns an amount of the token of a given account. Updates pointsCorrection to keep funds unchanged.
        @dev   It emits a `PointsCorrectionUpdated` event.
        @param account The account whose tokens will be burnt.
        @param value   The amount that will be burnt.
    */
    function _burn(address account, uint256 value) internal virtual override {
        super._burn(account, value);

        int256 _pointsCorrection = pointsCorrection[account].add(
            (pointsPerShare.mul(value)).toInt256Safe()
        );

        pointsCorrection[account] = _pointsCorrection;

        emit PointsCorrectionUpdated(account, _pointsCorrection);
    }

    /**
        @dev Withdraws all available funds for a token holder.
    */
    function withdrawFunds() public virtual override {}

    /**
        @dev    Updates the current `fundsToken` balance and returns the difference of the new and previous `fundsToken` balance.
        @return A int256 representing the difference of the new and previous `fundsToken` balance.
    */
    function _updateFundsTokenBalance() internal virtual returns (int256) {}

    /**
        @dev Registers a payment of funds in tokens. May be called directly after a deposit is made.
        @dev Calls _updateFundsTokenBalance(), whereby the contract computes the delta of the new and previous
             `fundsToken` balance and increments the total received funds (cumulative), by delta, by calling _distributeFunds().
    */
    function updateFundsReceived() public virtual {
        int256 newFunds = _updateFundsTokenBalance();

        if (newFunds <= 0) return;

        _distributeFunds(newFunds.toUint256Safe());
    }
}

////// contracts/token/ExtendedFDT.sol
/* pragma solidity 0.6.11; */

/* import "./BasicFDT.sol"; */

/// @title ExtendedFDT implements FDT functionality for accounting for losses.
abstract contract ExtendedFDT is BasicFDT {
    using SafeMath       for uint256;
    using SafeMathUint   for uint256;
    using SignedSafeMath for  int256;
    using SafeMathInt    for  int256;

    uint256 internal lossesPerShare;

    mapping(address => int256)  internal lossesCorrection;
    mapping(address => uint256) internal recognizedLosses;

    event   LossesPerShareUpdated(uint256 lossesPerShare);
    event LossesCorrectionUpdated(address indexed account, int256 lossesCorrection);

    /**
        @dev   This event emits when new losses are distributed.
        @param by                The address of the account that has distributed losses.
        @param lossesDistributed The amount of losses received for distribution.
    */
    event LossesDistributed(address indexed by, uint256 lossesDistributed);

    /**
        @dev   This event emits when distributed losses are recognized by a token holder.
        @param by                    The address of the receiver of losses.
        @param lossesRecognized      The amount of losses that were recognized.
        @param totalLossesRecognized The total amount of losses that are recognized.
    */
    event LossesRecognized(address indexed by, uint256 lossesRecognized, uint256 totalLossesRecognized);

    constructor(string memory name, string memory symbol) BasicFDT(name, symbol) public { }

    /**
        @dev Distributes losses to token holders.
        @dev It reverts if the total supply of tokens is 0.
        @dev It emits a `LossesDistributed` event if the amount of received losses is greater than 0.
        @dev It emits a `LossesPerShareUpdated` event if the amount of received losses is greater than 0.
             About undistributed losses:
                In each distribution, there is a small amount of losses which do not get distributed,
                which is `(value * pointsMultiplier) % totalSupply()`.
             With a well-chosen `pointsMultiplier`, the amount losses that are not getting distributed
                in a distribution can be less than 1 (base unit).
             We can actually keep track of the undistributed losses in a distribution
                and try to distribute it in the next distribution.
    */
    function _distributeLosses(uint256 value) internal {
        require(totalSupply() > 0, "FDT:ZERO_SUPPLY");

        if (value == 0) return;

        uint256 _lossesPerShare = lossesPerShare.add(value.mul(pointsMultiplier) / totalSupply());
        lossesPerShare          = _lossesPerShare;

        emit LossesDistributed(msg.sender, value);
        emit LossesPerShareUpdated(_lossesPerShare);
    }

    /**
        @dev    Prepares losses for a withdrawal.
        @dev    It emits a `LossesWithdrawn` event if the amount of withdrawn losses is greater than 0.
        @return recognizableDividend The amount of dividend losses that can be recognized.
    */
    function _prepareLossesWithdraw() internal returns (uint256 recognizableDividend) {
        recognizableDividend = recognizableLossesOf(msg.sender);

        uint256 _recognizedLosses    = recognizedLosses[msg.sender].add(recognizableDividend);
        recognizedLosses[msg.sender] = _recognizedLosses;

        emit LossesRecognized(msg.sender, recognizableDividend, _recognizedLosses);
    }

    /**
        @dev    Returns the amount of losses that an address can withdraw.
        @param  _owner The address of a token holder.
        @return The amount of losses that `_owner` can withdraw.
    */
    function recognizableLossesOf(address _owner) public view returns (uint256) {
        return accumulativeLossesOf(_owner).sub(recognizedLosses[_owner]);
    }

    /**
        @dev    Returns the amount of losses that an address has recognized.
        @param  _owner The address of a token holder
        @return The amount of losses that `_owner` has recognized
    */
    function recognizedLossesOf(address _owner) external view returns (uint256) {
        return recognizedLosses[_owner];
    }

    /**
        @dev    Returns the amount of losses that an address has earned in total.
        @dev    accumulativeLossesOf(_owner) = recognizableLossesOf(_owner) + recognizedLossesOf(_owner)
                = (lossesPerShare * balanceOf(_owner) + lossesCorrection[_owner]) / pointsMultiplier
        @param  _owner The address of a token holder
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
        @dev   Transfers tokens from one account to another. Updates pointsCorrection to keep funds unchanged.
        @dev         It emits two `LossesCorrectionUpdated` events, one for the sender and one for the receiver.
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

        int256 _lossesCorrection    = lossesPerShare.mul(value).toInt256Safe();
        int256 lossesCorrectionFrom = lossesCorrection[from].add(_lossesCorrection);
        lossesCorrection[from]      = lossesCorrectionFrom;
        int256 lossesCorrectionTo   = lossesCorrection[to].sub(_lossesCorrection);
        lossesCorrection[to]        = lossesCorrectionTo;

        emit LossesCorrectionUpdated(from, lossesCorrectionFrom);
        emit LossesCorrectionUpdated(to,   lossesCorrectionTo);
    }

    /**
        @dev   Mints tokens to an account. Updates lossesCorrection to keep losses unchanged.
        @dev   It emits a `LossesCorrectionUpdated` event.
        @param account The account that will receive the created tokens.
        @param value   The amount that will be created.
    */
    function _mint(address account, uint256 value) internal virtual override {
        super._mint(account, value);

        int256 _lossesCorrection = lossesCorrection[account].sub(
            (lossesPerShare.mul(value)).toInt256Safe()
        );

        lossesCorrection[account] = _lossesCorrection;

        emit LossesCorrectionUpdated(account, _lossesCorrection);
    }

    /**
        @dev   Burns an amount of the token of a given account. Updates lossesCorrection to keep losses unchanged.
        @dev   It emits a `LossesCorrectionUpdated` event.
        @param account The account from which tokens will be burnt.
        @param value   The amount that will be burnt.
    */
    function _burn(address account, uint256 value) internal virtual override {
        super._burn(account, value);

        int256 _lossesCorrection = lossesCorrection[account].add(
            (lossesPerShare.mul(value)).toInt256Safe()
        );

        lossesCorrection[account] = _lossesCorrection;

        emit LossesCorrectionUpdated(account, _lossesCorrection);
    }

    /**
        @dev Registers a loss. May be called directly after a shortfall after BPT burning occurs.
        @dev Calls _updateLossesTokenBalance(), whereby the contract computes the delta of the new and previous
             losses balance and increments the total losses (cumulative), by delta, by calling _distributeLosses().
    */
    function updateLossesReceived() public virtual {
        int256 newLosses = _updateLossesBalance();

        if (newLosses <= 0) return;

        _distributeLosses(newLosses.toUint256Safe());
    }

    /**
        @dev Recognizes all recognizable losses for an account using loss accounting.
    */
    function _recognizeLosses() internal virtual returns (uint256 losses) { }

    /**
        @dev    Updates the current losses balance and returns the difference of the new and previous losses balance.
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

    uint256 public interestSum;  // Sum of all withdrawable interest.
    uint256 public poolLosses;   // Sum of all unrecognized losses.

    uint256 public interestBalance;  // The amount of earned interest present and accounted for in this contract.
    uint256 public lossesBalance;    // The amount of losses present and accounted for in this contract.

    constructor(string memory name, string memory symbol) ExtendedFDT(name, symbol) public { }

    /**
        @dev Realizes losses incurred to LPs.
    */
    function _recognizeLosses() internal override returns (uint256 losses) {
        losses = _prepareLossesWithdraw();

        poolLosses = poolLosses.sub(losses);

        _updateLossesBalance();
    }

    /**
        @dev    Updates the current losses balance and returns the difference of the new and previous losses balance.
        @return A int256 representing the difference of the new and previous losses balance.
    */
    function _updateLossesBalance() internal override returns (int256) {
        uint256 _prevLossesTokenBalance = lossesBalance;

        lossesBalance = poolLosses;

        return int256(lossesBalance).sub(int256(_prevLossesTokenBalance));
    }

    /**
        @dev    Updates the current interest balance and returns the difference of the new and previous interest balance.
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

/* import "lib/openzeppelin-contracts/contracts/token/ERC20/SafeERC20.sol"; */

/* import "./interfaces/IBPool.sol"; */
/* import "./interfaces/IDebtLocker.sol"; */
/* import "./interfaces/IMapleGlobals.sol"; */
/* import "./interfaces/ILiquidityLocker.sol"; */
/* import "./interfaces/ILiquidityLockerFactory.sol"; */
/* import "./interfaces/ILoan.sol"; */
/* import "./interfaces/ILoanFactory.sol"; */
/* import "./interfaces/IPoolFactory.sol"; */
/* import "./interfaces/IStakeLocker.sol"; */
/* import "./interfaces/IStakeLockerFactory.sol"; */

/* import "./library/PoolLib.sol"; */

/* import "./token/PoolFDT.sol"; */

/// @title Pool maintains all accounting and functionality related to Pools.
contract Pool is PoolFDT {

    using SafeMath  for uint256;
    using SafeERC20 for IERC20;

    uint256 constant WAD = 10 ** 18;

    uint8 public constant DL_FACTORY = 1;  // Factory type of `DebtLockerFactory`.

    IERC20  public immutable liquidityAsset;  // The asset deposited by Lenders into the LiquidityLocker, for funding Loans.

    address public immutable poolDelegate;     // The Pool Delegate address, maintains full authority over the Pool.
    address public immutable liquidityLocker;  // The LiquidityLocker owned by this contract
    address public immutable stakeAsset;       // The address of the asset deposited by Stakers into the StakeLocker (BPTs), for liquidation during default events.
    address public immutable stakeLocker;      // The address of the StakeLocker, escrowing `stakeAsset`.
    address public immutable superFactory;     // The factory that deployed this Loan.

    uint256 private immutable liquidityAssetDecimals;  // The precision for the Liquidity Asset (i.e. `decimals()`).

    uint256 public           stakingFee;   // The fee Stakers earn            (in basis points).
    uint256 public immutable delegateFee;  // The fee the Pool Delegate earns (in basis points).

    uint256 public principalOut;  // The sum of all outstanding principal on Loans.
    uint256 public liquidityCap;  // The amount of liquidity tokens accepted by the Pool.
    uint256 public lockupPeriod;  // The period of time from an account's deposit date during which they cannot withdraw any funds.

    bool public openToPublic;  // Boolean opening Pool to public for LP deposits

    enum State { Initialized, Finalized, Deactivated }
    State public poolState;

    mapping(address => uint256)                     public depositDate;                // Used for withdraw penalty calculation.
    mapping(address => mapping(address => address)) public debtLockers;                // Address of the DebtLocker corresponding to `[Loan][DebtLockerFactory]`.
    mapping(address => bool)                        public poolAdmins;                 // The Pool Admin addresses that have permission to do certain operations in case of disaster management.
    mapping(address => bool)                        public allowedLiquidityProviders;  // Mapping that contains the list of addresses that have early access to the pool.
    mapping(address => uint256)                     public withdrawCooldown;           // The timestamp of when individual LPs have notified of their intent to withdraw.
    mapping(address => mapping(address => uint256)) public custodyAllowance;           // The amount of PoolFDTs that are "locked" at a certain address.
    mapping(address => uint256)                     public totalCustodyAllowance;      // The total amount of PoolFDTs that are "locked" for a given account. Cannot be greater than an account's balance.

    event                   LoanFunded(address indexed loan, address debtLocker, uint256 amountFunded);
    event                        Claim(address indexed loan, uint256 interest, uint256 principal, uint256 fee, uint256 stakeLockerPortion, uint256 poolDelegatePortion);
    event               BalanceUpdated(address indexed liquidityProvider, address indexed token, uint256 balance);
    event              CustodyTransfer(address indexed custodian, address indexed from, address indexed to, uint256 amount);
    event      CustodyAllowanceChanged(address indexed liquidityProvider, address indexed custodian, uint256 oldAllowance, uint256 newAllowance);
    event              LPStatusChanged(address indexed liquidityProvider, bool status);
    event              LiquidityCapSet(uint256 newLiquidityCap);
    event              LockupPeriodSet(uint256 newLockupPeriod);
    event                StakingFeeSet(uint256 newStakingFee);
    event             PoolStateChanged(State state);
    event                     Cooldown(address indexed liquidityProvider, uint256 cooldown);
    event           PoolOpenedToPublic(bool isOpen);
    event                 PoolAdminSet(address indexed poolAdmin, bool allowed);
    event           DepositDateUpdated(address indexed liquidityProvider, uint256 depositDate);
    event TotalCustodyAllowanceUpdated(address indexed liquidityProvider, uint256 newTotalAllowance);
    
    event DefaultSuffered(
        address indexed loan,
        uint256 defaultSuffered,
        uint256 bptsBurned,
        uint256 bptsReturned,
        uint256 liquidityAssetRecoveredFromBurn
    );

    /**
        Universal accounting law:
                                       fdtTotalSupply = liquidityLockerBal + principalOut - interestSum + poolLosses
            fdtTotalSupply + interestSum - poolLosses = liquidityLockerBal + principalOut
    */

    /**
        @dev   Constructor for a Pool.
        @dev   It emits a `PoolStateChanged` event.
        @param _poolDelegate   Address that has manager privileges of the Pool.
        @param _liquidityAsset Asset used to fund the Pool, It gets escrowed in LiquidityLocker.
        @param _stakeAsset     Asset escrowed in StakeLocker.
        @param _slFactory      Factory used to instantiate the StakeLocker.
        @param _llFactory      Factory used to instantiate the LiquidityLocker.
        @param _stakingFee     Fee that Stakers earn on interest, in basis points.
        @param _delegateFee    Fee that the Pool Delegate earns on interest, in basis points.
        @param _liquidityCap   Max amount of Liquidity Asset accepted by the Pool.
        @param name            Name of Pool token.
        @param symbol          Symbol of Pool token.
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

        // Conduct sanity checks on Pool parameters.
        PoolLib.poolSanityChecks(_globals(msg.sender), _liquidityAsset, _stakeAsset, _stakingFee, _delegateFee);

        // Assign variables relating to the Liquidity Asset.
        liquidityAsset         = IERC20(_liquidityAsset);
        liquidityAssetDecimals = ERC20(_liquidityAsset).decimals();

        // Assign state variables.
        stakeAsset   = _stakeAsset;
        poolDelegate = _poolDelegate;
        stakingFee   = _stakingFee;
        delegateFee  = _delegateFee;
        superFactory = msg.sender;
        liquidityCap = _liquidityCap;

        // Instantiate the LiquidityLocker and the StakeLocker.
        stakeLocker     = address(IStakeLockerFactory(_slFactory).newLocker(_stakeAsset, _liquidityAsset));
        liquidityLocker = address(ILiquidityLockerFactory(_llFactory).newLocker(_liquidityAsset));

        lockupPeriod = 180 days;

        emit PoolStateChanged(State.Initialized);
    }

    /*******************************/
    /*** Pool Delegate Functions ***/
    /*******************************/

    /**
        @dev Finalizes the Pool, enabling deposits. Checks the amount the Pool Delegate deposited to the StakeLocker.
             Only the Pool Delegate can call this function.
        @dev It emits a `PoolStateChanged` event.
    */
    function finalize() external {
        _isValidDelegateAndProtocolNotPaused();
        _isValidState(State.Initialized);
        (,, bool stakeSufficient,,) = getInitialStakeRequirements();
        require(stakeSufficient, "P:INSUF_STAKE");
        poolState = State.Finalized;
        emit PoolStateChanged(poolState);
    }

    /**
        @dev   Funds a Loan for an amount, utilizing the supplied DebtLockerFactory for DebtLockers.
               Only the Pool Delegate can call this function.
        @dev   It emits a `LoanFunded` event.
        @dev   It emits a `BalanceUpdated` event.
        @param loan      Address of the Loan to fund.
        @param dlFactory Address of the DebtLockerFactory to utilize.
        @param amt       Amount to fund the Loan.
    */
    function fundLoan(address loan, address dlFactory, uint256 amt) external {
        _isValidDelegateAndProtocolNotPaused();
        _isValidState(State.Finalized);
        principalOut = principalOut.add(amt);
        PoolLib.fundLoan(debtLockers, superFactory, liquidityLocker, loan, dlFactory, amt);
        _emitBalanceUpdatedEvent();
    }

    /**
        @dev   Liquidates a Loan. The Pool Delegate could liquidate the Loan only when the Loan completes its grace period.
               The Pool Delegate can claim its proportion of recovered funds from the liquidation using the `claim()` function.
               Only the Pool Delegate can call this function.
        @param loan      Address of the Loan to liquidate.
        @param dlFactory Address of the DebtLockerFactory that is used to pull corresponding DebtLocker.
    */
    function triggerDefault(address loan, address dlFactory) external {
        _isValidDelegateAndProtocolNotPaused();
        IDebtLocker(debtLockers[loan][dlFactory]).triggerDefault();
    }

    /**
        @dev    Claims available funds for the Loan through a specified DebtLockerFactory. Only the Pool Delegate or a Pool Admin can call this function.
        @dev    It emits two `BalanceUpdated` events.
        @dev    It emits a `Claim` event.
        @param  loan      Address of the loan to claim from.
        @param  dlFactory Address of the DebtLockerFactory.
        @return claimInfo The claim details.
                    claimInfo [0] = Total amount claimed
                    claimInfo [1] = Interest  portion claimed
                    claimInfo [2] = Principal portion claimed
                    claimInfo [3] = Fee       portion claimed
                    claimInfo [4] = Excess    portion claimed
                    claimInfo [5] = Recovered portion claimed (from liquidations)
                    claimInfo [6] = Default suffered
    */
    function claim(address loan, address dlFactory) external returns (uint256[7] memory claimInfo) {
        _whenProtocolNotPaused();
        _isValidDelegateOrPoolAdmin();
        claimInfo = IDebtLocker(debtLockers[loan][dlFactory]).claim();

        (uint256 poolDelegatePortion, uint256 stakeLockerPortion, uint256 principalClaim, uint256 interestClaim) = PoolLib.calculateClaimAndPortions(claimInfo, delegateFee, stakingFee);

        // Subtract outstanding principal by the principal claimed plus excess returned.
        // Considers possible `principalClaim` overflow if Liquidity Asset is transferred directly into the Loan.
        if (principalClaim <= principalOut) {
            principalOut = principalOut - principalClaim;
        } else {
            interestClaim  = interestClaim.add(principalClaim - principalOut);  // Distribute `principalClaim` overflow as interest to LPs.
            principalClaim = principalOut;                                      // Set `principalClaim` to `principalOut` so correct amount gets transferred.
            principalOut   = 0;                                                 // Set `principalOut` to zero to avoid subtraction overflow.
        }

        // Accounts for rounding error in StakeLocker / Pool Delegate / LiquidityLocker interest split.
        interestSum = interestSum.add(interestClaim);

        _transferLiquidityAsset(poolDelegate, poolDelegatePortion);  // Transfer the fee and portion of interest to the Pool Delegate.
        _transferLiquidityAsset(stakeLocker,  stakeLockerPortion);   // Transfer the portion of interest to the StakeLocker.

        // Transfer remaining claim (remaining interest + principal + excess + recovered) to the LiquidityLocker.
        // Dust will accrue in the Pool, but this ensures that state variables are in sync with the LiquidityLocker balance updates.
        // Not using `balanceOf` in case of external address transferring the Liquidity Asset directly into Pool.
        // Ensures that internal accounting is exactly reflective of balance change.
        _transferLiquidityAsset(liquidityLocker, principalClaim.add(interestClaim));

        // Handle default if defaultSuffered > 0.
        if (claimInfo[6] > 0) _handleDefault(loan, claimInfo[6]);

        // Update funds received for StakeLockerFDTs.
        IStakeLocker(stakeLocker).updateFundsReceived();

        // Update funds received for PoolFDTs.
        updateFundsReceived();

        _emitBalanceUpdatedEvent();
        emit BalanceUpdated(stakeLocker, address(liquidityAsset), liquidityAsset.balanceOf(stakeLocker));

        emit Claim(loan, interestClaim, principalClaim, claimInfo[3], stakeLockerPortion, poolDelegatePortion);
    }

    /**
        @dev   Handles if a claim has been made and there is a non-zero defaultSuffered amount.
        @dev   It emits a `DefaultSuffered` event.
        @param loan            Address of a Loan that has defaulted.
        @param defaultSuffered Losses suffered from default after liquidation.
    */
    function _handleDefault(address loan, uint256 defaultSuffered) internal {

        (uint256 bptsBurned, uint256 postBurnBptBal, uint256 liquidityAssetRecoveredFromBurn) = PoolLib.handleDefault(liquidityAsset, stakeLocker, stakeAsset, defaultSuffered);

        // If BPT burn is not enough to cover full default amount, pass on losses to LPs with PoolFDT loss accounting.
        if (defaultSuffered > liquidityAssetRecoveredFromBurn) {
            poolLosses = poolLosses.add(defaultSuffered - liquidityAssetRecoveredFromBurn);
            updateLossesReceived();
        }

        // Transfer Liquidity Asset from burn to LiquidityLocker.
        liquidityAsset.safeTransfer(liquidityLocker, liquidityAssetRecoveredFromBurn);

        principalOut = principalOut.sub(defaultSuffered);  // Subtract rest of the Loan's principal from `principalOut`.

        emit DefaultSuffered(
            loan,                            // The Loan that suffered the default.
            defaultSuffered,                 // Total default suffered from the Loan by the Pool after liquidation.
            bptsBurned,                      // Amount of BPTs burned from StakeLocker.
            postBurnBptBal,                  // Remaining BPTs in StakeLocker post-burn.
            liquidityAssetRecoveredFromBurn  // Amount of Liquidity Asset recovered from burning BPTs.
        );
    }

    /**
        @dev Triggers deactivation, permanently shutting down the Pool. Must have less than 100 USD worth of Liquidity Asset `principalOut`.
             Only the Pool Delegate can call this function.
        @dev It emits a `PoolStateChanged` event.
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
        @dev   Sets the liquidity cap. Only the Pool Delegate or a Pool Admin can call this function.
        @dev   It emits a `LiquidityCapSet` event.
        @param newLiquidityCap New liquidity cap value.
    */
    function setLiquidityCap(uint256 newLiquidityCap) external {
        _whenProtocolNotPaused();
        _isValidDelegateOrPoolAdmin();
        liquidityCap = newLiquidityCap;
        emit LiquidityCapSet(newLiquidityCap);
    }

    /**
        @dev   Sets the lockup period. Only the Pool Delegate can call this function.
        @dev   It emits a `LockupPeriodSet` event.
        @param newLockupPeriod New lockup period used to restrict the withdrawals.
    */
    function setLockupPeriod(uint256 newLockupPeriod) external {
        _isValidDelegateAndProtocolNotPaused();
        require(newLockupPeriod <= lockupPeriod, "P:BAD_VALUE");
        lockupPeriod = newLockupPeriod;
        emit LockupPeriodSet(newLockupPeriod);
    }

    /**
        @dev   Sets the staking fee. Only the Pool Delegate can call this function.
        @dev   It emits a `StakingFeeSet` event.
        @param newStakingFee New staking fee.
    */
    function setStakingFee(uint256 newStakingFee) external {
        _isValidDelegateAndProtocolNotPaused();
        require(newStakingFee.add(delegateFee) <= 10_000, "P:BAD_FEE");
        stakingFee = newStakingFee;
        emit StakingFeeSet(newStakingFee);
    }

    /**
        @dev   Sets the account status in the Pool's allowlist. Only the Pool Delegate can call this function.
        @dev   It emits an `LPStatusChanged` event.
        @param account The address to set status for.
        @param status  The status of an account in the allowlist.
    */
    function setAllowList(address account, bool status) external {
        _isValidDelegateAndProtocolNotPaused();
        allowedLiquidityProviders[account] = status;
        emit LPStatusChanged(account, status);
    }

    /**
        @dev   Sets a Pool Admin. Only the Pool Delegate can call this function.
        @dev   It emits a `PoolAdminSet` event.
        @param poolAdmin An address being allowed or disallowed as a Pool Admin.
        @param allowed Status of a Pool Admin.
    */
    function setPoolAdmin(address poolAdmin, bool allowed) external {
        _isValidDelegateAndProtocolNotPaused();
        poolAdmins[poolAdmin] = allowed;
        emit PoolAdminSet(poolAdmin, allowed);
    }

    /**
        @dev   Sets whether the Pool is open to the public. Only the Pool Delegate can call this function.
        @dev   It emits a `PoolOpenedToPublic` event.
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
        @dev   Handles Liquidity Providers depositing of Liquidity Asset into the LiquidityLocker, minting PoolFDTs.
        @dev   It emits a `DepositDateUpdated` event.
        @dev   It emits a `BalanceUpdated` event.
        @dev   It emits a `Cooldown` event.
        @param amt Amount of Liquidity Asset to deposit.
    */
    function deposit(uint256 amt) external {
        _whenProtocolNotPaused();
        _isValidState(State.Finalized);
        require(isDepositAllowed(amt), "P:DEP_NOT_ALLOWED");

        withdrawCooldown[msg.sender] = uint256(0);  // Reset the LP's withdraw cooldown if they had previously intended to withdraw.

        uint256 wad = _toWad(amt);
        PoolLib.updateDepositDate(depositDate, balanceOf(msg.sender), wad, msg.sender);

        liquidityAsset.safeTransferFrom(msg.sender, liquidityLocker, amt);
        _mint(msg.sender, wad);

        _emitBalanceUpdatedEvent();
        emit Cooldown(msg.sender, uint256(0));
    }

    /**
        @dev Activates the cooldown period to withdraw. It can't be called if the account is not providing liquidity.
        @dev It emits a `Cooldown` event.
    **/
    function intendToWithdraw() external {
        require(balanceOf(msg.sender) != uint256(0), "P:ZERO_BAL");
        withdrawCooldown[msg.sender] = block.timestamp;
        emit Cooldown(msg.sender, block.timestamp);
    }

    /**
        @dev Cancels an initiated withdrawal by resetting the account's withdraw cooldown.
        @dev It emits a `Cooldown` event.
    **/
    function cancelWithdraw() external {
        require(withdrawCooldown[msg.sender] != uint256(0), "P:NOT_WITHDRAWING");
        withdrawCooldown[msg.sender] = uint256(0);
        emit Cooldown(msg.sender, uint256(0));
    }

    /**
        @dev   Checks that the account can withdraw an amount.
        @param account The address of the account.
        @param wad     The amount to withdraw.
    */
    function _canWithdraw(address account, uint256 wad) internal view {
        require(depositDate[account].add(lockupPeriod) <= block.timestamp,     "P:FUNDS_LOCKED");     // Restrict withdrawal during lockup period
        require(balanceOf(account).sub(wad) >= totalCustodyAllowance[account], "P:INSUF_TRANS_BAL");  // Account can only withdraw tokens that aren't custodied
    }

    /**
        @dev   Handles Liquidity Providers withdrawing of Liquidity Asset from the LiquidityLocker, burning PoolFDTs.
        @dev   It emits two `BalanceUpdated` event.
        @param amt Amount of Liquidity Asset to withdraw.
    */
    function withdraw(uint256 amt) external {
        _whenProtocolNotPaused();
        uint256 wad = _toWad(amt);
        (uint256 lpCooldownPeriod, uint256 lpWithdrawWindow) = _globals(superFactory).getLpCooldownParams();

        _canWithdraw(msg.sender, wad);
        require((block.timestamp - (withdrawCooldown[msg.sender] + lpCooldownPeriod)) <= lpWithdrawWindow, "P:WITHDRAW_NOT_ALLOWED");

        _burn(msg.sender, wad);  // Burn the corresponding PoolFDTs balance.
        withdrawFunds();         // Transfer full entitled interest, decrement `interestSum`.

        // Transfer amount that is due after realized losses are accounted for.
        // Recognized losses are absorbed by the LP.
        _transferLiquidityLockerFunds(msg.sender, amt.sub(_recognizeLosses()));

        _emitBalanceUpdatedEvent();
    }

    /**
        @dev   Transfers PoolFDTs.
        @param from Address sending   PoolFDTs.
        @param to   Address receiving PoolFDTs.
        @param wad  Amount of PoolFDTs to transfer.
    */
    function _transfer(address from, address to, uint256 wad) internal override {
        _whenProtocolNotPaused();

        (uint256 lpCooldownPeriod, uint256 lpWithdrawWindow) = _globals(superFactory).getLpCooldownParams();

        _canWithdraw(from, wad);
        require(block.timestamp > (withdrawCooldown[to] + lpCooldownPeriod + lpWithdrawWindow), "P:TO_NOT_ALLOWED");  // Recipient must not be currently withdrawing.
        require(recognizableLossesOf(from) == uint256(0),                                       "P:RECOG_LOSSES");    // If an LP has unrecognized losses, they must recognize losses using `withdraw`.

        PoolLib.updateDepositDate(depositDate, balanceOf(to), wad, to);
        super._transfer(from, to, wad);
    }

    /**
        @dev Withdraws all claimable interest from the LiquidityLocker for an account using `interestSum` accounting.
        @dev It emits a `BalanceUpdated` event.
    */
    function withdrawFunds() public override {
        _whenProtocolNotPaused();
        uint256 withdrawableFunds = _prepareWithdraw();

        if (withdrawableFunds == uint256(0)) return;

        _transferLiquidityLockerFunds(msg.sender, withdrawableFunds);
        _emitBalanceUpdatedEvent();

        interestSum = interestSum.sub(withdrawableFunds);

        _updateFundsTokenBalance();
    }

    /**
        @dev   Increases the custody allowance for a given Custodian corresponding to the calling account (`msg.sender`).
        @dev   It emits a `CustodyAllowanceChanged` event.
        @dev   It emits a `TotalCustodyAllowanceUpdated` event.
        @param custodian Address which will act as Custodian of a given amount for an account.
        @param amount    Number of additional FDTs to be custodied by the Custodian.
    */
    function increaseCustodyAllowance(address custodian, uint256 amount) external {
        uint256 oldAllowance      = custodyAllowance[msg.sender][custodian];
        uint256 newAllowance      = oldAllowance.add(amount);
        uint256 newTotalAllowance = totalCustodyAllowance[msg.sender].add(amount);

        PoolLib.increaseCustodyAllowanceChecks(custodian, amount, newTotalAllowance, balanceOf(msg.sender));

        custodyAllowance[msg.sender][custodian] = newAllowance;
        totalCustodyAllowance[msg.sender]       = newTotalAllowance;
        emit CustodyAllowanceChanged(msg.sender, custodian, oldAllowance, newAllowance);
        emit TotalCustodyAllowanceUpdated(msg.sender, newTotalAllowance);
    }

    /**
        @dev   Transfers custodied PoolFDTs back to the account.
        @dev   `from` and `to` should always be equal in this implementation.
        @dev   This means that the Custodian can only decrease their own allowance and unlock funds for the original owner.
        @dev   It emits a `CustodyTransfer` event.
        @dev   It emits a `CustodyAllowanceChanged` event.
        @dev   It emits a `TotalCustodyAllowanceUpdated` event.
        @param from   Address which holds the PoolFDTs.
        @param to     Address which will be the new owner of the amount of PoolFDTs.
        @param amount Amount of PoolFDTs transferred.
    */
    function transferByCustodian(address from, address to, uint256 amount) external {
        uint256 oldAllowance = custodyAllowance[from][msg.sender];
        uint256 newAllowance = oldAllowance.sub(amount);

        PoolLib.transferByCustodianChecks(from, to, amount);

        custodyAllowance[from][msg.sender] = newAllowance;
        uint256 newTotalAllowance          = totalCustodyAllowance[from].sub(amount);
        totalCustodyAllowance[from]        = newTotalAllowance;
        emit CustodyTransfer(msg.sender, from, to, amount);
        emit CustodyAllowanceChanged(from, msg.sender, oldAllowance, newAllowance);
        emit TotalCustodyAllowanceUpdated(msg.sender, newTotalAllowance);
    }

    /**************************/
    /*** Governor Functions ***/
    /**************************/

    /**
        @dev   Transfers any locked funds to the Governor. Only the Governor can call this function.
        @param token Address of the token to be reclaimed.
    */
    function reclaimERC20(address token) external {
        PoolLib.reclaimERC20(token, address(liquidityAsset), _globals(superFactory));
    }

    /*************************/
    /*** Getter Functions ***/
    /*************************/

    /**
        @dev    Calculates the value of BPT in units of Liquidity Asset.
        @param  _bPool          Address of Balancer pool.
        @param  _liquidityAsset Asset used by Pool for liquidity to fund Loans.
        @param  _staker         Address that deposited BPTs to StakeLocker.
        @param  _stakeLocker    Escrows BPTs deposited by Staker.
        @return USDC value of staker BPTs.
    */
    function BPTVal(
        address _bPool,
        address _liquidityAsset,
        address _staker,
        address _stakeLocker
    ) external view returns (uint256) {
        return PoolLib.BPTVal(_bPool, _liquidityAsset, _staker, _stakeLocker);
    }

    /**
        @dev   Checks that the given deposit amount is acceptable based on current liquidityCap.
        @param depositAmt Amount of tokens (i.e liquidityAsset type) the account is trying to deposit.
    */
    function isDepositAllowed(uint256 depositAmt) public view returns (bool) {
        return (openToPublic || allowedLiquidityProviders[msg.sender]) &&
               _balanceOfLiquidityLocker().add(principalOut).add(depositAmt) <= liquidityCap;
    }

    /**
        @dev    Returns information on the stake requirements.
        @return [0] = Min amount of Liquidity Asset coverage from staking required.
                [1] = Present amount of Liquidity Asset coverage from the Pool Delegate stake.
                [2] = If enough stake is present from the Pool Delegate for finalization.
                [3] = Staked BPTs required for minimum Liquidity Asset coverage.
                [4] = Current staked BPTs.
    */
    function getInitialStakeRequirements() public view returns (uint256, uint256, bool, uint256, uint256) {
        return PoolLib.getInitialStakeRequirements(_globals(superFactory), stakeAsset, address(liquidityAsset), poolDelegate, stakeLocker);
    }

    /**
        @dev    Calculates BPTs required if burning BPTs for the Liquidity Asset, given supplied `tokenAmountOutRequired`.
        @param  _bPool                        The Balancer pool that issues the BPTs.
        @param  _liquidityAsset               Swap out asset (e.g. USDC) to receive when burning BPTs.
        @param  _staker                       Address that deposited BPTs to StakeLocker.
        @param  _stakeLocker                  Escrows BPTs deposited by Staker.
        @param  _liquidityAssetAmountRequired Amount of Liquidity Asset required to recover.
        @return [0] = poolAmountIn required.
                [1] = poolAmountIn currently staked.
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
      @dev    Checks that the Pool state is `Finalized`.
      @return bool Boolean value indicating if Pool is in a Finalized state.
    */
    function isPoolFinalized() external view returns (bool) {
        return poolState == State.Finalized;
    }

    /************************/
    /*** Helper Functions ***/
    /************************/

    /**
        @dev   Converts to WAD precision.
        @param amt Amount to convert.
    */
    function _toWad(uint256 amt) internal view returns (uint256) {
        return amt.mul(WAD).div(10 ** liquidityAssetDecimals);
    }

    /**
        @dev    Returns the balance of this Pool's LiquidityLocker.
        @return Balance of LiquidityLocker.
    */
    function _balanceOfLiquidityLocker() internal view returns (uint256) {
        return liquidityAsset.balanceOf(liquidityLocker);
    }

    /**
        @dev   Checks that the current state of Pool matches the provided state.
        @param _state Enum of desired Pool state.
    */
    function _isValidState(State _state) internal view {
        require(poolState == _state, "P:BAD_STATE");
    }

    /**
        @dev Checks that `msg.sender` is the Pool Delegate.
    */
    function _isValidDelegate() internal view {
        require(msg.sender == poolDelegate, "P:NOT_DEL");
    }

    /**
        @dev Returns the MapleGlobals instance.
    */
    function _globals(address poolFactory) internal view returns (IMapleGlobals) {
        return IMapleGlobals(IPoolFactory(poolFactory).globals());
    }

    /**
        @dev Emits a `BalanceUpdated` event for LiquidityLocker.
        @dev It emits a `BalanceUpdated` event.
    */
    function _emitBalanceUpdatedEvent() internal {
        emit BalanceUpdated(liquidityLocker, address(liquidityAsset), _balanceOfLiquidityLocker());
    }

    /**
        @dev   Transfers Liquidity Asset to given `to` address, from self (i.e. `address(this)`).
        @param to    Address to transfer liquidityAsset.
        @param value Amount of liquidity asset that gets transferred.
    */
    function _transferLiquidityAsset(address to, uint256 value) internal {
        liquidityAsset.safeTransfer(to, value);
    }

    /**
        @dev Checks that `msg.sender` is the Pool Delegate or a Pool Admin.
    */
    function _isValidDelegateOrPoolAdmin() internal view {
        require(msg.sender == poolDelegate || poolAdmins[msg.sender], "P:NOT_DEL_OR_ADMIN");
    }

    /**
        @dev Checks that the protocol is not in a paused state.
    */
    function _whenProtocolNotPaused() internal view {
        require(!_globals(superFactory).protocolPaused(), "P:PROTO_PAUSED");
    }

    /**
        @dev Checks that `msg.sender` is the Pool Delegate and that the protocol is not in a paused state.
    */
    function _isValidDelegateAndProtocolNotPaused() internal view {
        _isValidDelegate();
        _whenProtocolNotPaused();
    }

    function _transferLiquidityLockerFunds(address to, uint256 value) internal {
        ILiquidityLocker(liquidityLocker).transfer(to, value);
    }

}