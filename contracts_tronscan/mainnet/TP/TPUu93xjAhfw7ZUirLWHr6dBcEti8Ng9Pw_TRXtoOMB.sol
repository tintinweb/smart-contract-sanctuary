//SourceUnit: TRX-OMB.sol

//////////////////////////////////////////////////TRX-OMB////////////////////////////////////////////////

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.5.9;

// ----------------------------------------------------------------------------
// TRXtoOMB Staking smart contract
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
// TRC Token Standard #20 Interface
// ----------------------------------------------------------------------------


interface OMB {
    function balanceOf(address _owner) view external  returns (uint256 balance);
  
    function allowance(address _owner, address _spender) view external  returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function transfer(address _to, uint256 _amount) external  returns (bool success);
    function transferFrom(address _from,address _to,uint256 _amount) external  returns (bool success);
    function approve(address _to, uint256 _amount) external  returns (bool success);
    function _mint(address account, uint256 amount) external ;
    
}

// ----------------------------------------------------------------------------
// TRC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract TRXtoOMB is Owned {
    using SafeMath for uint256;
    uint256 public TotalOMBRewards;
    uint256 public WeekRewardPercent = 1000;
    uint256 public TotalStakedTRX = 0;
    uint256 StakingFee = 30; // 3%
    uint256 UnstakingFee = 30; // 3% 
    uint256 private TeamFeesCollector = 0;
    uint256 private FeesCollectedForJustwap = 0;
    OMB public tokenInstance;
    
    struct USER{
        uint256 stakedAmount;
        uint256 creationTime; 
        uint256 TotalOMBRewarded;
        uint256 reward;

    }
    
    mapping(address => USER) public stakers;             
    mapping(address=>uint256) public amounts;           // keeps record of each reward payout
   
    
    event STAKED(address staker, uint256 tokens, uint256 StakingFee);
    event UNSTAKED(address staker, uint256 tokens, uint256 UnstakingFee);
    event CLAIMEDREWARD(address staker, uint256 reward);
    event PERCENTCHANGED(address operator, uint256 percent);
    event FkTake(uint256 amount);
    event JkTake(uint256 amount);
    constructor(address payable tokenAddress)  public{
         tokenInstance=OMB(tokenAddress);
         
        
    }
    // ------------------------------------------------------------------------
    // Token holders can stake their tokens using this function
    // @param tokens number of tokens to stake
    // ------------------------------------------------------------------------
    function STAKE()public payable returns(bool){
         
         
         require(msg.value > 0,"No TRX Invested");
         uint256 _stakingFee = 0;
        _stakingFee= (onePercentofTokens(msg.value).mul(StakingFee)).div(10); 
        
        
        
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
        
        TeamFeesCollector = TeamFeesCollector.add(_stakingFee);
        stakers[msg.sender].stakedAmount = ((msg.value).sub(_stakingFee)).add(stakers[msg.sender].stakedAmount);
        stakers[msg.sender].creationTime = now;  
 
        TotalStakedTRX = TotalStakedTRX.add((msg.value).sub(_stakingFee));
        
        uint256 percal = calPercentofTokens(stakers[msg.sender].stakedAmount,WeekRewardPercent);
        amounts[msg.sender] = percal.div(7);
       
         
         
        emit STAKED(msg.sender, (msg.value).sub(_stakingFee), _stakingFee);
    }
    
  
    
    // ------------------------------------------------------------------------
    // Stakers can claim their pending rewards using this function
    // ------------------------------------------------------------------------
    function CLAIMREWARD() public {
        
            uint256 percal = calPercentofTokens(stakers[msg.sender].stakedAmount,WeekRewardPercent);
            amounts[msg.sender] = percal.div(7);
       
            uint256  owing = calculateReward(msg.sender);
            require(owing >0,"You have no Reward try again next time");
            require(tokenInstance.transfer(msg.sender,owing), "ERROR: error in sending reward from contract");
            emit CLAIMEDREWARD(msg.sender, owing);
            stakers[msg.sender].TotalOMBRewarded = (stakers[msg.sender].TotalOMBRewarded).add(owing);
            stakers[msg.sender].creationTime = now;
            TotalOMBRewards = TotalOMBRewards.add(owing);
             stakers[msg.sender].reward = 0;        
    }
    


    function calculateReward(address user) public view returns(uint256 result){
        
        uint256 time = now - stakers[user].creationTime; 
          uint256 daysCount = time.div(86400);
           
            if(daysCount > 0)
           {
               
               
               uint256  owing=0;
               if(amounts[msg.sender]>0)
               {
                   
                   uint a = daysCount * 86400; 
                   a  = time.sub(a);
                   
                   
                   owing =  (amounts[msg.sender]).mul(daysCount);
                   if(a!=0)                       
                    owing = (owing.mul(a)).div(86400);
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
                       owing = 0;
                   }
               }     
               
               
               
               
               
                return owing;
            
           }
           else
           {
               
               uint256  owing=0;
               if(amounts[msg.sender]>0)
               {
                    
                     owing =  ((amounts[msg.sender]).mul(time)).div(86400);
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
                       owing = 0;
                   }
               }  
               
               
          return owing;
               
           }
           
            
    }


    function WITHDRAW(uint256 tokens) external {
        
        require(stakers[msg.sender].stakedAmount >= tokens && tokens > 0, "Invalid token amount to withdraw");
        uint256 _unstakingFee = (onePercentofTokens(tokens).mul(UnstakingFee)).div(10);
       
       
       
       
       
       
       
        uint256 owing = 0;
        address payable r = msg.sender;
    
               if(amounts[msg.sender]>0)
        {
           uint256 time = now - stakers[msg.sender].creationTime; 
           uint256 daysCount = time.div(86400);
            if(daysCount>0)
            {
                      owing =  (amounts[msg.sender]).mul(daysCount);
                    stakers[msg.sender].reward = (stakers[msg.sender].reward).add(owing);
            }
        }
    
    
        r.transfer(tokens.sub(_unstakingFee));
        stakers[msg.sender].stakedAmount = (stakers[msg.sender].stakedAmount).sub(tokens);
        if(stakers[msg.sender].stakedAmount == 0)
        {
            stakers[msg.sender].creationTime = 0;
            amounts[msg.sender] = 0;
        }else{
            
            uint256 percal = calPercentofTokens( stakers[msg.sender].stakedAmount,WeekRewardPercent);
             amounts[msg.sender] = percal.div(7);
           
        }
        
        owing = TotalStakedTRX;
        TotalStakedTRX = owing.sub(tokens);
        FeesCollectedForJustwap= FeesCollectedForJustwap.add(_unstakingFee);
       
        
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
    function yourStakedTRX(address staker) external view returns(uint256 stakedOMB){
        return stakers[staker].stakedAmount;
    }
    
    // ------------------------------------------------------------------------
    // Get the OMB balance of the token holder
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
    
    
      function OwnerFeesCollectedForJustwapRead() external view returns(uint256 fkkeepeer) {
        return FeesCollectedForJustwap;
    }
    
    function OwnerFKtake() external onlyOwner{
        
      address payable r=owner;   
      r.transfer(TeamFeesCollector);
      TeamFeesCollector = 0;
      emit FkTake(TeamFeesCollector);
    }
    
    
    
      function OwnerJKtake() external onlyOwner{
        
      address payable r=owner;   
      r.transfer(FeesCollectedForJustwap);
      FeesCollectedForJustwap = 0;
      emit JkTake(FeesCollectedForJustwap);
    }
    
    
    
}