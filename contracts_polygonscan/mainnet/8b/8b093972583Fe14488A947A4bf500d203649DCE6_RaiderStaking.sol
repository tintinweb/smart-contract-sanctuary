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
 * @author @Nateliason, please contact me on Twitter if you have any questions about this contract.
 */

contract RaiderStaking is Ownable, ReentrancyGuard, Pausable { 
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  mapping(address => bool) internal stakers; // everyone who has staked
  mapping(address => uint) internal userStakes; // the amount the user has staked
  mapping(address => uint) internal bigUserRewardsCollected; // how much the user has collected
  
  uint public totalStakedSupply = 1000000000000000000; // for tracking how much is staked in total, starts at 1 to prevent divide by 0 issues
  uint public lastRewardTime; // For calculating how recently rewards were issued so we update with the right amount 

  IERC20 internal stakingToken; // address of the token people can stake
  IERC20 internal rewardToken; // address of the token people will be rewarded with

  uint public dailyEmissionsRate; // How much of the rewardToken gets distributed per day
  uint public bigMultiplier = 1000000000000000000; // Need this for getting around floating point issues

  uint internal bigRewardsPerToken; // the rewards per token, multipled by bigNum to avoid decimals

  // -------- CONSTRUCTOR -----------------

  constructor(address _stakingToken, address _rewardToken) {
    stakingToken = IERC20(_stakingToken);
    rewardToken = IERC20(_rewardToken);
    lastRewardTime = block.timestamp; // set this to when the contract is initiated minus one second so the first harvest isn't huge! 
    dailyEmissionsRate = 6849000000000000000000; // daily emissions for a 20m supply over 4 years
    updateBigRewardsPerToken();
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

  function createStake(uint _amount) external whenNotPaused {
    require(_amount > 0, "Cannot stake 0");
    totalStakedSupply = totalStakedSupply.add(_amount);
    getRewards();
    if (userStakes[msg.sender] == 0) {
        addStaker(msg.sender);
        bigUserRewardsCollected[msg.sender] = bigRewardsPerToken;
    }
    userStakes[msg.sender] = userStakes[msg.sender].add(_amount);
    stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
    emit Staked(msg.sender, _amount);
  }
  
  function removeStake(uint _amount) external whenNotPaused {
    require(_amount > 0, "Cannot remove 0");
    getRewards();
    totalStakedSupply = totalStakedSupply.sub(_amount);
    userStakes[msg.sender] = userStakes[msg.sender].sub(_amount);
    if (userStakes[msg.sender] == 0) removeStaker(msg.sender);
    stakingToken.safeTransfer(msg.sender, _amount);
    emit Withdrawn(msg.sender, _amount);
  }

  // Backup function in case something happens with the update rewards functions
  function emergencyUnstake(uint _amount) external {
    require(_amount > 0, "Cannot remove 0");
    totalStakedSupply = totalStakedSupply.sub(_amount);
    userStakes[msg.sender] = userStakes[msg.sender].sub(_amount);
    if (userStakes[msg.sender] == 0) removeStaker(msg.sender);
    stakingToken.safeTransfer(msg.sender, _amount);
    emit Withdrawn(msg.sender, _amount);
  }

  // ------------ REWARD ACTIONS ---------------

  function getRewards() public nonReentrant whenNotPaused {
    uint rewardsToSend = updateAddressRewardsBalance(msg.sender);
    if (rewardsToSend > 0) {
      rewardToken.safeTransfer(msg.sender, rewardsToSend);
      emit RewardPaid(msg.sender, rewardsToSend); 
    }
  }
  
  function updateAddressRewardsBalance(address _address) public returns (uint) {
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
      uint newBigRewardsPerToken = ((newEmissionsToAdd.mul(bigMultiplier)).div(totalStakedSupply)); // calc how much to add
      bigRewardsPerToken = bigRewardsPerToken.add(newBigRewardsPerToken); // add it
    }
  }
  
  function userPendingRewards(address _address) public view returns (uint) {
    uint earnedBigRewardsPerToken =  bigRewardsPerToken.sub(bigUserRewardsCollected[_address]);
    if (earnedBigRewardsPerToken > 0) {
      uint rewardsToSend = (earnedBigRewardsPerToken.mul(userStakes[_address])).div(bigMultiplier);
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
  
  function addressStakedBalance(address _address) external view returns (uint) {
    return userStakes[_address];
  }

  function showStakingToken() external view returns (address) {
    return address(stakingToken);
  }
  
  function showRewardToken() external view returns (address) {
    return address(rewardToken);
  }
  
  function showBigRewardsPerToken() external view returns (uint) {
    return bigRewardsPerToken;
  }
  
  function showBigUserRewardsCollected() external view returns (uint) {
    return bigUserRewardsCollected[msg.sender];
  }
}