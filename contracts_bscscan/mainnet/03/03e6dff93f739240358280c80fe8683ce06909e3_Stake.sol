/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.5.9;

// ----------------------------------------------------------------------------
// 'SafeBank' Staking smart contract
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// SafeMath library
// ----------------------------------------------------------------------------

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


interface sBANK {
    function balanceOf(address _owner) view external  returns (uint256 balance);
    // function transfer(address _to, uint256 _value) public  returns (bool success);
    // function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success);
    // function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) view external  returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    // function transfer(address _to, uint256 _amount) external  returns (bool success);
    function transfer(address _to, uint256 _amount) external  returns (bool success);
    function transferFrom(address _from,address _to,uint256 _amount) external  returns (bool success);
    function approve(address _to, uint256 _amount) external  returns (bool success);
    // function balanceOf(address _owner) external view returns (uint256 balance);
    function _mint(address account, uint256 amount) external ;
    
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract Stake is Owned {
    using SafeMath for uint256;
    address contractAddress;
    uint256 public WeekRewardPercent = 200;
    uint256 public TotalStakedOMB = 0;
    uint256 StakingFee = 10; // 2.5%
    uint256 UnstakingFee = 10; // 2.5% 
    uint256 private TeamFeesCollector = 0;
    uint256 private FeesCollectedForJustwap = 0;
    sBANK public tokenInstance;
    sBANK public rewardTkn;
    struct USER{
        uint256 stakedAmount;
        uint256 reward;
        uint256 creationTime; 
        uint256 TotalOMBRewarded;
    }
    
    mapping(address => USER) public stakers;
             
    mapping(address=>uint256) public amounts;
    
    
    event STAKED(address staker, uint256 tokens, uint256 StakingFee);
    event UNSTAKED(address staker, uint256 tokens, uint256 UnstakingFee);
    event CLAIMEDREWARD(address staker, uint256 reward);
    event PERCENTCHANGED(address operator, uint256 percent);
    event FkTake(uint256 amount);
    event JkTake(uint256 amount);
    constructor(address payable tokenAddress, address payable rewardToken)  public{
         tokenInstance=sBANK(tokenAddress);
         rewardTkn=sBANK(rewardToken);
         contractAddress=tokenAddress;
        
    }
    // ------------------------------------------------------------------------
    // Token holders can stake their tokens using this function
    // @param tokens number of tokens to stake
    // ------------------------------------------------------------------------
    function STAKE(uint256 tokens) external {
        require(tokenInstance.transferFrom(msg.sender, address(this), tokens), "Tokens cannot be transferred from user account");
        
        uint256 _stakingFee = 0;
        if(TotalStakedOMB > 0)
        _stakingFee= (onePercentofTokens(tokens).mul(StakingFee)).div(10); 
        
        
                if(amounts[msg.sender]>0)
        {
           uint256 time = now - stakers[msg.sender].creationTime; 
           uint256 daysCount = time.div(86400);
            if(daysCount>0)
            {
                    uint256  owing =  (amounts[msg.sender]).mul(daysCount);
                    stakers[msg.sender].reward = (stakers[msg.sender].reward).add(owing);
            }
        }
        
        stakers[msg.sender].stakedAmount = (tokens.sub(_stakingFee)).add(stakers[msg.sender].stakedAmount);
        stakers[msg.sender].creationTime = now;    
        TotalStakedOMB = TotalStakedOMB.add(tokens.sub(_stakingFee));
        uint256 percal = calPercentofTokens(stakers[msg.sender].stakedAmount,WeekRewardPercent);
        amounts[msg.sender] = percal;
        
        TeamFeesCollector = TeamFeesCollector.add(_stakingFee);
        
        emit STAKED(msg.sender, tokens.sub(_stakingFee), _stakingFee);
    
    }

    // ------------------------------------------------------------------------
    // Stakers can claim their pending rewards using this function
    // ------------------------------------------------------------------------
    function CLAIMREWARD() public {

        
 
           uint256 time = now - stakers[msg.sender].creationTime; 
           uint256 daysCount = time.div(300);
           
           if(daysCount > 0)
           {
                uint256  owing=0;
               if(amounts[msg.sender]>0)
               {
                   
                   uint a = daysCount * 300; 
                   a  = time.sub(a);
                   
                   
                   owing =  (amounts[msg.sender]).mul(daysCount);
                   if(a!=0)                       
                    owing = (owing.mul(a)).div(300);
                   if(stakers[msg.sender].reward >0)
                   {
                
                    owing = owing.add(stakers[msg.sender].reward);
                   }      
                   
               }
               else
               {
                   if(stakers[msg.sender].reward > 0)
                   {
                          owing = stakers[msg.sender].reward;
                   }else{
                       revert("No reward");
                   }
               }     
        
            require(rewardTkn.transfer(msg.sender,owing), "ERROR: error in sending reward from contract");
            emit CLAIMEDREWARD(msg.sender, owing);
            stakers[msg.sender].TotalOMBRewarded = (stakers[msg.sender].TotalOMBRewarded).add(owing);
            stakers[msg.sender].creationTime = now;
            stakers[msg.sender].reward = 0;
            
           }else
           {
                uint256  owing=0;
               if(amounts[msg.sender]>0)
               {
                    
                     owing =  ((amounts[msg.sender]).mul(time)).div(time);
                   if(stakers[msg.sender].reward >0)
                   {
                
                    owing = owing.add(stakers[msg.sender].reward);
                   }      
                   
               }
               else
               {
                   if(stakers[msg.sender].reward > 0)
                   {
                          owing = stakers[msg.sender].reward;
                   }else{
                       revert("No reward");
                   }
               }  
              
            require(rewardTkn.transfer(msg.sender,owing), "ERROR: error in sending reward from contract");
            emit CLAIMEDREWARD(msg.sender, owing);
            stakers[msg.sender].TotalOMBRewarded = (stakers[msg.sender].TotalOMBRewarded).add(owing);
            stakers[msg.sender].creationTime = now;
            stakers[msg.sender].reward = 0;
               
           }
           
    }

    function calculateReward(address user) public view returns(uint256 result){
        
        uint256 time = block.timestamp - stakers[user].creationTime; 
        uint256 daysCount = time.div(300);
           
            if(daysCount > 0)
           {
               
               
               uint256  owing=0;
               if(amounts[user]>0)
               {
                   
                   uint256 a = daysCount * 300; 
                   a  = time.sub(a);
                   
    
                   owing =  (amounts[user]).mul(daysCount);
                   if(a!=0)                       
                    owing = (owing.mul(a)).div(300);
                   if(stakers[user].reward >0)
                   {
                
                    owing = owing.add(stakers[user].reward);
                   }      
                   
               }
               else
               {
                   if(stakers[user].reward > 0)
                   {
                          owing = stakers[user].reward;
                   }else{
                       owing = 0;
                   }
               }     
               
               
               
               
               
                return owing;
            
           }
           else
           {
               uint256  owing=0;
               if(amounts[user]>0)
               {
                    
                     owing =  ((amounts[user]).mul(time)).div(300);
                   if(stakers[user].reward >0)
                   {
                
                    owing = owing.add(stakers[user].reward);
                   }      
                   
               }
               else
               {
                   if(stakers[user].reward > 0)
                   {
                          owing = stakers[user].reward;
                   }else{
                       owing = 0;
                   }
               }  
               
               
          return owing;
               
           }
           
            
    }
    
    function WITHDRAW(uint256 tokens) external {
        
        require(stakers[msg.sender].stakedAmount >= tokens && tokens > 0, "Invalid token amount to withdraw");
        
        uint256 _unstakingFee = (onePercentofTokens(tokens).mul(UnstakingFee)).div(10);
        
       
                if(amounts[msg.sender]>0)
        {
           uint256 time = now - stakers[msg.sender].creationTime; 
           uint256 daysCount = time.div(300);
            if(daysCount>0)
            {
                    uint256  owing =  (amounts[msg.sender]).mul(daysCount);
                    stakers[msg.sender].reward = (stakers[msg.sender].reward).add(owing);
            }
        }
       
       
                
        require(tokenInstance.transfer(msg.sender, tokens.sub(_unstakingFee)), "Error in un-staking tokens");
        
        stakers[msg.sender].stakedAmount = stakers[msg.sender].stakedAmount.sub(tokens);
        
        if(stakers[msg.sender].stakedAmount == 0)
        {
            stakers[msg.sender].creationTime = 0;
            amounts[msg.sender] = 0;
        }else{
            
            uint256 percal = calPercentofTokens(stakers[msg.sender].stakedAmount,WeekRewardPercent);
             amounts[msg.sender] = percal;
           
        }
        
        TotalStakedOMB = TotalStakedOMB.sub(tokens);
        FeesCollectedForJustwap =FeesCollectedForJustwap.add(_unstakingFee); 
        
        emit UNSTAKED(msg.sender, tokens.sub(_unstakingFee), _unstakingFee);
    }
    // ------------------------------------------------------------------------
    // Private function to calculate 1% percentage
    // ------------------------------------------------------------------------
    
    function onePercentofTokens(uint256 _tokens) private pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint onePercentofToken = roundValue.mul(100).div(100 * 10**uint(2));
        return onePercentofToken;
    }
    
    function calPercentofTokens(uint256 _tokens, uint256 cust) private pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint256 custPercentofTokens = roundValue.mul(cust).div(100 * 10**uint(2));
        return custPercentofTokens;
    }

    // ------------------------------------------------------------------------
    // Get the number of tokens staked by a staker
    // param _staker the address of the staker
    // ------------------------------------------------------------------------
    function yourStakedOMB(address staker) external view returns(uint256 stakedOMB){
        return stakers[staker].stakedAmount;
    }
    
    // ------------------------------------------------------------------------
    // Get the SNTM balance of the token holder
    // @param user the address of the token holder
    // ------------------------------------------------------------------------
    function yourOMBBalance(address user) external view returns(uint256 OMBBalance){
        return tokenInstance.balanceOf(user);
    }
    
    function setPercent(uint256 percent) public onlyOwner {
        
        if(percent >= 1)
        {
         WeekRewardPercent = percent;    
         emit PERCENTCHANGED(msg.sender, percent);
        }
         
    }

    function OwnerTeamFeesCollectorRead() external view returns(uint256 jKeeper) {
        return TeamFeesCollector;
    }
    
    function OwnerFeesCollectedForJustwapRead() external view returns(uint256 Fkeeper) {
        return FeesCollectedForJustwap;
    }
    
    function OwnerFKtake() external onlyOwner{
        
      address payable r=owner;   
      r.transfer(TeamFeesCollector);
      TeamFeesCollector = 0;
      emit FkTake(TeamFeesCollector);
    }

    function OwnerJustSwaptake() external onlyOwner{
        
      address payable r=owner;   
      r.transfer(FeesCollectedForJustwap);
      FeesCollectedForJustwap = 0;
      emit JkTake(FeesCollectedForJustwap);
    }
    
}