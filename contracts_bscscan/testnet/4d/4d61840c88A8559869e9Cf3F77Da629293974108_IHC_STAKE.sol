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
    uint256 withdrawByTimestamp;
    uint256 stakeAmount;
    uint apy;
    uint stakeDays;
    
    constructor () public payable{
        ihcTokenAddress = 0x864D8c4413e482c56f43DfFFFD9f2d11201B83eC;
        stakePoolAddress = 0x64D940aA965E12ac00637E0F7f4370592dD807ab;
        state = LoanState.Created;
        apy = IHC_TEST(ihcTokenAddress).getApy();
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
    
    function stake(uint256 _stakeAmount, uint _daysAfter) public payable onlyInState(LoanState.Created) {
        state = LoanState.Funded;
        withdrawByTimestamp = block.timestamp + _daysAfter * 1 days;
        staker = msg.sender;
        stakeDays = _daysAfter;
        stakeAmount = _stakeAmount;
        IHC_TEST(ihcTokenAddress).transfer(stakePoolAddress, stakeAmount);
    }
    
    function withdraw() public onlyInState(LoanState.Funded) {
        require(msg.sender == staker, "Only the staker can withdraw the stake");
        
        uint256 yeildAmount = ((stakeAmount * apy) / 100) / 365 * stakeDays;
        IHC_TEST(ihcTokenAddress).transferFrom(stakePoolAddress, staker, stakeAmount.add(yeildAmount));
        selfdestruct(staker);
    }
}