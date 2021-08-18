pragma experimental ABIEncoderV2;
pragma solidity ^0.5.16;
import {IHC_TEST} from 'ihc_test_token.sol';

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
    */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract IHC_TEST_LOAN {
    using SafeMath for uint256;
    struct Terms {
        uint256 collateralAmount;
        uint repayByType;
    }
    
    Terms public terms;
    enum LoanState{Created, Funded, Taken}
    LoanState public state;
    address payable public lender;
    address payable public borrower;
    address public ihcTokenAddress;
    uint256 repayByTimestamp;
    uint loanDuration;
    uint256 feePercent;
    uint256 loanAmount;
    uint256 loanMinAmount;
    constructor (
        Terms memory _terms
    ) public payable{
        terms = _terms;
        if(terms.repayByType == 1) {
            repayByTimestamp = block.timestamp + 30 days;
            loanDuration = 30;
        }else if(terms.repayByType == 2) {
            repayByTimestamp = block.timestamp + 90 days;
            loanDuration = 90;
        }else if(terms.repayByType == 3) {
            repayByTimestamp = block.timestamp + 180 days;
            loanDuration = 180;
        }else if(terms.repayByType == 4) {
            repayByTimestamp = block.timestamp + 365 days;
            loanDuration = 365;
        }else {
            revert();
        }
        ihcTokenAddress = 0x5B500Fae664c81aEfC3931A967DC0fA348982d11;
        lender = IHC_TEST(ihcTokenAddress).getLoanPoolAddress();
        state = LoanState.Created;
        
        feePercent = IHC_TEST(ihcTokenAddress).getLoanFeePercent();
        loanAmount = terms.collateralAmount * IHC_TEST(ihcTokenAddress).getLoanSizePercent() / 100;
    }
    
    modifier onlyInState(LoanState expectedState) {
        require(state == expectedState, "Not allowed in this state");
        _;
    }
    
    function getIhcTokenAddress() public view returns(address) {
        
        return ihcTokenAddress;
    }
    
    function getThisContractAddress() public view returns(address) {
        
        return address(this);
    }
    
    function getLoanPoolAddress() public view returns(address) {
        
        return lender;
    }
    
    function getBalanceOfPool() public view returns(uint256) {
        
        return IHC_TEST(ihcTokenAddress).balanceOf(lender);
    }
    
    function getLoanAmount() public view returns(uint256) {
        
        return loanAmount;
    }
    
    function checkTokenAllowance(address owner) public view returns (uint256) {
        return IHC_TEST(ihcTokenAddress).allowance(owner, address(this));
    }
    
    function takeALoanAndAcceptLoanTerms(uint256 _collateralAmount) public payable onlyInState(LoanState.Created) {
        require(_collateralAmount == terms.collateralAmount, "Invalid collateral amount");
        require(_collateralAmount >= IHC_TEST(ihcTokenAddress).getLoanMinAmount(), "Minimum loan amount not met");
        borrower = msg.sender;
        state = LoanState.Taken;
        
        // grant allowance on token smart contract
        IHC_TEST(ihcTokenAddress).transferFrom(borrower, address(this), _collateralAmount);
        
        // grant allowance on token smart contract
        IHC_TEST(ihcTokenAddress).transferFrom(lender, borrower, loanAmount);
    }
    
    function repay() public onlyInState(LoanState.Taken) {
        require(msg.sender == borrower, "Only the borrower can repay the loan");
        uint feeAmount = ((loanAmount * feePercent) / 100 / 365) * loanDuration;
        IHC_TEST(ihcTokenAddress).transferFrom(borrower, lender, loanAmount.add(feeAmount));
        selfdestruct(borrower);
    }
    
    function liquidate() public onlyInState(LoanState.Taken) {
        require(msg.sender == lender, "Only the lender can liquidate the loan");
        require(block.timestamp >= repayByTimestamp, "Can not liquidate before the loan is due");
        IHC_TEST(ihcTokenAddress).transfer(lender, terms.collateralAmount);
        selfdestruct(lender);
    }
}