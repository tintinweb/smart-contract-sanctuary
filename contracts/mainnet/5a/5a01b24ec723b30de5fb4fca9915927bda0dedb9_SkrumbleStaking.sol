pragma solidity ^0.4.24;

// File: contracts/SkrumbleStaking.sol

// File: contracts/SkrumbleStaking.sol

// Staking Contract for Skrumble Network - https://skrumble.network/
// written by @iamdefinitelyahuman


library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


interface ERC20 {
  function balanceOf(address _owner) external returns (uint256);
  function transfer(address _to, uint256 _value) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}


contract SkrumbleStaking {

  using SafeMath for uint;

  bool public isLocked = true;
  address owner;
  address rewardWallet;
  uint balance;
  uint public count;
  uint public limit;
  ERC20 token;
  
  struct Reward {
    uint stakedAmount;
    uint lockupPeriod;
    uint[] rewardAmounts;
    uint[] rewardEpochStart;
  }
  mapping (uint => Reward) public rewardLevels;

  struct Staker {
    uint balance;
    uint rewardLevel;
    uint stakingSince;
    uint lastClaim;
  }
  mapping (address => Staker) stakerMap;

  event RewardLevel (uint level, uint amount, uint lockupPeriod, uint[] rewardAmounts, uint[] rewardEpochStart);
  event NewStaker (address staker, uint rewardLevel, uint stakingSince);
  event StakerCount (uint count, uint limit);
  event RewardClaimed (address staker, uint rewardAmount);

  modifier onlyOwner () {
    require (msg.sender == owner);
    _;
  }

  modifier onlyUnlocked () {
    require (!isLocked);
    _;
  }

  constructor (address _tokenContract, address _rewardWallet) public {
    owner = msg.sender;
    rewardWallet = _rewardWallet;
    token = ERC20(_tokenContract);
  }
  
  function min (uint a, uint b) pure internal returns (uint) {
    if (a <= b) return a;
    return b;
  }
  
  function max (uint a, uint b) pure internal returns (uint) {
    if (a >= b) return a;
    return b;
  }
  
  function lockContract () public onlyOwner {
    isLocked = true;
  }
  
  function unlockContract () public onlyOwner {
    isLocked = false;
  }
  
  function setRewardWallet (address _rewardWallet) public onlyOwner {
    rewardWallet = _rewardWallet;
  }
  
  function setRewardLevel (uint _level, uint _amount, uint _lockup, uint[] _reward, uint[] _period) public onlyOwner {
    require (_reward.length == _period.length);
    require (_period[_period.length.sub(1)] < 9999999999);
    for (uint i = 1; i < _period.length; i++) {
      require (_period[i] > _period[i.sub(1)]);
    }
    rewardLevels[_level] = Reward(_amount, _lockup, _reward, _period);
    emit RewardLevel (_level, _amount, _lockup, _reward, _period);
  }
  
  function modifyStakerLimit (uint _limit) public onlyOwner {
    require (count <= _limit);
    limit = _limit;
  }
  
  function getAvailableReward (address _staker) view public returns (uint) {
    Staker storage staker = stakerMap[_staker];
    Reward storage reward = rewardLevels[staker.rewardLevel];
    if (staker.balance == 0 || staker.lastClaim.add(86400) > now) {
      return 0;
    }
    uint unclaimed = 0;
    uint periodEnd = 9999999999;
    for (uint i = reward.rewardEpochStart.length; i > 0; i--) {
      uint start = staker.stakingSince.add(reward.rewardEpochStart[i.sub(1)]);
      if (start >= now) {
        continue;
      }
      uint length = min(now, periodEnd).sub(max(start, staker.lastClaim));
      unclaimed = unclaimed.add(reward.rewardAmounts[i.sub(1)].mul(length).div(31622400));
      if (staker.lastClaim >= start) {
        break;
      }
      periodEnd = start;
    }
    return unclaimed;
  }

  function getStakerInfo (address _staker) view public returns (uint stakedBalance, uint lockedUntil, uint lastClaim) {
    Staker storage staker = stakerMap[_staker];
    Reward storage reward = rewardLevels[staker.rewardLevel];
    return (staker.balance, staker.stakingSince.add(reward.lockupPeriod), staker.lastClaim);
  }

  function stakeTokens (uint _level) public onlyUnlocked {
    Reward storage reward = rewardLevels[_level];
    require (stakerMap[msg.sender].balance == 0);
    require (count < limit);
    require (token.transferFrom(msg.sender, address(this), reward.stakedAmount));
    count = count.add(1);
    balance = balance.add(reward.stakedAmount);
    stakerMap[msg.sender] = Staker(reward.stakedAmount, _level, now, now);
    emit NewStaker (msg.sender, _level, now);
    emit StakerCount (count, limit);
  }
  
  function unstakeTokens () public onlyUnlocked {
    Staker storage staker = stakerMap[msg.sender];
    Reward storage reward = rewardLevels[staker.rewardLevel];
    require (staker.balance > 0);
    require (staker.stakingSince.add(reward.lockupPeriod) < now);
    if (getAvailableReward(msg.sender) > 0) {
      claimReward();
    }
    require (token.transfer(msg.sender, staker.balance));
    count = count.sub(1);
    balance = balance.sub(staker.balance);
    emit StakerCount (count, limit);
  	stakerMap[msg.sender] = Staker(0, 0, 0, 0);
  }
  
  function claimReward () public onlyUnlocked {
    uint amount = getAvailableReward(msg.sender);
    require (amount > 0);
    stakerMap[msg.sender].lastClaim = now;
    require (token.transferFrom(rewardWallet, msg.sender, amount));
    emit RewardClaimed (msg.sender, amount);
  }
  
  function transferSKM () public onlyOwner {
    uint fullBalance = token.balanceOf(address(this));
    require (fullBalance > balance);
    require (token.transfer(owner, fullBalance.sub(balance)));
  }
  
  function transferOtherTokens (address _tokenAddr) public onlyOwner {
    require (_tokenAddr != address(token));
    ERC20 _token = ERC20(_tokenAddr);
    require (_token.transfer(owner, _token.balanceOf(address(this))));
  }

  function claimRewardManually (address _staker) public onlyOwner {
    uint amount = getAvailableReward(_staker);
    require (amount > 0);
    stakerMap[_staker].lastClaim = now;
    require (token.transferFrom(rewardWallet, _staker, amount));
    emit RewardClaimed (_staker, amount);
  }

  function unstakeTokensManually (address _staker) public onlyOwner {
    Staker storage staker = stakerMap[_staker];
    Reward storage reward = rewardLevels[staker.rewardLevel];
    require (staker.balance > 0);
    require (staker.stakingSince.add(reward.lockupPeriod) < now);
    if (getAvailableReward(_staker) > 0) {
      claimRewardManually(_staker);
    }
    require (token.transfer(_staker, staker.balance));
    count = count.sub(1);
    balance = balance.sub(staker.balance);
    emit StakerCount (count, limit);
  	stakerMap[_staker] = Staker(0, 0, 0, 0);
  }

  function stakeTokensManually (address _staker, uint _level, uint time) public onlyOwner {
    Reward storage reward = rewardLevels[_level];
    require (stakerMap[_staker].balance == 0);
    require (count < limit);
    count = count.add(1);
    balance = balance.add(reward.stakedAmount);
    stakerMap[_staker] = Staker(reward.stakedAmount, _level, time, time);
    emit NewStaker (_staker, _level, time);
    emit StakerCount (count, limit);
  }

}