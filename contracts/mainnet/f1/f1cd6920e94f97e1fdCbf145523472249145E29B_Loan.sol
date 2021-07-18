/**
 *Submitted for verification at Etherscan.io on 2021-07-18
*/

// SPDX-License-Identifier:  AGPL-3.0-or-later // hevm: flattened sources of contracts/Loan.sol
pragma solidity =0.6.11 >=0.6.0 <0.8.0 >=0.6.2 <0.8.0;

////// contracts/interfaces/ICollateralLocker.sol
/* pragma solidity 0.6.11; */

interface ICollateralLocker {

    function collateralAsset() external view returns (address);

    function loan() external view returns (address);

    function pull(address, uint256) external;

}

////// contracts/interfaces/ICollateralLockerFactory.sol
/* pragma solidity 0.6.11; */

interface ICollateralLockerFactory {

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

////// contracts/interfaces/IFundingLocker.sol
/* pragma solidity 0.6.11; */

interface IFundingLocker {

    function liquidityAsset() external view returns (address);

    function loan() external view returns (address);

    function pull(address, uint256) external;

    function drain() external;

}

////// contracts/interfaces/IFundingLockerFactory.sol
/* pragma solidity 0.6.11; */

interface IFundingLockerFactory {

    function owner(address) external view returns (address);
    
    function isLocker(address) external view returns (bool);

    function factoryType() external view returns (uint8);
    
    function newLocker(address) external returns (address);

}

////// contracts/interfaces/ILateFeeCalc.sol
/* pragma solidity 0.6.11; */

interface ILateFeeCalc {

    function calcType() external view returns (uint8);

    function name() external view returns (bytes32);

    function lateFee() external view returns (uint256);

    function getLateFee(uint256) external view returns (uint256);

} 

////// contracts/interfaces/ILiquidityLocker.sol
/* pragma solidity 0.6.11; */

interface ILiquidityLocker {

    function pool() external view returns (address);

    function liquidityAsset() external view returns (address);

    function transfer(address, uint256) external;

    function fundLoan(address, address, uint256) external;

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

////// contracts/token/interfaces/IPoolFDT.sol
/* pragma solidity 0.6.11; */

/* import "./IExtendedFDT.sol"; */

interface IPoolFDT is IExtendedFDT {

    function interestSum() external view returns (uint256);

    function poolLosses() external view returns (uint256);

    function interestBalance() external view returns (uint256);

    function lossesBalance() external view returns (uint256);

}

////// contracts/interfaces/IPool.sol
/* pragma solidity 0.6.11; */

/* import "../token/interfaces/IPoolFDT.sol"; */

interface IPool is IPoolFDT {

    function poolDelegate() external view returns (address);

    function poolAdmins(address) external view returns (bool);

    function deposit(uint256) external;

    function increaseCustodyAllowance(address, uint256) external;

    function transferByCustodian(address, address, uint256) external;

    function poolState() external view returns (uint256);

    function deactivate() external;

    function finalize() external;

    function claim(address, address) external returns (uint256[7] memory);

    function setLockupPeriod(uint256) external;
    
    function setStakingFee(uint256) external;

    function setPoolAdmin(address, bool) external;

    function fundLoan(address, address, uint256) external;

    function withdraw(uint256) external;

    function superFactory() external view returns (address);

    function triggerDefault(address, address) external;

    function isPoolFinalized() external view returns (bool);

    function setOpenToPublic(bool) external;

    function setAllowList(address, bool) external;

    function allowedLiquidityProviders(address) external view returns (bool);

    function openToPublic() external view returns (bool);

    function intendToWithdraw() external;

    function DL_FACTORY() external view returns (uint8);

    function liquidityAsset() external view returns (address);

    function liquidityLocker() external view returns (address);

    function stakeAsset() external view returns (address);

    function stakeLocker() external view returns (address);

    function stakingFee() external view returns (uint256);

    function delegateFee() external view returns (uint256);

    function principalOut() external view returns (uint256);

    function liquidityCap() external view returns (uint256);

    function lockupPeriod() external view returns (uint256);

    function depositDate(address) external view returns (uint256);

    function debtLockers(address, address) external view returns (address);

    function withdrawCooldown(address) external view returns (uint256);

    function setLiquidityCap(uint256) external;

    function cancelWithdraw() external;

    function reclaimERC20(address) external;

    function BPTVal(address, address, address, address) external view returns (uint256);

    function isDepositAllowed(uint256) external view returns (bool);

    function getInitialStakeRequirements() external view returns (uint256, uint256, bool, uint256, uint256);

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

////// contracts/interfaces/IPremiumCalc.sol
/* pragma solidity 0.6.11; */

interface IPremiumCalc {

    function calcType() external view returns (uint8);

    function name() external view returns (bytes32);

    function premiumFee() external view returns (uint256);

    function getPremiumPayment(address) external view returns (uint256, uint256, uint256);

} 

////// contracts/interfaces/IRepaymentCalc.sol
/* pragma solidity 0.6.11; */

interface IRepaymentCalc {

    function calcType() external view returns (uint8);

    function name() external view returns (bytes32);

    function getNextPayment(address) external view returns (uint256, uint256, uint256);

} 

////// contracts/interfaces/IUniswapRouter.sol
/* pragma solidity 0.6.11; */

interface IUniswapRouter {

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function WETH() external pure returns (address);

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

////// contracts/library/Util.sol
/* pragma solidity 0.6.11; */

/* import "../interfaces/IERC20Details.sol"; */
/* import "../interfaces/IMapleGlobals.sol"; */
/* import "lib/openzeppelin-contracts/contracts/math/SafeMath.sol"; */

/// @title Util is a library that contains utility functions.
library Util {

    using SafeMath for uint256;

    /**
        @dev    Calculates the minimum amount from a swap (adjustable for price slippage).
        @param  globals   Instance of a MapleGlobals.
        @param  fromAsset Address of ERC-20 that will be swapped.
        @param  toAsset   Address of ERC-20 that will returned from swap.
        @param  swapAmt   Amount of `fromAsset` to be swapped.
        @return Expected amount of `toAsset` to receive from swap based on current oracle prices.
    */
    function calcMinAmount(IMapleGlobals globals, address fromAsset, address toAsset, uint256 swapAmt) external view returns (uint256) {
        return 
            swapAmt
                .mul(globals.getLatestPrice(fromAsset))           // Convert from `fromAsset` value.
                .mul(10 ** IERC20Details(toAsset).decimals())     // Convert to `toAsset` decimal precision.
                .div(globals.getLatestPrice(toAsset))             // Convert to `toAsset` value.
                .div(10 ** IERC20Details(fromAsset).decimals());  // Convert from `fromAsset` decimal precision.
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

////// contracts/library/LoanLib.sol
/* pragma solidity 0.6.11; */

/* import "../interfaces/ICollateralLocker.sol"; */
/* import "../interfaces/ICollateralLockerFactory.sol"; */
/* import "../interfaces/IERC20Details.sol"; */
/* import "../interfaces/IFundingLocker.sol"; */
/* import "../interfaces/IFundingLockerFactory.sol"; */
/* import "../interfaces/IMapleGlobals.sol"; */
/* import "../interfaces/ILateFeeCalc.sol"; */
/* import "../interfaces/ILoanFactory.sol"; */
/* import "../interfaces/IPremiumCalc.sol"; */
/* import "../interfaces/IRepaymentCalc.sol"; */
/* import "../interfaces/IUniswapRouter.sol"; */

/* import "../library/Util.sol"; */

/* import "lib/openzeppelin-contracts/contracts/token/ERC20/SafeERC20.sol"; */
/* import "lib/openzeppelin-contracts/contracts/math/SafeMath.sol"; */

/// @title LoanLib is a library of utility functions used by Loan.
library LoanLib {

    using SafeMath  for uint256;
    using SafeERC20 for IERC20;

    address public constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    /********************************/
    /*** Lender Utility Functions ***/
    /********************************/

    /**
        @dev    Performs sanity checks on the data passed in Loan constructor.
        @param  globals         Instance of a MapleGlobals.
        @param  liquidityAsset  Contract address of the Liquidity Asset.
        @param  collateralAsset Contract address of the Collateral Asset.
        @param  specs           Contains specifications for this Loan.
    */
    function loanSanityChecks(IMapleGlobals globals, address liquidityAsset, address collateralAsset, uint256[5] calldata specs) external view {
        require(globals.isValidLiquidityAsset(liquidityAsset),   "L:INVALID_LIQ_ASSET");
        require(globals.isValidCollateralAsset(collateralAsset), "L:INVALID_COL_ASSET");

        require(specs[2] != uint256(0),               "L:ZERO_PID");
        require(specs[1].mod(specs[2]) == uint256(0), "L:INVALID_TERM_DAYS");
        require(specs[3] > uint256(0),                "L:ZERO_REQUEST_AMT");
    }

    /**
        @dev    Returns capital to Lenders, if the Borrower has not drawn down the Loan past the grace period.
        @param  liquidityAsset IERC20 of the Liquidity Asset.
        @param  fundingLocker  Address of FundingLocker.
        @param  createdAt      Timestamp of Loan instantiation.
        @param  fundingPeriod  Duration of the funding period, after which funds can be reclaimed.
        @return excessReturned Amount of Liquidity Asset that was returned to the Loan from the FundingLocker.
    */
    function unwind(IERC20 liquidityAsset, address fundingLocker, uint256 createdAt, uint256 fundingPeriod) external returns (uint256 excessReturned) {
        // Only callable if Loan funding period has elapsed.
        require(block.timestamp > createdAt.add(fundingPeriod), "L:STILL_FUNDING_PERIOD");

        // Account for existing balance in Loan.
        uint256 preBal = liquidityAsset.balanceOf(address(this));

        // Drain funding from FundingLocker, transfers all the Liquidity Asset to this Loan.
        IFundingLocker(fundingLocker).drain();

        return liquidityAsset.balanceOf(address(this)).sub(preBal);
    }

    /**
        @dev    Liquidates a Borrower's collateral, via Uniswap, when a default is triggered. Only the Loan can call this function.
        @param  collateralAsset  IERC20 of the Collateral Asset.
        @param  liquidityAsset   Address of Liquidity Asset.
        @param  superFactory     Factory that instantiated Loan.
        @param  collateralLocker Address of CollateralLocker.
        @return amountLiquidated Amount of Collateral Asset that was liquidated.
        @return amountRecovered  Amount of Liquidity Asset that was returned to the Loan from the liquidation.
    */
    function liquidateCollateral(
        IERC20  collateralAsset,
        address liquidityAsset,
        address superFactory,
        address collateralLocker
    ) 
        external
        returns (
            uint256 amountLiquidated,
            uint256 amountRecovered
        ) 
    {
        // Get the liquidation amount from CollateralLocker.
        uint256 liquidationAmt = collateralAsset.balanceOf(address(collateralLocker));
        
        // Pull the Collateral Asset from CollateralLocker.
        ICollateralLocker(collateralLocker).pull(address(this), liquidationAmt);

        if (address(collateralAsset) == liquidityAsset || liquidationAmt == uint256(0)) return (liquidationAmt, liquidationAmt);

        collateralAsset.safeApprove(UNISWAP_ROUTER, uint256(0));
        collateralAsset.safeApprove(UNISWAP_ROUTER, liquidationAmt);

        IMapleGlobals globals = _globals(superFactory);

        // Get minimum amount of loan asset get after swapping collateral asset.
        uint256 minAmount = Util.calcMinAmount(globals, address(collateralAsset), liquidityAsset, liquidationAmt);

        // Generate Uniswap path.
        address uniswapAssetForPath = globals.defaultUniswapPath(address(collateralAsset), liquidityAsset);
        bool middleAsset = uniswapAssetForPath != liquidityAsset && uniswapAssetForPath != address(0);

        address[] memory path = new address[](middleAsset ? 3 : 2);

        path[0] = address(collateralAsset);
        path[1] = middleAsset ? uniswapAssetForPath : liquidityAsset;

        if (middleAsset) path[2] = liquidityAsset;

        // Swap collateralAsset for Liquidity Asset.
        uint256[] memory returnAmounts = IUniswapRouter(UNISWAP_ROUTER).swapExactTokensForTokens(
            liquidationAmt,
            minAmount.sub(minAmount.mul(globals.maxSwapSlippage()).div(10_000)),
            path,
            address(this),
            block.timestamp
        );

        return(returnAmounts[0], returnAmounts[path.length - 1]);
    }

    /**********************************/
    /*** Governor Utility Functions ***/
    /**********************************/

    /**
        @dev   Transfers any locked funds to the Governor. Only the Governor can call this function.
        @param token          Address of the token to be reclaimed.
        @param liquidityAsset Address of token that is used by the loan for drawdown and payments.
        @param globals        Instance of a MapleGlobals.
    */
    function reclaimERC20(address token, address liquidityAsset, IMapleGlobals globals) external {
        require(msg.sender == globals.governor(),               "L:NOT_GOV");
        require(token != liquidityAsset && token != address(0), "L:INVALID_TOKEN");
        IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    /************************/
    /*** Getter Functions ***/
    /************************/

    /**
        @dev    Returns if a default can be triggered.
        @param  nextPaymentDue     Timestamp of when payment is due.
        @param  defaultGracePeriod Amount of time after the next payment is due that a Borrower has before a liquidation can occur.
        @param  superFactory       Factory that instantiated Loan.
        @param  balance            LoanFDT balance of account trying to trigger a default.
        @param  totalSupply        Total supply of LoanFDT.
        @return Boolean indicating if default can be triggered.
    */
    function canTriggerDefault(uint256 nextPaymentDue, uint256 defaultGracePeriod, address superFactory, uint256 balance, uint256 totalSupply) external view returns (bool) {
        bool pastDefaultGracePeriod = block.timestamp > nextPaymentDue.add(defaultGracePeriod);

        // Check if the Loan is past the default grace period and that the account triggering the default has a percentage of total LoanFDTs
        // that is greater than the minimum equity needed (specified in globals)
        return pastDefaultGracePeriod && balance >= ((totalSupply * _globals(superFactory).minLoanEquity()) / 10_000);
    }

    /**
        @dev    Returns information on next payment amount.
        @param  repaymentCalc   Address of RepaymentCalc.
        @param  nextPaymentDue  Timestamp of when payment is due.
        @param  lateFeeCalc     Address of LateFeeCalc.
        @return total           Entitled total amount needed to be paid in the next payment (Principal + Interest only when the next payment is last payment of the Loan).
        @return principal       Entitled principal amount needed to be paid in the next payment.
        @return interest        Entitled interest amount needed to be paid in the next payment.
        @return _nextPaymentDue Payment Due Date.
        @return paymentLate     Whether payment is late.
    */
    function getNextPayment(
        address repaymentCalc,
        uint256 nextPaymentDue,
        address lateFeeCalc
    )
        external
        view
        returns (
            uint256 total,
            uint256 principal,
            uint256 interest,
            uint256 _nextPaymentDue,
            bool    paymentLate
        ) 
    {
        _nextPaymentDue  = nextPaymentDue;

        // Get next payment amounts from RepaymentCalc.
        (total, principal, interest) = IRepaymentCalc(repaymentCalc).getNextPayment(address(this));

        paymentLate = block.timestamp > _nextPaymentDue;

        // If payment is late, add late fees.
        if (paymentLate) {
            uint256 lateFee = ILateFeeCalc(lateFeeCalc).getLateFee(interest);
            
            total    = total.add(lateFee);
            interest = interest.add(lateFee);
        }
    }

    /**
        @dev    Returns information on full payment amount.
        @param  repaymentCalc   Address of RepaymentCalc.
        @param  nextPaymentDue  Timestamp of when payment is due.
        @param  lateFeeCalc     Address of LateFeeCalc.
        @param  premiumCalc     Address of PremiumCalc.
        @return total           Principal + Interest for the full payment.
        @return principal       Entitled principal amount needed to be paid in the full payment.
        @return interest        Entitled interest amount needed to be paid in the full payment.
    */
    function getFullPayment(
        address repaymentCalc,
        uint256 nextPaymentDue,
        address lateFeeCalc,
        address premiumCalc
    )
        external
        view
        returns (
            uint256 total,
            uint256 principal,
            uint256 interest
        ) 
    {
        (total, principal, interest) = IPremiumCalc(premiumCalc).getPremiumPayment(address(this));

        if (block.timestamp <= nextPaymentDue) return (total, principal, interest);

        // If payment is late, calculate and add late fees using interest amount from regular payment.
        (,, uint256 regInterest) = IRepaymentCalc(repaymentCalc).getNextPayment(address(this));

        uint256 lateFee = ILateFeeCalc(lateFeeCalc).getLateFee(regInterest);
        
        total    = total.add(lateFee);
        interest = interest.add(lateFee);
    }

    /**
        @dev    Calculates collateral required to drawdown amount.
        @param  collateralAsset IERC20 of the Collateral Asset.
        @param  liquidityAsset  IERC20 of the Liquidity Asset.
        @param  collateralRatio Percentage of drawdown value that must be posted as collateral.
        @param  superFactory    Factory that instantiated Loan.
        @param  amt             Drawdown amount.
        @return Amount of Collateral Asset required to post in CollateralLocker for given drawdown amount.
    */
    function collateralRequiredForDrawdown(
        IERC20Details collateralAsset,
        IERC20Details liquidityAsset,
        uint256 collateralRatio,
        address superFactory,
        uint256 amt
    ) 
        external
        view
        returns (uint256) 
    {
        IMapleGlobals globals = _globals(superFactory);

        uint256 wad = _toWad(amt, liquidityAsset);  // Convert to WAD precision.

        // Fetch current value of Liquidity Asset and Collateral Asset (Chainlink oracles provide 8 decimal precision).
        uint256 liquidityAssetPrice  = globals.getLatestPrice(address(liquidityAsset));
        uint256 collateralPrice = globals.getLatestPrice(address(collateralAsset));

        // Calculate collateral required.
        uint256 collateralRequiredUSD = wad.mul(liquidityAssetPrice).mul(collateralRatio).div(10_000);  // 18 + 8 = 26 decimals
        uint256 collateralRequiredWAD = collateralRequiredUSD.div(collateralPrice);                     // 26 - 8 = 18 decimals

        return collateralRequiredWAD.mul(10 ** collateralAsset.decimals()).div(10 ** 18);  // 18 + collateralAssetDecimals - 18 = collateralAssetDecimals
    }

    /************************/
    /*** Helper Functions ***/
    /************************/

    function _globals(address loanFactory) internal view returns (IMapleGlobals) {
        return IMapleGlobals(ILoanFactory(loanFactory).globals());
    }

    function _toWad(uint256 amt, IERC20Details liquidityAsset) internal view returns (uint256) {
        return amt.mul(10 ** 18).div(10 ** liquidityAsset.decimals());
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

////// contracts/token/LoanFDT.sol
/* pragma solidity 0.6.11; */

/* import "lib/openzeppelin-contracts/contracts/token/ERC20/SafeERC20.sol"; */

/* import "./BasicFDT.sol"; */

/// @title LoanFDT inherits BasicFDT and uses the original ERC-2222 logic.
abstract contract LoanFDT is BasicFDT {
    using SafeMath       for uint256;
    using SafeMathUint   for uint256;
    using SignedSafeMath for  int256;
    using SafeMathInt    for  int256;
    using SafeERC20      for  IERC20;

    IERC20 public immutable fundsToken; // The `fundsToken` (dividends).

    uint256 public fundsTokenBalance;   // The amount of `fundsToken` (Liquidity Asset) currently present and accounted for in this contract.

    constructor(string memory name, string memory symbol, address _fundsToken) BasicFDT(name, symbol) public {
        fundsToken = IERC20(_fundsToken);
    }

    /**
        @dev Withdraws all available funds for a token holder.
    */
    function withdrawFunds() public virtual override {
        uint256 withdrawableFunds = _prepareWithdraw();

        if (withdrawableFunds > uint256(0)) {
            fundsToken.safeTransfer(msg.sender, withdrawableFunds);

            _updateFundsTokenBalance();
        }
    }

    /**
        @dev    Updates the current `fundsToken` balance and returns the difference of the new and previous `fundsToken` balance.
        @return A int256 representing the difference of the new and previous `fundsToken` balance.
    */
    function _updateFundsTokenBalance() internal virtual override returns (int256) {
        uint256 _prevFundsTokenBalance = fundsTokenBalance;

        fundsTokenBalance = fundsToken.balanceOf(address(this));

        return int256(fundsTokenBalance).sub(int256(_prevFundsTokenBalance));
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

////// contracts/Loan.sol
/* pragma solidity 0.6.11; */

/* import "lib/openzeppelin-contracts/contracts/utils/Pausable.sol"; */
/* import "lib/openzeppelin-contracts/contracts/token/ERC20/SafeERC20.sol"; */

/* import "./interfaces/ICollateralLocker.sol"; */
/* import "./interfaces/ICollateralLockerFactory.sol"; */
/* import "./interfaces/IERC20Details.sol"; */
/* import "./interfaces/IFundingLocker.sol"; */
/* import "./interfaces/IFundingLockerFactory.sol"; */
/* import "./interfaces/IMapleGlobals.sol"; */
/* import "./interfaces/ILateFeeCalc.sol"; */
/* import "./interfaces/ILiquidityLocker.sol"; */
/* import "./interfaces/ILoanFactory.sol"; */
/* import "./interfaces/IPool.sol"; */
/* import "./interfaces/IPoolFactory.sol"; */
/* import "./interfaces/IPremiumCalc.sol"; */
/* import "./interfaces/IRepaymentCalc.sol"; */
/* import "./interfaces/IUniswapRouter.sol"; */

/* import "./library/Util.sol"; */
/* import "./library/LoanLib.sol"; */

/* import "./token/LoanFDT.sol"; */

/// @title Loan maintains all accounting and functionality related to Loans.
contract Loan is LoanFDT, Pausable {

    using SafeMathInt     for int256;
    using SignedSafeMath  for int256;
    using SafeMath        for uint256;
    using SafeERC20       for IERC20;

    /**
        Ready      = The Loan has been initialized and is ready for funding (assuming funding period hasn't ended)
        Active     = The Loan has been drawdown and the Borrower is making payments
        Matured    = The Loan is fully paid off and has "matured"
        Expired    = The Loan did not initiate, and all funding was returned to Lenders
        Liquidated = The Loan has been liquidated
    */
    enum State { Ready, Active, Matured, Expired, Liquidated }

    State public loanState;  // The current state of this Loan, as defined in the State enum below.

    IERC20 public immutable liquidityAsset;      // The asset deposited by Lenders into the FundingLocker, when funding this Loan.
    IERC20 public immutable collateralAsset;     // The asset deposited by Borrower into the CollateralLocker, for collateralizing this Loan.

    address public immutable fundingLocker;      // The FundingLocker that holds custody of Loan funds before drawdown.
    address public immutable flFactory;          // The FundingLockerFactory.
    address public immutable collateralLocker;   // The CollateralLocker that holds custody of Loan collateral.
    address public immutable clFactory;          // The CollateralLockerFactory.
    address public immutable borrower;           // The Borrower of this Loan, responsible for repayments.
    address public immutable repaymentCalc;      // The RepaymentCalc for this Loan.
    address public immutable lateFeeCalc;        // The LateFeeCalc for this Loan.
    address public immutable premiumCalc;        // The PremiumCalc for this Loan.
    address public immutable superFactory;       // The LoanFactory that deployed this Loan.

    mapping(address => bool) public loanAdmins;  // Admin addresses that have permission to do certain operations in case of disaster management.

    uint256 public nextPaymentDue;  // The unix timestamp due date of the next payment.

    // Loan specifications
    uint256 public immutable apr;                     // The APR in basis points.
    uint256 public           paymentsRemaining;       // The number of payments remaining on the Loan.
    uint256 public immutable termDays;                // The total length of the Loan term in days.
    uint256 public immutable paymentIntervalSeconds;  // The time between Loan payments in seconds.
    uint256 public immutable requestAmount;           // The total requested amount for Loan.
    uint256 public immutable collateralRatio;         // The percentage of value of the drawdown amount to post as collateral in basis points.
    uint256 public immutable createdAt;               // The timestamp of when Loan was instantiated.
    uint256 public immutable fundingPeriod;           // The time for a Loan to be funded in seconds.
    uint256 public immutable defaultGracePeriod;      // The time a Borrower has, after a payment is due, to make a payment before a liquidation can occur.

    // Accounting variables
    uint256 public principalOwed;   // The amount of principal owed (initially the drawdown amount).
    uint256 public principalPaid;   // The amount of principal that has  been paid     by the Borrower since the Loan instantiation.
    uint256 public interestPaid;    // The amount of interest  that has  been paid     by the Borrower since the Loan instantiation.
    uint256 public feePaid;         // The amount of fees      that have been paid     by the Borrower since the Loan instantiation.
    uint256 public excessReturned;  // The amount of excess    that has  been returned to the Lenders  after the Loan drawdown.

    // Liquidation variables
    uint256 public amountLiquidated;   // The amount of Collateral Asset that has been liquidated after default.
    uint256 public amountRecovered;    // The amount of Liquidity Asset  that has been recovered  after default.
    uint256 public defaultSuffered;    // The difference between `amountRecovered` and `principalOwed` after liquidation.
    uint256 public liquidationExcess;  // If `amountRecovered > principalOwed`, this is the amount of Liquidity Asset that is to be returned to the Borrower.

    event       LoanFunded(address indexed fundedBy, uint256 amountFunded);
    event   BalanceUpdated(address indexed account, address indexed token, uint256 balance);
    event         Drawdown(uint256 drawdownAmount);
    event LoanStateChanged(State state);
    event     LoanAdminSet(address indexed loanAdmin, bool allowed);
    
    event PaymentMade(
        uint256 totalPaid,
        uint256 principalPaid,
        uint256 interestPaid,
        uint256 paymentsRemaining,
        uint256 principalOwed,
        uint256 nextPaymentDue,
        bool latePayment
    );
    
    event Liquidation(
        uint256 collateralSwapped,
        uint256 liquidityAssetReturned,
        uint256 liquidationExcess,
        uint256 defaultSuffered
    );

    /**
        @dev    Constructor for a Loan.
        @dev    It emits a `LoanStateChanged` event.
        @param  _borrower        Will receive the funding when calling `drawdown()`. Is also responsible for repayments.
        @param  _liquidityAsset  The asset the Borrower is requesting funding in.
        @param  _collateralAsset The asset provided as collateral by the Borrower.
        @param  _flFactory       Factory to instantiate FundingLocker with.
        @param  _clFactory       Factory to instantiate CollateralLocker with.
        @param  specs            Contains specifications for this Loan.
                                     specs[0] = apr
                                     specs[1] = termDays
                                     specs[2] = paymentIntervalDays (aka PID)
                                     specs[3] = requestAmount
                                     specs[4] = collateralRatio
        @param  calcs            The calculators used for this Loan.
                                     calcs[0] = repaymentCalc
                                     calcs[1] = lateFeeCalc
                                     calcs[2] = premiumCalc
    */
    constructor(
        address _borrower,
        address _liquidityAsset,
        address _collateralAsset,
        address _flFactory,
        address _clFactory,
        uint256[5] memory specs,
        address[3] memory calcs
    ) LoanFDT("Maple Loan Token", "MPL-LOAN", _liquidityAsset) public {
        IMapleGlobals globals = _globals(msg.sender);

        // Perform validity cross-checks.
        LoanLib.loanSanityChecks(globals, _liquidityAsset, _collateralAsset, specs);

        borrower        = _borrower;
        liquidityAsset  = IERC20(_liquidityAsset);
        collateralAsset = IERC20(_collateralAsset);
        flFactory       = _flFactory;
        clFactory       = _clFactory;
        createdAt       = block.timestamp;

        // Update state variables.
        apr                    = specs[0];
        termDays               = specs[1];
        paymentsRemaining      = specs[1].div(specs[2]);
        paymentIntervalSeconds = specs[2].mul(1 days);
        requestAmount          = specs[3];
        collateralRatio        = specs[4];
        fundingPeriod          = globals.fundingPeriod();
        defaultGracePeriod     = globals.defaultGracePeriod();
        repaymentCalc          = calcs[0];
        lateFeeCalc            = calcs[1];
        premiumCalc            = calcs[2];
        superFactory           = msg.sender;

        // Deploy lockers.
        collateralLocker = ICollateralLockerFactory(_clFactory).newLocker(_collateralAsset);
        fundingLocker    = IFundingLockerFactory(_flFactory).newLocker(_liquidityAsset);
        emit LoanStateChanged(State.Ready);
    }

    /**************************/
    /*** Borrower Functions ***/
    /**************************/

    /**
        @dev   Draws down funding from FundingLocker, posts collateral, and transitions the Loan state from `Ready` to `Active`. Only the Borrower can call this function.
        @dev   It emits four `BalanceUpdated` events.
        @dev   It emits a `LoanStateChanged` event.
        @dev   It emits a `Drawdown` event.
        @param amt Amount of Liquidity Asset the Borrower draws down. Remainder is returned to the Loan where it can be claimed back by LoanFDT holders.
    */
    function drawdown(uint256 amt) external {
        _whenProtocolNotPaused();
        _isValidBorrower();
        _isValidState(State.Ready);
        IMapleGlobals globals = _globals(superFactory);

        IFundingLocker _fundingLocker = IFundingLocker(fundingLocker);

        require(amt >= requestAmount,              "L:AMT_LT_REQUEST_AMT");
        require(amt <= _getFundingLockerBalance(), "L:AMT_GT_FUNDED_AMT");

        // Update accounting variables for the Loan.
        principalOwed  = amt;
        nextPaymentDue = block.timestamp.add(paymentIntervalSeconds);

        loanState = State.Active;

        // Transfer the required amount of collateral for drawdown from the Borrower to the CollateralLocker.
        collateralAsset.safeTransferFrom(borrower, collateralLocker, collateralRequiredForDrawdown(amt));

        // Transfer funding amount from the FundingLocker to the Borrower, then drain remaining funds to the Loan.
        uint256 treasuryFee = globals.treasuryFee();
        uint256 investorFee = globals.investorFee();

        address treasury = globals.mapleTreasury();

        uint256 _feePaid = feePaid = amt.mul(investorFee).div(10_000);  // Update fees paid for `claim()`.
        uint256 treasuryAmt        = amt.mul(treasuryFee).div(10_000);  // Calculate amount to send to the MapleTreasury.

        _transferFunds(_fundingLocker, treasury, treasuryAmt);                         // Send the treasury fee directly to the MapleTreasury.
        _transferFunds(_fundingLocker, borrower, amt.sub(treasuryAmt).sub(_feePaid));  // Transfer drawdown amount to the Borrower.

        // Update excessReturned for `claim()`. 
        excessReturned = _getFundingLockerBalance().sub(_feePaid);

        // Drain remaining funds from the FundingLocker (amount equal to `excessReturned` plus `feePaid`)
        _fundingLocker.drain();

        // Call `updateFundsReceived()` update LoanFDT accounting with funds received from fees and excess returned.
        updateFundsReceived();

        _emitBalanceUpdateEventForCollateralLocker();
        _emitBalanceUpdateEventForFundingLocker();
        _emitBalanceUpdateEventForLoan();

        emit BalanceUpdated(treasury, address(liquidityAsset), liquidityAsset.balanceOf(treasury));
        emit LoanStateChanged(State.Active);
        emit Drawdown(amt);
    }

    /**
        @dev Makes a payment for this Loan. Amounts are calculated for the Borrower.
    */
    function makePayment() external {
        _whenProtocolNotPaused();
        _isValidState(State.Active);
        (uint256 total, uint256 principal, uint256 interest,, bool paymentLate) = getNextPayment();
        --paymentsRemaining;
        _makePayment(total, principal, interest, paymentLate);
    }

    /**
        @dev Makes the full payment for this Loan (a.k.a. "calling" the Loan). This requires the Borrower to pay a premium fee.
    */
    function makeFullPayment() external {
        _whenProtocolNotPaused();
        _isValidState(State.Active);
        (uint256 total, uint256 principal, uint256 interest) = getFullPayment();
        paymentsRemaining = uint256(0);
        _makePayment(total, principal, interest, false);
    }

    /**
        @dev Updates the payment variables and transfers funds from the Borrower into the Loan.
        @dev It emits one or two `BalanceUpdated` events (depending if payments remaining).
        @dev It emits a `LoanStateChanged` event if no payments remaining.
        @dev It emits a `PaymentMade` event.
    */
    function _makePayment(uint256 total, uint256 principal, uint256 interest, bool paymentLate) internal {

        // Caching to reduce `SLOADs`.
        uint256 _paymentsRemaining = paymentsRemaining;

        // Update internal accounting variables.
        interestPaid = interestPaid.add(interest);
        if (principal > uint256(0)) principalPaid = principalPaid.add(principal);

        if (_paymentsRemaining > uint256(0)) {
            // Update info related to next payment and, if needed, decrement principalOwed.
            nextPaymentDue = nextPaymentDue.add(paymentIntervalSeconds);
            if (principal > uint256(0)) principalOwed = principalOwed.sub(principal);
        } else {
            // Update info to close loan.
            principalOwed  = uint256(0);
            loanState      = State.Matured;
            nextPaymentDue = uint256(0);

            // Transfer all collateral back to the Borrower.
            ICollateralLocker(collateralLocker).pull(borrower, _getCollateralLockerBalance());
            _emitBalanceUpdateEventForCollateralLocker();
            emit LoanStateChanged(State.Matured);
        }

        // Loan payer sends funds to the Loan.
        liquidityAsset.safeTransferFrom(msg.sender, address(this), total);

        // Update FDT accounting with funds received from interest payment.
        updateFundsReceived();

        emit PaymentMade(
            total,
            principal,
            interest,
            _paymentsRemaining,
            principalOwed,
            _paymentsRemaining > 0 ? nextPaymentDue : 0,
            paymentLate
        );

        _emitBalanceUpdateEventForLoan();
    }

    /************************/
    /*** Lender Functions ***/
    /************************/

    /**
        @dev   Funds this Loan and mints LoanFDTs for `mintTo` (DebtLocker in the case of Pool funding).
               Only LiquidityLocker using valid/approved Pool can call this function.
        @dev   It emits a `LoanFunded` event.
        @dev   It emits a `BalanceUpdated` event.
        @param amt    Amount to fund the Loan.
        @param mintTo Address that LoanFDTs are minted to.
    */
    function fundLoan(address mintTo, uint256 amt) whenNotPaused external {
        _whenProtocolNotPaused();
        _isValidState(State.Ready);
        _isValidPool();
        _isWithinFundingPeriod();
        liquidityAsset.safeTransferFrom(msg.sender, fundingLocker, amt);

        uint256 wad = _toWad(amt);  // Convert to WAD precision.
        _mint(mintTo, wad);         // Mint LoanFDTs to `mintTo` (i.e DebtLocker contract).

        emit LoanFunded(mintTo, amt);
        _emitBalanceUpdateEventForFundingLocker();
    }

    /**
        @dev Handles returning capital to the Loan, where it can be claimed back by LoanFDT holders,
             if the Borrower has not drawn down on the Loan past the drawdown grace period.
        @dev It emits a `LoanStateChanged` event.
    */
    function unwind() external {
        _whenProtocolNotPaused();
        _isValidState(State.Ready);

        // Update accounting for `claim()` and transfer funds from FundingLocker to Loan.
        excessReturned = LoanLib.unwind(liquidityAsset, fundingLocker, createdAt, fundingPeriod);

        updateFundsReceived();

        // Transition state to `Expired`.
        loanState = State.Expired;
        emit LoanStateChanged(State.Expired);
    }

    /**
        @dev Triggers a default if the Loan meets certain default conditions, liquidating all collateral and updating accounting.
             Only the an account with sufficient LoanFDTs of this Loan can call this function.
        @dev It emits a `BalanceUpdated` event.
        @dev It emits a `Liquidation` event.
        @dev It emits a `LoanStateChanged` event.
    */
    function triggerDefault() external {
        _whenProtocolNotPaused();
        _isValidState(State.Active);
        require(LoanLib.canTriggerDefault(nextPaymentDue, defaultGracePeriod, superFactory, balanceOf(msg.sender), totalSupply()), "L:FAILED_TO_LIQ");

        // Pull the Collateral Asset from the CollateralLocker, swap to the Liquidity Asset, and hold custody of the resulting Liquidity Asset in the Loan.
        (amountLiquidated, amountRecovered) = LoanLib.liquidateCollateral(collateralAsset, address(liquidityAsset), superFactory, collateralLocker);
        _emitBalanceUpdateEventForCollateralLocker();

        // Decrement `principalOwed` by `amountRecovered`, set `defaultSuffered` to the difference (shortfall from the liquidation).
        if (amountRecovered <= principalOwed) {
            principalOwed   = principalOwed.sub(amountRecovered);
            defaultSuffered = principalOwed;
        }
        // Set `principalOwed` to zero and return excess value from the liquidation back to the Borrower.
        else {
            liquidationExcess = amountRecovered.sub(principalOwed);
            principalOwed = 0;
            liquidityAsset.safeTransfer(borrower, liquidationExcess);  // Send excess to the Borrower.
        }

        // Update LoanFDT accounting with funds received from the liquidation.
        updateFundsReceived();

        // Transition `loanState` to `Liquidated`
        loanState = State.Liquidated;

        emit Liquidation(
            amountLiquidated,  // Amount of Collateral Asset swapped.
            amountRecovered,   // Amount of Liquidity Asset recovered from swap.
            liquidationExcess, // Amount of Liquidity Asset returned to borrower.
            defaultSuffered    // Remaining losses after the liquidation.
        );
        emit LoanStateChanged(State.Liquidated);
    }

    /***********************/
    /*** Admin Functions ***/
    /***********************/

    /**
        @dev Triggers paused state. Halts functionality for certain functions. Only the Borrower or a Loan Admin can call this function.
    */
    function pause() external {
        _isValidBorrowerOrLoanAdmin();
        super._pause();
    }

    /**
        @dev Triggers unpaused state. Restores functionality for certain functions. Only the Borrower or a Loan Admin can call this function.
    */
    function unpause() external {
        _isValidBorrowerOrLoanAdmin();
        super._unpause();
    }

    /**
        @dev   Sets a Loan Admin. Only the Borrower can call this function.
        @dev   It emits a `LoanAdminSet` event.
        @param loanAdmin An address being allowed or disallowed as a Loan Admin.
        @param allowed   Status of a Loan Admin.
    */
    function setLoanAdmin(address loanAdmin, bool allowed) external {
        _whenProtocolNotPaused();
        _isValidBorrower();
        loanAdmins[loanAdmin] = allowed;
        emit LoanAdminSet(loanAdmin, allowed);
    }

    /**************************/
    /*** Governor Functions ***/
    /**************************/

    /**
        @dev   Transfers any locked funds to the Governor. Only the Governor can call this function.
        @param token Address of the token to be reclaimed.
    */
    function reclaimERC20(address token) external {
        LoanLib.reclaimERC20(token, address(liquidityAsset), _globals(superFactory));
    }

    /*********************/
    /*** FDT Functions ***/
    /*********************/

    /**
        @dev Withdraws all available funds earned through LoanFDT for a token holder.
        @dev It emits a `BalanceUpdated` event.
    */
    function withdrawFunds() public override {
        _whenProtocolNotPaused();
        super.withdrawFunds();
        emit BalanceUpdated(address(this), address(fundsToken), fundsToken.balanceOf(address(this)));
    }

    /************************/
    /*** Getter Functions ***/
    /************************/

    /**
        @dev    Returns the expected amount of Liquidity Asset to be recovered from a liquidation based on current oracle prices.
        @return The minimum amount of Liquidity Asset that can be expected by swapping Collateral Asset.
    */
    function getExpectedAmountRecovered() external view returns (uint256) {
        uint256 liquidationAmt = _getCollateralLockerBalance();
        return Util.calcMinAmount(_globals(superFactory), address(collateralAsset), address(liquidityAsset), liquidationAmt);
    }

    /**
        @dev    Returns information of the next payment amount.
        @return [0] = Entitled interest of the next payment (Principal + Interest only when the next payment is last payment of the Loan)
                [1] = Entitled principal amount needed to be paid in the next payment
                [2] = Entitled interest amount needed to be paid in the next payment
                [3] = Payment Due Date
                [4] = Is Payment Late
    */
    function getNextPayment() public view returns (uint256, uint256, uint256, uint256, bool) {
        return LoanLib.getNextPayment(repaymentCalc, nextPaymentDue, lateFeeCalc);
    }

    /**
        @dev    Returns the information of a full payment amount.
        @return total     Principal and interest owed, combined.
        @return principal Principal owed.
        @return interest  Interest owed.
    */
    function getFullPayment() public view returns (uint256 total, uint256 principal, uint256 interest) {
        (total, principal, interest) = LoanLib.getFullPayment(repaymentCalc, nextPaymentDue, lateFeeCalc, premiumCalc);
    }

    /**
        @dev    Calculates the collateral required to draw down amount.
        @param  amt The amount of the Liquidity Asset to draw down from the FundingLocker.
        @return The amount of the Collateral Asset required to post in the CollateralLocker for a given drawdown amount.
    */
    function collateralRequiredForDrawdown(uint256 amt) public view returns (uint256) {
        return LoanLib.collateralRequiredForDrawdown(
            IERC20Details(address(collateralAsset)),
            IERC20Details(address(liquidityAsset)),
            collateralRatio,
            superFactory,
            amt
        );
    }

    /************************/
    /*** Helper Functions ***/
    /************************/

    /**
        @dev Checks that the protocol is not in a paused state.
    */
    function _whenProtocolNotPaused() internal view {
        require(!_globals(superFactory).protocolPaused(), "L:PROTO_PAUSED");
    }

    /**
        @dev Checks that `msg.sender` is the Borrower or a Loan Admin.
    */
    function _isValidBorrowerOrLoanAdmin() internal view {
        require(msg.sender == borrower || loanAdmins[msg.sender], "L:NOT_BORROWER_OR_ADMIN");
    }

    /**
        @dev Converts to WAD precision.
    */
    function _toWad(uint256 amt) internal view returns (uint256) {
        return amt.mul(10 ** 18).div(10 ** IERC20Details(address(liquidityAsset)).decimals());
    }

    /**
        @dev Returns the MapleGlobals instance.
    */
    function _globals(address loanFactory) internal view returns (IMapleGlobals) {
        return IMapleGlobals(ILoanFactory(loanFactory).globals());
    }

    /**
        @dev Returns the CollateralLocker balance.
    */
    function _getCollateralLockerBalance() internal view returns (uint256) {
        return collateralAsset.balanceOf(collateralLocker);
    }

    /**
        @dev Returns the FundingLocker balance.
    */
    function _getFundingLockerBalance() internal view returns (uint256) {
        return liquidityAsset.balanceOf(fundingLocker);
    }

    /**
        @dev   Checks that the current state of the Loan matches the provided state.
        @param _state Enum of desired Loan state.
    */
    function _isValidState(State _state) internal view {
        require(loanState == _state, "L:INVALID_STATE");
    }

    /**
        @dev Checks that `msg.sender` is the Borrower.
    */
    function _isValidBorrower() internal view {
        require(msg.sender == borrower, "L:NOT_BORROWER");
    }

    /**
        @dev Checks that `msg.sender` is a Lender (LiquidityLocker) that is using an approved Pool to fund the Loan.
    */
    function _isValidPool() internal view {
        address pool        = ILiquidityLocker(msg.sender).pool();
        address poolFactory = IPool(pool).superFactory();
        require(
            _globals(superFactory).isValidPoolFactory(poolFactory) &&
            IPoolFactory(poolFactory).isPool(pool),
            "L:INVALID_LENDER"
        );
    }

    /**
        @dev Checks that "now" is currently within the funding period.
    */
    function _isWithinFundingPeriod() internal view {
        require(block.timestamp <= createdAt.add(fundingPeriod), "L:PAST_FUNDING_PERIOD");
    }

    /**
        @dev   Transfers funds from the FundingLocker.
        @param from  Instance of the FundingLocker.
        @param to    Address to send funds to.
        @param value Amount to send.
    */
    function _transferFunds(IFundingLocker from, address to, uint256 value) internal {
        from.pull(to, value);
    }

    /**
        @dev Emits a `BalanceUpdated` event for the Loan.
        @dev It emits a `BalanceUpdated` event.
    */
    function _emitBalanceUpdateEventForLoan() internal {
        emit BalanceUpdated(address(this), address(liquidityAsset), liquidityAsset.balanceOf(address(this)));
    }

    /**
        @dev Emits a `BalanceUpdated` event for the FundingLocker.
        @dev It emits a `BalanceUpdated` event.
    */
    function _emitBalanceUpdateEventForFundingLocker() internal {
        emit BalanceUpdated(fundingLocker, address(liquidityAsset), _getFundingLockerBalance());
    }

    /**
        @dev Emits a `BalanceUpdated` event for the CollateralLocker.
        @dev It emits a `BalanceUpdated` event.
    */
    function _emitBalanceUpdateEventForCollateralLocker() internal {
        emit BalanceUpdated(collateralLocker, address(collateralAsset), _getCollateralLockerBalance());
    }

}