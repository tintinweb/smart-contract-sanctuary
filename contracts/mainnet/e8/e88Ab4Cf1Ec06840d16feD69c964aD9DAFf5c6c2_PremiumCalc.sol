/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

// SPDX-License-Identifier:  AGPL-3.0-or-later // hevm: flattened sources of contracts/PremiumCalc.sol
pragma solidity =0.6.11 >=0.6.0 <0.8.0;

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

////// contracts/PremiumCalc.sol
/* pragma solidity 0.6.11; */

/* import "lib/openzeppelin-contracts/contracts/math/SafeMath.sol"; */

/* import "./interfaces/ILoan.sol"; */

/// @title PremiumCalc calculates premium fees on Loans.
contract PremiumCalc {

    using SafeMath for uint256;

    uint8   public constant calcType = 12;      // PREMIUM type.
    bytes32 public constant name     = "FLAT";

    uint256 public immutable premiumFee;  // Flat percentage fee (in basis points) of principal to charge as a premium when calling a Loan.

    constructor(uint256 _premiumFee) public {
        premiumFee = _premiumFee;
    }

    /**
        @dev    Calculates the premium payment for a Loan, when making a full payment.
        @param  _loan         The address of a Loan to calculate a premium payment for.
        @return total         Principal + Interest.
        @return principalOwed Principal.
        @return interest      Interest.
    */
    function getPremiumPayment(address _loan) external view returns (uint256 total, uint256 principalOwed, uint256 interest) {
        principalOwed = ILoan(_loan).principalOwed();
        interest      = principalOwed.mul(premiumFee).div(10_000);
        total         = interest.add(principalOwed);
    }

}