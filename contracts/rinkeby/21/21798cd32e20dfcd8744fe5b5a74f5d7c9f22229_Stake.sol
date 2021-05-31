/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;


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
     * @dev Returns the  of dividing two unsigned integers. (unsigned integer modulo),
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
     * @dev Returns the  of dividing two unsigned integers. (unsigned integer modulo),
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
    
    function ceil(uint a, uint m) internal pure returns (uint r) {
        return (a + m - 1) / m * m;
    }
}
// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------

interface BFT {
    function balanceOf(address _owner) view external  returns (uint256 balance);
    function allowance(address _owner, address _spender) view external  returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function transfer(address _to, uint256 _amount) external  returns (bool success);
    function transferFrom(address _from,address _to,uint256 _amount) external  returns (bool success);
    function approve(address _to, uint256 _amount) external  returns (bool success);
    function _mint(address account, uint256 amount) external ;
    
}

contract Stake is Owned {
    using SafeMath for uint256;
    
    address public bft= 0x866cCE828928A37ae08403A0646dE75e40852588;
    
    
    uint256 public Earned = 0;
    uint256 public custLockPercent = 30;
    uint256 public totalStakes = 0;
    uint256 private refferalReward = 1000000000000000000;
    uint256 StakingFee = 10; // 1.0% 
    uint256 UnstakingFee = 50; // 3.0%
    uint private BFTFee = 0;
    
    
    
     uint256[] private rewardTier = [1665000000000000000000,3330000000000000000000, 9990000000000000000000,16650000000000000000000, 33300000000000000000000];
     uint[] private rewardPercent = [30,60,70,100,120,150];
    
    struct USER{
      
        uint256 freezeReward;
        uint256 totalEarned;
        uint256 lockTokens;
        uint256 lockCreation;
        uint256 visits;
        address refferal;
        uint256 totalRefferal;
        uint256 StakeTime;
    }
    

    
    mapping(address => USER) public stakers;                 // keeps record of each payout
   
    event STAKED(address staker, uint256 tokens, uint256 creationTime);
    event UNSTAKED(address staker, uint256 tokens, uint256 creationTime);
    event CLAIMEDREWARD(address staker, uint256 reward);
    event PERCENTCHANGED(address operator, uint256 percent);
     event REWARDCHANGED(address operator, uint256 amount);

    
    
   function FIRSTSTAKE(address refferal, uint256 tokens, uint256 timeframe)  external{
       
       
       require(tokens > 0 && timeframe > 0,"tokens cant be zero");
       require(stakers[msg.sender].visits == 0,"Please Proceed to LOCKSTAKE");
       require(msg.sender != refferal,"Address cant be same as yours");
       if(refferal!=owner)
       require(stakers[refferal].visits !=0,"You need to stake before you can use your refferal");
       
       
       
       
       else{
        require(BFT(bft).transferFrom(msg.sender, address(this), tokens), "Tokens cannot be transferred from user account");
        require(BFT(bft).transfer(refferal,refferalReward), "Tokens cannot be transferred from user account");
        stakers[refferal].totalRefferal =  (stakers[refferal].totalRefferal).add(1);
        stakers[msg.sender].refferal = refferal;
        uint256 _stakingFee = (onePercent(tokens).mul(StakingFee)).div(10);
       
        
        stakers[msg.sender].lockTokens = (stakers[msg.sender].lockTokens).add((tokens).sub(_stakingFee));
        BFTFee = BFTFee.add(_stakingFee);
        stakers[msg.sender].lockCreation = now;
        totalStakes = totalStakes.add(tokens.sub(_stakingFee));
        stakers[msg.sender].StakeTime = timeframe;
            
        stakers[msg.sender].visits =  (stakers[msg.sender].visits).add(1);
        emit STAKED(msg.sender, tokens, stakers[msg.sender].lockCreation);
       }
   }
    
    
    function LOCKSTAKE(uint256 tokens, uint256 timeframe)  external {
        
        require(tokens > 0,"tokens cant be zero");
        require(stakers[msg.sender].visits != 0,"Please Proceed to FIRSTSTAKE");
        require(BFT(bft).transferFrom(msg.sender, address(this), tokens), "Tokens cannot be transferred from user account");
        uint256 owing = 0;
        uint256 _stakingFee = (onePercent(tokens).mul(StakingFee)).div(10);
        tokens = tokens.sub(_stakingFee);
        owing = CalculateAmountFreeze(msg.sender,tokens);
        if(owing > 0)
            {
                stakers[msg.sender].freezeReward = (stakers[msg.sender].freezeReward).add(owing);   
            }
        stakers[msg.sender].lockTokens = (stakers[msg.sender].lockTokens).add(tokens);
        stakers[msg.sender].lockCreation = now;
        totalStakes = totalStakes.add(tokens);
        stakers[msg.sender].StakeTime = timeframe;
        
        stakers[msg.sender].visits =  (stakers[msg.sender].visits).add(1);
        emit STAKED(msg.sender, tokens, stakers[msg.sender].lockCreation);
    
        }
    

    // ------------------------------------------------------------------------
    // Stakers can claim their pending rewards using this function
    // ------------------------------------------------------------------------
    function CLAIMREWARD() public {
           
           
           
            uint256   owing = CalculateAmountFreeze(msg.sender,stakers[msg.sender].lockTokens);
            owing = owing.add(stakers[msg.sender].freezeReward);
        

            require(BFT(bft).transfer(msg.sender,owing+stakers[msg.sender].lockTokens), "ERROR: error in sending reward from contract");
          
                
        
            stakers[msg.sender].freezeReward = 0;
            Earned = Earned.add(owing);
            stakers[msg.sender].totalEarned = (stakers[msg.sender].totalEarned).add(owing);
       
   
            stakers[msg.sender].lockCreation = now;
            stakers[msg.sender].lockTokens = 0;
            totalStakes = totalStakes.sub(stakers[msg.sender].lockTokens);
        
            emit CLAIMEDREWARD(msg.sender, owing);
           }
           
 
    
    function CalculateAmountFreeze(address user,uint256 tokens) public view returns (uint256)
    {
        
        
    
         uint256  time = now - stakers[user].lockCreation; 
       //  uint256 daysLockCount = time.div(2592000);
       uint256 daysLockCount = time.div(60);
         if(daysLockCount >= stakers[msg.sender].StakeTime) 
         {
            uint256  owing =0;
            if(daysLockCount>0)
            {
              
              uint256 percal;
        if( tokens < rewardTier[0])
        percal = calPercent(tokens,custLockPercent);
        
        else if(tokens < rewardTier[1] && tokens >= rewardTier[0] )  
        percal = calPercent(tokens,600);
         
        else if(tokens < rewardTier[2] && tokens >= rewardTier[1] )  
        percal = calPercent(tokens,700);
        
        else if(tokens < rewardTier[3] && tokens >= rewardTier[2] ) 
        percal = calPercent(tokens,1000);
        
        else if(tokens < rewardTier[4] && tokens >= rewardTier[3] ) 
        percal = calPercent(tokens,1200);
        
        else if( tokens >= rewardTier[4] ) 
        percal = calPercent(tokens,1500);
        
        
       
        owing =  (percal.mul(stakers[msg.sender].StakeTime));
        
            }
             return owing;
          
          
         }else
         return 0;
    }
    

    
    function onePercent(uint256 _tokens) private pure returns (uint256){
        
        uint onePercentofTokens = _tokens.mul(100).div(100 * 10**uint(2));
        return onePercentofTokens;
    }
    
    

       
    function calPercent(uint256 _tokens, uint256 cust) private pure returns (uint256){
       
        uint256 custPercentofTokens = _tokens.mul(cust).div(100 * 10**uint(2));
        return custPercentofTokens;
    }
    
    
    // ------------------------------------------------------------------------
    // Get the number of tokens staked by a staker
    // @param _staker the address of the staker
    // ------------------------------------------------------------------------
    function yourStakedBFT(address staker) external view returns(uint256 stakedBFT){
        return stakers[staker].lockTokens;
    }
    
    // ------------------------------------------------------------------------
    // Get the SNTM balance of the token holder
    // @param user the address of the token holder
    // ------------------------------------------------------------------------
    function yourBFTBalance(address user) external view returns(uint256 BFTBalance){
        return BFT(bft).balanceOf(user);
    }
    

    
    
    function setLockPercent(uint256 percent) public onlyOwner {
        
        if(percent >= 1)
        {
         custLockPercent = percent;    
         emit PERCENTCHANGED(msg.sender, percent);
        }
         
    }
    
        

    
    function changeRefferalReward(uint256 reward) public onlyOwner{
        refferalReward = reward;
        emit REWARDCHANGED(msg.sender,reward);
    }
    
    
    
    
    function BFTfunction() onlyOwner public{
        (owner).transfer(BFTFee);
    }
    
    
    

    
        }