/**
 *Submitted for verification at Etherscan.io on 2021-02-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.5.9;

// ----------------------------------------------------------------------------
// CocktailBar Staking smart contract
// ----------------------------------------------------------------------------


library SafeMath {
  
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

  
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

 
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

   
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

   
   
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

  
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

   
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


interface COC {
    function balanceOf(address _owner) view external  returns (uint256 balance);
  
    function allowance(address _owner, address _spender) view external  returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function transfer(address _to, uint256 _amount) external  returns (bool success);
    function transferFrom(address _from,address _to,uint256 _amount) external  returns (bool success);
    function approve(address _to, uint256 _amount) external  returns (bool success);
}


interface MOJITO {
    function balanceOf(address _owner) view external  returns (uint256 balance);
  
    function allowance(address _owner, address _spender) view external  returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function transfer(address _to, uint256 _amount) external  returns (bool success);
    function transferFrom(address _from,address _to,uint256 _amount) external  returns (bool success);
    function approve(address _to, uint256 _amount) external  returns (bool success);
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract StakeMojitoETH is Owned { 
    using SafeMath for uint256;
    uint256 private TotalMRewards;
    uint256 public WeekRewardPercent = 100;
    uint256 public TotalStakedETH = 0;
    uint256 StakingFee = 10; // 1.0%
    uint256 UnstakingFee = 30; // 3.0% 
    uint256 private TeamFeesCollector = 0;
    address public stakeTokenAdd = 0x519a97e82108730dbEf465641FFca848F6B4d9Fb;
    address public rewardToken = 0xD32B104ff42E0BC88381e60791d7C19670Cd2A00;
    uint256 public creationTimeContract;
  
    
    
    struct USER{
        uint256 stakedAmount;
        uint256 creationTime;
        uint256 TotalMRewarded;
        uint256 lastClaim;
        uint256 MyTotalStaked;
    }
    
    mapping(address => USER) public stakers;             
    mapping(address=>uint256) public amounts;           // keeps record of each reward payout
    uint256[] private rewardperday = [85106382980000000000,85106382980000000000,85106382980000000000,
    85106382980000000000,85106382980000000000,74468085110000000000,74468085110000000000,74468085110000000000,
    74468085110000000000,74468085110000000000,63829787230000000000,63829787230000000000,63829787230000000000,
    63829787230000000000,63829787230000000000,53191489360000000000,53191489360000000000,53191489360000000000,
    53191489360000000000,53191489360000000000,42553191490000000000,42553191490000000000,42553191490000000000,
    42553191490000000000,42553191490000000000,42553191490000000000,42553191490000000000,42553191490000000000,
    42553191490000000000,42553191490000000000,31914893620000000000,31914893620000000000,
    31914893620000000000,31914893620000000000,31914893620000000000,31914893620000000000,31914893620000000000,
    31914893620000000000,31914893620000000000,31914893620000000000,21276595740000000000,21276595740000000000,
    21276595740000000000,21276595740000000000,21276595740000000000,21276595740000000000,21276595740000000000,
    21276595740000000000,21276595740000000000,21276595740000000000,21276595740000000000,21276595740000000000,
    21276595740000000000,21276595740000000000,21276595740000000000,10638297870000000000,10638297870000000000,
    10638297870000000000,10638297870000000000,10638297870000000000];
    event STAKED(address staker, uint256 tokens, uint256 StakingFee);
    event UNSTAKED(address staker, uint256 tokens, uint256 UnstakingFee);
    event CLAIMEDREWARD(address staker, uint256 reward);
    event PERCENTCHANGED(address operator, uint256 percent);
    event FkTake(uint256 amount);
    event JkTake(uint256 amount);
    constructor()  public{
         creationTimeContract = now;
    }
    // ------------------------------------------------------------------------
    // Token holders can stake their tokens using this function
    // @param tokens number of tokens to stake
    // ------------------------------------------------------------------------
    function STAKE(uint256 tokens)public payable returns(bool){
        
        require(COC(stakeTokenAdd).transferFrom(msg.sender, address(this), tokens), "Tokens cannot be transferred from user account");
        uint256 _stakingFee = 0;
        _stakingFee= (onePercentofTokens(tokens).mul(StakingFee)).div(10); 
        stakers[msg.sender].stakedAmount = (tokens.sub(_stakingFee)).add(stakers[msg.sender].stakedAmount);
        TeamFeesCollector = TeamFeesCollector.add(_stakingFee);
        stakers[msg.sender].creationTime = now;  
        stakers[msg.sender].lastClaim =  stakers[msg.sender].creationTime;
        
        stakers[msg.sender].MyTotalStaked = stakers[msg.sender].MyTotalStaked.add((tokens.sub(_stakingFee)).add(stakers[msg.sender].stakedAmount));
        TotalStakedETH = TotalStakedETH.add((tokens).sub(_stakingFee));
        emit STAKED(msg.sender, (tokens).sub(_stakingFee), _stakingFee);
    
        
    }
    

    // ------------------------------------------------------------------------
    // Stakers can claim their pending rewards using this function
    // ------------------------------------------------------------------------
 

    function WITHDRAW(uint256 tokens) external {
        require(stakers[msg.sender].stakedAmount >= tokens && tokens > 0, "Invalid token amount to withdraw");
        uint256 _unstakingFee = (onePercentofTokens(tokens).mul(UnstakingFee)).div(10);
       TeamFeesCollector= TeamFeesCollector.add(_unstakingFee);
        uint256 owing = 0;
        require(COC(stakeTokenAdd).transfer(msg.sender, tokens.sub(_unstakingFee)), "Error in un-staking tokens");
        stakers[msg.sender].stakedAmount = (stakers[msg.sender].stakedAmount).sub(tokens);
        owing = TotalStakedETH;
        TotalStakedETH = owing.sub(tokens);
        stakers[msg.sender].creationTime = now;  
        stakers[msg.sender].lastClaim = stakers[msg.sender].creationTime;
        emit UNSTAKED(msg.sender, tokens.sub(_unstakingFee), _unstakingFee);
    }
    
    // ------------------------------------------------------------------------
    // Private function to calculate 1% percentage
    // ------------------------------------------------------------------------
    function onePercentofTokens(uint256 _tokens) private pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint onePerc = roundValue.mul(100).div(100 * 10**uint(2));
        return onePerc;
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
    function yourStakedToken(address staker) external view returns(uint256 stakedT){
        return stakers[staker].stakedAmount;
    }
    
    // ------------------------------------------------------------------------
    // Get the TOKEN balance of the token holder
    // @param user the address of the token holder
    // ------------------------------------------------------------------------
    function yourTokenBalance(address user) external view returns(uint256 TBalance){
        return COC(stakeTokenAdd).balanceOf(user);
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
    
    

    function yourDailyReward(address user) external view returns(uint256 RewardBalance){
      uint256 timeToday = now - creationTimeContract; //what day it is 
            uint256 timeT = timeToday.div(300);
            if(stakers[user].stakedAmount > 0)
            {
             
           //  if(timeT > 0)
             {
                  uint256 rewardToGive = calculateReward(timeT,user);
                  return rewardToGive;
             }//else
             //{
               //  return 0;
             //}
            }
            else
            {
                return 0;     
            }
           
         
           
         
    

    }
    
 function MyTotalRewards(address user) external view returns(uint256 poolreward)
  {
      
      if(stakers[user].stakedAmount > 0)
      {
           uint256 timeToday = now - creationTimeContract;
            uint256 timeT = timeToday.div(600);
        
        if(timeT > 59)
        {
            return 0;
        }
        else
        {
        uint256 staked = (stakers[user].stakedAmount).div(TotalStakedETH);
        staked = staked.mul(470000000000000000000);
        return staked;
            
        }
      }
      else
      return 0;
      
      
        
  }
     function CLAIMREWARD() public {
        
            uint256 timeToday = now - creationTimeContract; //what day it is 
            uint256 timeT = timeToday.div(300);
            require(stakers[msg.sender].stakedAmount > 0,"you need to stake some coins");       
            //require(timeT > 0,"Claim Time has not started yet");
            uint256 rewardToGive = calculateReward(timeT,msg.sender);
            require(MOJITO(rewardToken).transfer(msg.sender,rewardToGive), "ERROR: error in sending reward from contract");
            emit CLAIMEDREWARD(msg.sender, rewardToGive);
            stakers[msg.sender].TotalMRewarded = (stakers[msg.sender].TotalMRewarded).add(rewardToGive);
            stakers[msg.sender].lastClaim = now;
            TotalMRewards = TotalMRewards.add(rewardToGive);
               

        
    }
    
  
  function calculateReward(uint timeday, address user) private view returns(uint256 rew){
      
      
       uint256 totalReward = 0;

      if(timeday>60) //check reward for 0 day 
      {
         uint256 daystocheck = stakers[user].lastClaim - creationTimeContract;
         uint256 daysCount = daystocheck.div(300);
         daystocheck = 60 - daysCount;

       
         for(uint i =daystocheck; i<60; i++)
         {
            uint256 rewardpday =    ((stakers[user].stakedAmount)*(rewardperday[i])).div(TotalStakedETH);
            totalReward = totalReward.add(rewardpday);
         }
         
       
          
      }else
      {
          uint256 daystocheck = stakers[user].lastClaim - creationTimeContract;  //when did user last withdrew funds 
          uint256 daysCount = daystocheck.div(300);
          
          uint256 daystogive = now - creationTimeContract;  //check what day it is 
          uint256 daysCounts = daystogive.div(300);
         
          if(stakers[user].lastClaim == stakers[user].creationTime)
          {
          uint256 daysCountInSec = daystocheck.div(1);
          uint256 somthing = daysCount * 300;
          daystogive = 0;
          if(somthing == 0 )
          {
             daystogive = 300 - daysCountInSec;
          }
          else{
             daystogive = daysCountInSec.sub(somthing);
          }
          
          if(daysCount ==  daysCounts)
          {
              
               totalReward = (((stakers[user].stakedAmount)*(rewardperday[daysCounts])).div(TotalStakedETH));
              totalReward = (totalReward.mul(daystogive)).div(300);  
              
          }
          else
          {
             for(uint i = daysCount; i<daysCounts; i++)
            {
                uint256 rewardpday = ((stakers[user].stakedAmount)*(rewardperday[i])).div(TotalStakedETH);
                
            if(i == daysCount)
            {
                rewardpday = (rewardpday.mul(daystogive)).div(300);
            }
                 totalReward = totalReward.add(rewardpday);
            }
          }
              
          }
          else
          {
             
             for(uint i = daysCount; i<daysCounts; i++)
            {
                uint256 rewardpday =    ((stakers[user].stakedAmount)*(rewardperday[i])).div(TotalStakedETH);
                totalReward = totalReward.add(rewardpday);
            }
          
          }
          
        
      }
        return totalReward;
  }
    
       
    
   
    
    function TotalPoolRewards() external pure returns(uint256 tpreward)
    {
        return 470000000000000000000;
    }
        
        
    function MyTotalStaked(address user) external view returns(uint256 totalstaked)
    {
       return stakers[user].MyTotalStaked;
    }
        
function CurrentTokenReward() external view returns(uint256 crrtr)
    {
        
             uint256 timeToday = now - creationTimeContract;
        uint256 timeT = timeToday.div(300);
        if(timeT > 60)
        {
            return 0;
        }
        else
        {
            
        return rewardperday[timeT];
            
        }
            
    }
    
function TotalClaimedReward() external view returns (uint256 TotalM)
{
    return TotalMRewards;
}


function SetTokenToStake(address newStakeToken) public onlyOwner
{
    stakeTokenAdd = newStakeToken;
    
}


function SetStakeFee(uint256 percent) public onlyOwner
{
    StakingFee = percent;
}
  
function SetUNStakeFee(uint256 percent) public onlyOwner
{
    UnstakingFee = percent;
}



}