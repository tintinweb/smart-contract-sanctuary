// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// !! IMPORTANT !! The most up to date SafeMath relies on Solidity 0.8.0's new overflow protection. 
// If you use an older version of Soliditiy you MUST also use an older version of SafeMath

import "./SafeMath.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

/**
 * @author @Nateliason, please ping me on Twitter if you have any questions
 */

contract RaiderStakingLocking is Ownable, ReentrancyGuard, Pausable { 
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint public totalStakedSupply = 1000000000000000000; // for tracking how much is staked in total
  uint public totalWeightedStakedSupply = 1000000000000000000; // adjusted total based on locking weights
  uint public lastRewardTime; // For calculating how recently rewards were issued so we update with the right amount 

  mapping(address => uint) internal userStakes;
  mapping(address => uint) internal userWeightedStakes;
  mapping(address => bool) internal stakers;
  mapping(address => uint) internal bigUserRewardsCollected;
  mapping(address => uint) internal userUnlockTime; // gives us a uint for when they can retrieve their rewards
  mapping(address => uint) internal userRewardMultiplier;

  uint internal threeMonthMultiplier = 1;
  uint internal sixMonthMultiplier = 2;
  uint internal nineMonthMultiplier = 3;
  uint internal twelveMonthMultiplier = 4;

  IERC20 internal stakingToken; // address of the token people can stake
  IERC20 internal rewardToken; // address of the token people will be rewarded with

  uint public dailyEmissionsRate; // How much of the rewardToken gets distributed per day
  uint public bigMultiplier = 1000000000000; // Need this for getting around floating point issues

  uint internal bigRewardsPerToken;

  bool internal emergencyUnlock = false;

  // -------- CONSTRUCTOR -----------------

  constructor(address _stakingToken, address _rewardToken) {
    stakingToken = IERC20(_stakingToken);
    rewardToken = IERC20(_rewardToken);
    lastRewardTime = block.timestamp; // set this to when the contract is initiated so the first harvest isn't huge! 
    dailyEmissionsRate = 13698000000000000000000; // daily emissions for the initial 50m AURUM supply till we get platform distributions working
    updateBigRewardsPerToken();
  }

  // ----------- MODIFIERS -----------------

  modifier isStaking() {
    require(addressStakedBalance(msg.sender) > 0, "You're not staking anything");
    _;
  }

  // ----------- EVENTS --------------------

  event RewardAdded(uint256 reward);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);

  // --------- UTILITY FUNCTIONS ------------

  function isStaker(address _address) public view returns(bool) {
    return stakers[_address];
  }
  
  function addStaker(address _address) internal whenNotPaused {
    stakers[_address] = true;
  }

  function removeStaker(address _address) internal whenNotPaused {
    stakers[_address] = false;
  }

  // ----------- STAKING ACTIONS ------------

  function createStake(uint _amount, uint _duration) external whenNotPaused {
    // note that duration will come in as a 0, 3, 6, 9, or 12
    require(_amount > 0, "Cannot stake 0");
    require(_duration > 0 || userStakes[msg.sender] != 0, "You need a duration for your initial stake");
    require( _duration.div(3) >= userRewardMultiplier[msg.sender] || userStakes[msg.sender] == 0 || _duration == 0, "You can't reduce your staking time!");
    
    setLock(_duration);
    uint multiplier = userRewardMultiplier[msg.sender];

    totalStakedSupply = totalStakedSupply.add(_amount);
    totalWeightedStakedSupply = totalWeightedStakedSupply.add(_amount.mul(multiplier));
    getRewards();
    if (userStakes[msg.sender] == 0) {
      addStaker(msg.sender);
      bigUserRewardsCollected[msg.sender] = bigRewardsPerToken;
    }
    
    userStakes[msg.sender] = userStakes[msg.sender].add(_amount);
    userWeightedStakes[msg.sender] = userWeightedStakes[msg.sender].add(_amount.mul(multiplier));
    stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
    emit Staked(msg.sender, _amount);
  }

  function removeStake(uint _amount) external whenNotPaused isStaking {
    require(_amount > 0, "Cannot remove 0");
    require(block.timestamp > userUnlockTime[msg.sender] || emergencyUnlock, "Your staking tokens are still locked!");
    getRewards();
    uint multiplier = userRewardMultiplier[msg.sender];
    totalStakedSupply = totalStakedSupply.sub(_amount);
    totalWeightedStakedSupply = totalWeightedStakedSupply.sub(_amount.mul(multiplier));
    userStakes[msg.sender] = userStakes[msg.sender].sub(_amount);
    userWeightedStakes[msg.sender] = userWeightedStakes[msg.sender].sub(_amount.mul(multiplier));
    if (userStakes[msg.sender] == 0) removeStaker(msg.sender);
    stakingToken.safeTransfer(msg.sender, _amount);
    emit Withdrawn(msg.sender, _amount);
  }

  // Backup function in case something happens with the update rewards functions
  function emergencyUnstake(uint _amount) external {
    require(_amount > 0, "Cannot remove 0");
    require(block.timestamp > userUnlockTime[msg.sender] || emergencyUnlock, "Your staking tokens are still locked!");
    uint multiplier = userRewardMultiplier[msg.sender];
    totalStakedSupply = totalStakedSupply.sub(_amount);
    totalWeightedStakedSupply = totalWeightedStakedSupply.sub(_amount.mul(multiplier));
    userStakes[msg.sender] = userStakes[msg.sender].sub(_amount);
    userWeightedStakes[msg.sender] = userWeightedStakes[msg.sender].sub(_amount.mul(multiplier));
    if (userStakes[msg.sender] == 0) removeStaker(msg.sender);
    stakingToken.safeTransfer(msg.sender, _amount);
    emit Withdrawn(msg.sender, _amount);
  }

  function setLock(uint _duration) internal {
    if (_duration >= 0 && _duration < 3) {
      return;
    } else if (_duration >= 3 && _duration < 6) {
      userRewardMultiplier[msg.sender] = threeMonthMultiplier;
      userUnlockTime[msg.sender] = block.timestamp.add(91 days);
    } else if (_duration >= 6 && _duration < 9) {
      userRewardMultiplier[msg.sender] = sixMonthMultiplier;
      userUnlockTime[msg.sender] = block.timestamp.add(182 days);
    } else if (_duration >= 9 && _duration < 12) {
      userRewardMultiplier[msg.sender] = nineMonthMultiplier;
      userUnlockTime[msg.sender] = block.timestamp.add(273 days);
    } else if (_duration >= 12) {
      userRewardMultiplier[msg.sender] = twelveMonthMultiplier;
      userUnlockTime[msg.sender] = block.timestamp.add(365 days);
    }
  } 

  // ------------ REWARD ACTIONS ---------------

  function getRewards() public nonReentrant whenNotPaused {
    uint rewardsToSend = (updateAddressRewardsBalance(msg.sender));
    if (rewardsToSend > 0) {
      rewardToken.safeTransfer(msg.sender, rewardsToSend);
      emit RewardPaid(msg.sender, rewardsToSend); 
    }
  }

  function updateAddressRewardsBalance(address _address) internal returns (uint) {
    updateBigRewardsPerToken();
    uint pendingRewards = userPendingRewards(msg.sender);
    if (pendingRewards > 0) {
      bigUserRewardsCollected[_address] = bigRewardsPerToken;
      return pendingRewards; 
    } else {
      return 0;
    }
  }

  function updateBigRewardsPerToken() public {
    if (timeSinceLastReward() > 0) { // so it doesn't run multiple times a second, possible during high activity
      uint rewardSeconds = timeSinceLastReward(); // get how many seconds its been since the last reward time
      lastRewardTime = block.timestamp; // update the last reward time
      uint emissionsPerSecond = dailyEmissionsRate.div(86400); // calc emissions per second
      uint newEmissionsToAdd = emissionsPerSecond.mul(rewardSeconds); // calculate how many new rewards to add
      uint newBigRewardsPerToken = ((newEmissionsToAdd.mul(bigMultiplier)).div(totalWeightedStakedSupply)); // calc how much to add
      bigRewardsPerToken = bigRewardsPerToken.add(newBigRewardsPerToken); // add it
    }
  }

  function userPendingRewards(address _address) public view returns (uint) {
    uint earnedBigRewardsPerToken =  bigRewardsPerToken.sub(bigUserRewardsCollected[_address]);
    if (earnedBigRewardsPerToken > 0) {
      uint rewardsToSend = (earnedBigRewardsPerToken.mul(userStakes[_address]).mul(userRewardMultiplier[_address])).div(bigMultiplier);
      return rewardsToSend; 
    } else {
      return 0;
    }
  }


  // ------------ ADMIN ACTIONS ---------------

  function withdrawRewards(uint _amount) external onlyOwner {
    rewardToken.safeTransfer(msg.sender, _amount);
  }

  function depositRewards(uint _amount) external onlyOwner {
    rewardToken.safeTransferFrom(msg.sender, address(this), _amount);
  }
  
  function setDailyEmissions(uint _amount) external onlyOwner {
    dailyEmissionsRate = _amount;
  }

  // End everyone's lock time in case of an emergency
  function emergencyUnlockToggle() external onlyOwner {
    emergencyUnlock = !emergencyUnlock;
  }

  function pause() external onlyOwner {
    _pause();
  }
  
  function unpause() external onlyOwner {
    _unpause();
  }

  // ------------ VIEW FUNCTIONS ---------------

  function timeSinceLastReward() public view returns (uint) {
    return block.timestamp.sub(lastRewardTime);
  }

  function rewardsBalance() external view returns (uint) {
    return rewardToken.balanceOf(address(this));
  }
  
  function addressStakedBalance(address _address) public view returns (uint) {
    return userStakes[_address];
  }

  function showStakingToken() external view returns (address) {
    return address(stakingToken);
  }
  
  function showRewardToken() external view returns (address) {
    return address(rewardToken);
  }

  function showLockTimeRemaining(address _address) external view returns (uint) {
    if (userUnlockTime[_address] > block.timestamp) {
      return userUnlockTime[_address].sub(block.timestamp);
    } else {
      return 0;
    }
    
  }

  function showRewardsMultiplier() external view returns (uint) {
    return userRewardMultiplier[msg.sender];
  }

  function showBigRewardsPerToken() external view returns (uint) {
    return bigRewardsPerToken;
  }
  
  function showBigUserRewardsCollected() external view returns (uint) {
    return bigUserRewardsCollected[msg.sender];
  }
}