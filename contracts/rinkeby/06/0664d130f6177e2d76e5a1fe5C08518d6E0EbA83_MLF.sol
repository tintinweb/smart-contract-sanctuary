// Team MLF
// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.5.11 <= 0.8.2;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/upgrades/contracts/Initializable.sol';

contract MLF is Initializable {

    using SafeMath for uint256;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);
    event Repaid(address indexed payee, uint256 weiAmount);
    event Approved(address indexed approvedPayee);

    struct LoanInfo {
        uint256 loanTimestamp;
        uint16 loanPeriod;
// interest charged for the loan period. Accounting for the possibility that the lowest interest rate is 0.1%, so
// the value in interest field should be multiplied by 10?
        uint16 interest;         
        bool approved;           // default is false, which means not approved
        uint256 dateWithdrawn;
        address approvingOfficer;
        uint256 borrowAmount;
        uint256 repayAmount;
    }
    
    address[3] public owners;
    mapping(address => LoanInfo) loanInfo;

    modifier noOutstandingLoan() {
        require(loanInfo[msg.sender].borrowAmount == 0, "Borrower has outstanding loan!");
        _;
    } 

    modifier onlyApproved() {
        require(loanInfo[msg.sender].approved, "Loan has not been approved!");
        _;
    }

    modifier validBorrower() {
        require(loanInfo[msg.sender].borrowAmount > 0, 
          "Borrower does not have an outstanding loan application!");
        _;
    }

    function owner1() internal view returns (address result) {
        result = owners[0];
    }

    function owner2() internal view returns (address result) {
        result = owners[1];
    }

    function owner3() internal view returns (address result) {
        result = owners[2];
    }

    modifier validOwners() {
        require(
            owner1() != address(0x0) || 
            owner2() != address(0x0) || 
            owner3() != address(0x0),
          "None of the owners are valid!");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner1() || msg.sender == owner2() || msg.sender == owner3(), 
          "msg.sender is not owner!");
        _;
    }

    modifier sufficientBalance() {
        require(loanInfo[msg.sender].borrowAmount > 0, 
          "Loan amount is larger than available balance!");
        _;
    }

    function setOwner(uint8 index, address _owner) public onlyOwner {
        owners[index] = _owner;
    }

    function initialize(address _owner1) public initializer {
        owners[0] = _owner1;        
    }    
    
    function deposit() public payable {
        emit Deposited(msg.sender, msg.value);
    }

    // Called by the person borrowing the money
    // Checks that the loan has been approved.
    // Checks that there is sufficient balance.
    function withdraw() public onlyApproved sufficientBalance validOwners {
        LoanInfo storage localLoanInfo = loanInfo[msg.sender];
        uint256 loanAmount = localLoanInfo.borrowAmount;
        localLoanInfo.borrowAmount = localLoanInfo.borrowAmount.sub(loanAmount);
        localLoanInfo.dateWithdrawn = block.timestamp;
        msg.sender.transfer(loanAmount);
        emit Withdrawn(msg.sender, loanAmount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // loanPeriod is in terms of months
    // function is called by the borrower
    function applyLoan(uint256 borrowAmount, uint16 interest, uint16 loanPeriod) public 
      noOutstandingLoan validOwners {
        LoanInfo storage localLoanInfo = loanInfo[msg.sender];
        localLoanInfo.borrowAmount = borrowAmount;
        localLoanInfo.interest = interest;
        localLoanInfo.loanPeriod = loanPeriod;

        // automatic loan approval due to time constraint
        // This shouldn't be automatic
        _approveLoan(owner1(), msg.sender);
    }

    // Approves loan for the borrower, with the approving officer being msgSender
    function _approveLoan(address msgSender, address borrower) internal {
        LoanInfo storage localLoanInfo = loanInfo[borrower];
        localLoanInfo.approved = true;
        localLoanInfo.approvingOfficer = msgSender;
        emit Approved(borrower);
    }

    // Called by one of the owners, approves the loan for the specified borrower
    function approveLoan(address borrower) public onlyOwner {
        _approveLoan(msg.sender, borrower);
    }

    // clears a loan, to be called by one of the owners
    function clearLoan(address borrower) public onlyOwner {
        LoanInfo memory localLoanInfo;
        loanInfo[borrower] = localLoanInfo;
    }

    // Called by the borrower
    // Ensures that the borrower has an outstanding loan.
    // Amount repaid is in msg.value
    function payLoan() public payable validBorrower {
        LoanInfo storage localLoanInfo = loanInfo[msg.sender];
        localLoanInfo.repayAmount = localLoanInfo.repayAmount.add(msg.value);
        emit Repaid(msg.sender, msg.value);
    }

    function getLoan(address borrower) public view returns (LoanInfo memory result) {
        result = loanInfo[borrower];
    }

}

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}