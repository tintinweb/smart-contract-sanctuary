/**
 *Submitted for verification at BscScan.com on 2021-11-04
*/

pragma solidity ^0.8.7;

interface IBEP20 {
    function mint(address account, uint256 amount) external  returns (bool);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        
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
}


contract RubyStake {
    using SafeMath for uint256;
    struct Pool{
        uint _poolId;
        IBEP20 _token;
        uint _staked;
        uint _timestamp;
        uint _apy;
        uint _issuedRewards;
    }
    struct UserInfo{
        uint _amount;
        uint _time;
        uint _totalEarned;
    }
    
event stakeCoins(uint _poolId,address _staker, address _tokenContract, uint _amount, uint _time);
event unStakeCoins(uint _poolId,address _staker, address _tokenContract, uint _amount, uint _time);
event harvestRewards(uint _poolId,address _staker, uint _amount, uint _time);
event depositRewards( address _depositor, uint _amount, uint _time);
event withdrawRewards( address _receiver, uint _amount, uint _time);


event poolCreated(uint _poolId,address _creator,uint _yield,address _stakeToken );

    uint public  poolCounter;
    address public owner;
    IBEP20 rewardToken;
    uint public rewardsBalance;

    constructor(address rewardContract){
        rewardToken=IBEP20(rewardContract);
        owner=msg.sender;

    }
    
  mapping (uint => Pool) public idToPool;// to track pool info
    mapping (uint => mapping (address => UserInfo)) public userInfo;// to tract staking contribution by user in a pool
  
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner == msg.sender, "Ruby Stake: caller is not the owner");
    _;
  }
  
  function createPool(address tokenAddress,uint bps)onlyOwner public{
      
      uint  time=block.timestamp;
      IBEP20 tokenContract=IBEP20(tokenAddress);
      Pool memory stakePool=Pool(poolCounter,tokenContract,0,time,bps,0);
      idToPool[poolCounter]=stakePool;
      poolCounter++;

   emit poolCreated(stakePool._poolId,msg.sender,bps,tokenAddress);  
  }
   function updatePool(uint poolId,uint bps)onlyOwner public{
      
     
      idToPool[poolId]._apy=bps;
    

    
  }
  function stake(uint poolId,uint amount)public{
     address  staker=msg.sender;
     UserInfo memory  user= userInfo[poolId][staker];
      //    harvest(poolId);// harvest the pending reward

     user._amount=user._amount.add(amount);
     user._time=block.timestamp;
     idToPool[poolId]._staked=idToPool[poolId]._staked.add(amount);
    idToPool[poolId]._token.transferFrom(staker,address(this),amount);
userInfo[poolId][staker]=user;
 emit stakeCoins( poolId,staker,address(idToPool[poolId]._token), amount,user._time );

  }
   function unStake(uint poolId,uint amount)public{
     address  staker=msg.sender;
     UserInfo memory  user= userInfo[poolId][staker];
     require(user._amount>= amount);
     user._amount=user._amount.sub(amount);
     harvest(poolId);// harvest the pending reward
     user._time=block.timestamp;
     
    idToPool[poolId]._token.transfer(staker,amount);//returning the staked tokens
    idToPool[poolId]._staked= idToPool[poolId]._staked.sub(amount);// subtract  unstak amount from pool
 userInfo[poolId][staker]=user;// updating user info time and amount
 emit unStakeCoins( poolId,staker, address(idToPool[poolId]._token),amount, user._time);


  }
  function pendingHarvest(uint poolId, address staker)public view returns(uint){
  Pool memory pool= idToPool[poolId];
      uint cuurentTime= block.timestamp;
      uint stakedamount=userInfo[poolId][staker]._amount;
      uint timeLapsed= cuurentTime.sub(userInfo[poolId][staker]._time);
      
     uint pooldecimal=pool._token.decimals();
  uint rewardDecimals=rewardToken.decimals();
   uint rewardRate=rewardCoins(pool._apy,pooldecimal,rewardDecimals);
    pooldecimal=1*10**pooldecimal;
   rewardDecimals=1*10**rewardDecimals;// actual zeros
   
       uint pendingReward= (timeLapsed.mul(rewardRate).mul(stakedamount)).div(rewardDecimals);
      return pendingReward;
      
  }
  function harvest(uint poolId ) public returns(uint){
      address staker=msg.sender;
      uint rewardableTokens = pendingHarvest(poolId,msg.sender);
      require(rewardableTokens!=0,"No tokens to reward");
      uint oldTime=userInfo[poolId][staker]._time;
      userInfo[poolId][staker]._time=block.timestamp;
      uint currentRewards=userInfo[poolId][staker]._totalEarned;
      userInfo[poolId][staker]._totalEarned= currentRewards+ rewardableTokens;
      idToPool[poolId]._issuedRewards= idToPool[poolId]._issuedRewards.add(rewardableTokens);

    
 issueReward(staker,rewardableTokens);// issue the rewards   
 emit harvestRewards(poolId,staker, rewardableTokens, userInfo[poolId][staker]._time-oldTime);

  }
  
  function viewPoolbyId(uint poolId) public view returns ( uint _poolId,address _token,uint _staked,uint _timestamp,uint _re_apy,uint _reward){
  Pool memory pool= idToPool[poolId];
  uint pooldecimal=pool._token.decimals();
  uint rewardDecimals=rewardToken.decimals();
   uint reward=rewardCoins(pool._apy,pooldecimal,rewardDecimals);
   
   return ( pool._poolId,address(pool._token),pool._staked,pool._timestamp,pool._apy,reward);
}
 function userPoolData(uint poolId, address _user) public view returns ( uint _stakeAmount,uint _pendingRewards, uint _totalEarned,uint _time){
 
  UserInfo  memory user= userInfo[poolId][_user];

    uint pendingrewards= pendingHarvest(poolId,_user);
   return ( user._amount,pendingrewards,user._totalEarned,user._time);
}
function viewUserData( uint poolId,address  _user) public view returns (   uint _amount,uint _totalEarned,uint _pendingReward){
  UserInfo  memory user= userInfo[poolId][_user];
  uint pendingrewards= pendingHarvest(poolId,_user);
  
   return ( user._amount,user._totalEarned,pendingrewards);
}
/*
deposit  the rewards
*/
function addRewards(uint tokens)onlyOwner public{
   address depositor= msg.sender;

     rewardToken.transferFrom(depositor,address(this),tokens); // transfer  the rewards
     rewardsBalance= rewardsBalance.add(tokens);
      emit depositRewards(  depositor, tokens, block.timestamp);
}
/*
withdraw  the rewards
*/
function withdraw(address receiver, uint tokens)onlyOwner public{
   
    require(rewardsBalance>=tokens,"RubyStaking:insufficient Ruby balance to withdraw");
     rewardToken.transfer(receiver,tokens); // withdraw  the rewards
    rewardsBalance=  rewardsBalance.sub(tokens);
   emit   withdrawRewards( receiver, tokens, block.timestamp);
}
/*
issue  the rewards
*/
function issueReward(address staker, uint tokens) internal{

    require(rewardsBalance>=tokens,"RubyStaking:insufficient Ruby balance");
     rewardToken.transfer(staker,tokens); // transfer  the rewards
    rewardsBalance= rewardsBalance.sub(tokens);
}
/*
convert yield into rewardcoins per  seconds
*/
function rewardCoins(uint bps, uint poolDec, uint rewardDec)public pure returns(uint) {
    uint minute= 60;
    uint hour= minute.mul(60);
    uint year= hour.mul(24).mul(365);
    uint poolDecimals=1*10** poolDec;
    uint rewardDecimals=1*10** rewardDec;
    
    uint reward= bps.mul(poolDecimals).div(1000).div(year);
    uint mintableReward=reward.mul(rewardDecimals).div(poolDecimals);
    
    return mintableReward;
}
}