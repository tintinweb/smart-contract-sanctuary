/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;


 
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
    uint256 public custLockPercent = 300;
    uint256 public custPercent = 100;
    uint256 public lockdays = 50;
    uint256 public totalStakes = 0;
    uint256 private refferalReward = 1000000000000000000;
    uint256 StakingFee = 10; // 1.0% 
    uint256 UnstakingFee = 50; // 3.0%
    uint private BFTFee = 0;
    
    
    
    
    
    
    struct USER{
      
        uint256 freezeReward;
        uint256 totalEarned;
        uint256 lockTokens;
        uint256 lockCreation;
        uint256 StakedDate;
        uint256 visits;
        address refferal;
        uint256 totalRefferal;
    }
    

    
    mapping(address => USER) public stakers;                 // keeps record of each payout
    mapping(address=>uint256) public amounts;
    mapping(address=>uint256) public lockamounts;
    
    
    event STAKED(address staker, uint256 tokens, uint256 creationTime);
    event UNSTAKED(address staker, uint256 tokens, uint256 creationTime);
    event CLAIMEDREWARD(address staker, uint256 reward);
    event PERCENTCHANGED(address operator, uint256 percent);
    event LOCKDAYSCHANGED(address operator, uint256 day);
    event REWARDCHANGED(address operator, uint256 amount);

    
    
   function FIRSTSTAKE(address refferal, uint256 tokens)  external{
       
       
       require(tokens > 0,"tokens cant be zero");
       require(stakers[msg.sender].visits == 0,"Please Proceed to LOCKSTAKE");
       require(msg.sender != refferal,"Address cant be same as yours");
       if(refferal!=owner)
       require(stakers[refferal].visits !=0);
       
       
       
       
       else{
           
        require(BFT(bft).transferFrom(msg.sender, address(this), tokens), "Tokens cannot be transferred from user account");
        require(BFT(bft).transfer(refferal,refferalReward), "Tokens cannot be transferred from user account");
        stakers[refferal].totalRefferal =  (stakers[refferal].totalRefferal).add(1);
       stakers[msg.sender].refferal = refferal;
        uint256 _stakingFee = (onePercent(tokens).mul(StakingFee)).div(10);
        
        stakers[msg.sender].lockTokens = (stakers[msg.sender].lockTokens).add((tokens).sub(_stakingFee));
        BFTFee = BFTFee.add(_stakingFee);
        stakers[msg.sender].lockCreation = now;
        stakers[msg.sender].StakedDate = now;
        totalStakes = totalStakes.add(tokens);
        uint256 percal = calPercent(tokens,custLockPercent);
        lockamounts[msg.sender] = percal;
        stakers[msg.sender].visits =  (stakers[msg.sender].visits).add(1);
        
        emit STAKED(msg.sender, tokens, stakers[msg.sender].lockCreation);
       }
   }
    
    
    function LOCKSTAKE(uint256 tokens)  external {
        
        require(tokens > 0,"tokens cant be zero");
        require(stakers[msg.sender].visits != 0,"Please Proceed to FIRSTSTAKE");
        
        
        require(BFT(bft).transferFrom(msg.sender, address(this), tokens), "Tokens cannot be transferred from user account");
       
        uint256 owing = 0;
        owing = CalculateAmountFreeze(msg.sender);
        if(owing > 0)
            {
                stakers[msg.sender].freezeReward = (stakers[msg.sender].freezeReward).add(owing);   
            }
    
        stakers[msg.sender].lockTokens = (stakers[msg.sender].lockTokens).add(tokens);
        stakers[msg.sender].lockCreation = now;
         stakers[msg.sender].StakedDate = now;
        totalStakes = totalStakes.add(tokens);
        uint256 percal = calPercent(tokens,custLockPercent);
        lockamounts[msg.sender] = percal;
        stakers[msg.sender].visits =  (stakers[msg.sender].visits).add(1);
        emit STAKED(msg.sender, tokens, stakers[msg.sender].lockCreation);
    
        }
    

    
    // ------------------------------------------------------------------------
    // Stakers can claim their pending rewards using this function
    // ------------------------------------------------------------------------
    function CLAIMREWARD() public {
           
           
            uint256   owing = CalculateAmountFreeze(msg.sender);
            owing = owing.add(stakers[msg.sender].freezeReward);
        

            require(BFT(bft).transfer(msg.sender,owing), "ERROR: error in sending reward from contract");
            emit CLAIMEDREWARD(msg.sender, owing);
                
        
            stakers[msg.sender].freezeReward = 0;
            Earned = Earned.add(owing);
            stakers[msg.sender].totalEarned = (stakers[msg.sender].totalEarned).add(owing);
       
               if(stakers[msg.sender].lockTokens == 0)
            {
                stakers[msg.sender].lockCreation = 0;
            }
        
        else
            {
               stakers[msg.sender].lockCreation = now;
            }
            
            stakers[msg.sender].lockCreation = now;
           }
           
 
    
    function CalculateAmountFreeze(address user) public view returns (uint256)
    {
         uint256  time = now - stakers[user].lockCreation; 
           uint256 daysLockCount = time.div(30);
           
           require(daysLockCount > 0 , "Minimum Time of withdrawal is 1 day");
        
               uint256  owing =0;
            if(daysLockCount>0)
            {
            owing =  ((lockamounts[user]).mul(daysLockCount)).add(owing);
        
            }
             return owing;
            
    }
    

    function LOCKWITHDRAW(uint256 tokens) external {
        
        
        
        
        require(stakers[msg.sender].lockTokens >= tokens && tokens > 0, "Invalid token amount to withdraw");
        
        uint256 time = now - stakers[msg.sender].StakedDate; 
        uint256 daysLockCount = time.div(30);
        
        
        require(daysLockCount > lockdays , "Lock Period not finished");
      
        
        // add pending rewards to remainder to be claimed by user later, if there is any existing stake
        uint256 owing = 0;
         msg.sender.transfer(tokens);
           
        owing = 0;
        owing = CalculateAmountFreeze(msg.sender);
        
        if(owing > 0)
        {
         
          stakers[msg.sender].freezeReward = (stakers[msg.sender].freezeReward).add(owing);   
        }
        
 
        stakers[msg.sender].lockTokens = stakers[msg.sender].lockTokens.sub(tokens);
        
               if(stakers[msg.sender].lockTokens == 0)
            {
                stakers[msg.sender].lockCreation = 0;
                stakers[msg.sender].StakedDate = 0;
            }
        
        else
            {
                 stakers[msg.sender].lockCreation = now;
                 
            }
        
        totalStakes = totalStakes.sub(tokens);
        uint256 percal = calPercent(stakers[msg.sender].lockTokens,custLockPercent);
        amounts[msg.sender] = percal;
        
        
        if(totalStakes > 0)
        emit UNSTAKED(msg.sender, tokens, stakers[msg.sender].StakedDate);
        
        
        
        
    
    }
    

    
    function onePercent(uint256 _tokens) private pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint onePercentofTokens = roundValue.mul(100).div(100 * 10**uint(2));
        return onePercentofTokens;
    }
    
    

       
    function calPercent(uint256 _tokens, uint256 cust) private pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint256 custPercentofTokens = roundValue.mul(cust).div(100 * 10**uint(2));
        custPercentofTokens = custPercentofTokens.div(7);
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
    
        
         function setLockDays(uint256 day) public onlyOwner {
        
        require(day != 0,"lock days cant be 0");
        {
         lockdays  =day;    
         emit LOCKDAYSCHANGED(msg.sender, day);
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