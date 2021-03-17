/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.8.0;

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

abstract contract MSH {
    function transfer(address _to, uint256 _value) public virtual returns(bool success);
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool);
}

contract Staking{
    using SafeMath for uint;
    using SafeMath for uint8;

    MSH mn;
    address public owner;
    uint public minStakeAmount;
    
    // events
    event Stake(uint amount, address indexed staker);
    event Unstake(uint amount, address indexed unstaker);
    
    struct Investment {
        uint lockUntill;
        uint stakeAmount;
        uint8 lockPeriod;
    }
    
    mapping(address => uint) investmentCount;
    mapping(address => mapping(uint => Investment)) investments;
    mapping(address => uint) totalAmountStaked;
    
      
    constructor(address MSHAddress, uint minimumStakeAmount) public {
        owner = msg.sender;
        mn = MSH(MSHAddress);
        minStakeAmount = minimumStakeAmount;
    }
    
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

    modifier verifyStakingConditions(uint amountToStake, uint8 lockingPeriod) {
        require(amountToStake >= minStakeAmount, "Stake Amount should be greater than minimum stake amount");
        require(lockingPeriod >= 1 && lockingPeriod <= 4, "Locking period can be only 1 to 4");
        _;
    }

    modifier verifyUnstakingConditions(){
        require(investmentCount[msg.sender]>0,"there must be a stake");
        _;
    }
    

    function stakeAmount(uint amount, uint8 lockingPeriod) public verifyStakingConditions(amount, lockingPeriod) returns(bool){
        // calculating the next investmentCount
        uint nextInvestmentCount = investmentCount[msg.sender];  
        //saving the amount into investments mapping
        Investment memory investment = Investment({
            stakeAmount: amount,
            lockUntill: getLockingPeriod(lockingPeriod),
            lockPeriod: lockingPeriod
        }); 
        investments[msg.sender][nextInvestmentCount + 1] = investment;
        
        // trasnfering the token
        require(mn.transferFrom(msg.sender, address(this), amount));

        // saving totalAmountStaked by user till now
        totalAmountStaked[msg.sender] = (totalAmountStaked[msg.sender]).add(amount);
        investmentCount[msg.sender] = (investmentCount[msg.sender]).add(1);
        emit Stake(amount, msg.sender);
        return true;
    }


    function unstakeAmount() public verifyUnstakingConditions() returns (bool){
        require(investmentCount[msg.sender] > 0);
        uint withdrawableAmount=0;
        for(uint i=1;i<=investmentCount[msg.sender];i++)
        {
            if(investments[msg.sender][i].lockUntill <= block.timestamp)
            {
            withdrawableAmount = withdrawableAmount.add(investments[msg.sender][i].stakeAmount);
            investments[msg.sender][i].stakeAmount=0;
            }
        }

        //transfer the token back
        require(mn.transfer(msg.sender, withdrawableAmount));
        
        // subtract user totalAmountStaked
        totalAmountStaked[msg.sender] = (totalAmountStaked[msg.sender]).sub(withdrawableAmount);
        
        emit Unstake(withdrawableAmount, msg.sender);
        return true;
    }

    function stakedAmountByUser(address user) public view returns(uint){
        return totalAmountStaked[user];
    }
    
    function getLockingPeriod(uint8 lockingPeriod) private view returns (uint) {
        if(lockingPeriod == 1){
            return block.timestamp + 5 minutes;
        }else if(lockingPeriod == 2) {
             return block.timestamp + 10 minutes;
        }else if(lockingPeriod == 3) {
             return block.timestamp + 15 minutes;
        }else if(lockingPeriod == 4) {
             return block.timestamp + 20 minutes;
        }
    }
    
    function getCurrentTimeStamp() public view returns(uint) {
        return block.timestamp;
    }
    
    function investmentTimeStamp(uint stakeInvestmentCount) public view returns(uint) {
        return (investments[msg.sender][stakeInvestmentCount]).lockUntill;
    }
    
}