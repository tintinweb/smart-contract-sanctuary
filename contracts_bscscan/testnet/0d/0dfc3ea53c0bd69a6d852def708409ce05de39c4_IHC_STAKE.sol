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

contract IHC_STAKE {
    using SafeMath for uint256;
    
    enum LoanState{Created, Funded}
    LoanState public state;
    address payable public staker;
    address payable public stakePoolAddress;
    address public ihcTokenAddress;
    uint256 withdrawDeadlineByTimestamp;
    uint256 stakeAmount;
    uint apy;
    uint stakeDays;
    uint256 stakeMinAmount;
    
    constructor () public payable{
        ihcTokenAddress = 0x5B500Fae664c81aEfC3931A967DC0fA348982d11;
        state = LoanState.Created;
        apy = IHC_TEST(ihcTokenAddress).getApy();
        stakePoolAddress = IHC_TEST(ihcTokenAddress).getStakePoolAddress();
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
    
    function getBalanceOfPool() public view returns(uint256) {
        
        return IHC_TEST(ihcTokenAddress).balanceOf(stakePoolAddress);
    }
    
    function getStakeAmount() public view returns(uint256) {
        
        return stakeAmount;
    }
    
    function getStakeApy() public view returns(uint) {
        return apy;
    }
    
    function getYieldAmount() public view returns(uint256) {
        uint256 yeildAmount = ((stakeAmount * apy) / 100) / 365 * stakeDays;
        return yeildAmount;
    }
    
    function getWithdrawDeadlineByTimestamp() public view returns(uint256) {
        return withdrawDeadlineByTimestamp;
    }
    
    function stake(uint256 _stakeAmount, uint _daysAfter) public onlyInState(LoanState.Created) {
        require(_stakeAmount >= IHC_TEST(ihcTokenAddress).getStakeMinAmount(), "Minimum stake amount not met");
        state = LoanState.Funded;
        withdrawDeadlineByTimestamp = block.timestamp + _daysAfter * 1 days;
        staker = msg.sender;
        stakeDays = _daysAfter;
        stakeAmount = _stakeAmount;
        IHC_TEST(ihcTokenAddress).transferFrom(msg.sender, stakePoolAddress, stakeAmount);
    }
    
    function withdraw() public onlyInState(LoanState.Funded) {
        require(msg.sender == staker, "Only the staker can withdraw the stake");
        require(block.timestamp >= withdrawDeadlineByTimestamp, "It's not time to end");
        
        uint256 yeildAmount = ((stakeAmount * apy) / 100) / 365 * stakeDays;
        IHC_TEST(ihcTokenAddress).transferFrom(stakePoolAddress, staker, stakeAmount.add(yeildAmount));
        selfdestruct(staker);
    }
}