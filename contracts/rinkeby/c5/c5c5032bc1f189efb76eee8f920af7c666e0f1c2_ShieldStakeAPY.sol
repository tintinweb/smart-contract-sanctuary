// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./BEP20Token.sol";
import "./Ownable.sol";
import "./ReEntrancyGuard.sol";

contract ShieldStakeAPY is Ownable, ReEntrancyGuard {

  struct Pool {
    address stakeToken;
    address rewardToken;
    uint256 rewardAPY; // 10000 = 100%, 1000 = 10%, 100 = 1%, 10 = 0.1%, 1 = 0.01%
    uint256 depositFee;   // 1000 = 10%, 100 = 1%, 10 = 0.1%, 1 = 0.01%
    uint256 withdrawFee;  // 1000 = 10%, 100 = 1%, 10 = 0.1%, 1 = 0.01%
    address feeWallet;
    address rewardsWallet;
  }
  Pool[] public pools;

  struct Stake {
    uint256 amount;
    uint256 pendingRewards;
    uint256 lastRewardTime;
  }

  // pool => address => stake
  mapping(uint256 => mapping(address => Stake)) public stakes;
  mapping(uint256 => address[]) poolUsers;
  mapping(uint256 => mapping(address => uint256)) poolUserIndex;
  mapping(uint256 => bool) haltRewards;
  mapping(uint256 => bool) haltDeposits;
  mapping(uint256 => bool) haltWithdraws;

  event PoolCreated(uint256 pId, address stakeToken, address rewardToken, uint256 rewardAPY);
  event Deposit(address sender, uint256 pId, uint256 amount);
  event Withdraw(address sender, uint256 pId, uint256 amount);
  event ClaimRewards(address sender, uint256 pId, uint256 amount);
  event APYModified(uint256 oldAPY, uint256 newAPY);
  event HaltRewards(uint256 pId, bool isHalted);
  event HaltDeposits(uint256 pId, bool isHalted);
  event HaltWithdraws(uint256 pId, bool isHalted);
  event RewardsWalletModified(uint256 pId, address oldRewardsWallet, address newRewardsWallet);

  constructor(address owner) {
    transferOwnership(owner);
  }

  /**
   * @dev Create a new pool
   * @param stakeToken The token we want to stake in the pool.
   * @param rewardToken The token used to fulfill rewards.
   * @param rewardAPY The "fixed" APY of the pool. Can be modifeed manually by using modifyAPY(...).
   * @param depositFee The deposit fee % to be collected.
   * @param withdrawFee The withdraw fee % to be collected.
   * @param feeWallet The fee collector.
   * @param rewardsWallet The wallet used to transfer from rewards.
   * @return pId The id of the created pool
   *
   * Requirements:
   * - stakeToken is not zero address
   * - rewardToken is not zero address
   * - rewardAPY is greater than not zero
   * - feeWallet is not zero address
   *
   * NOTE
   * When rewardsWallet is zero address, staking contract will execute rewardToken.mint to fulfill rewards.
   */
  function createPool(address stakeToken, address rewardToken, uint256 rewardAPY, uint256 depositFee, uint256 withdrawFee, address feeWallet, address rewardsWallet) external onlyOwner returns (uint256 pId) {
    require(stakeToken != address(0), "stake from zero address");
    require(rewardToken != address(0), "rewards from zero address");
    require(rewardAPY > 0, "APY zero");
    require(feeWallet != address(0), "fees to zero address");
    // set pool id
    pId = pools.length;
    // add create Pool
    pools.push(Pool(
      stakeToken,
      rewardToken,
      rewardAPY,
      depositFee,
      withdrawFee,
      feeWallet,
      rewardsWallet
    ));
    emit PoolCreated(pId, stakeToken, rewardToken, rewardAPY);
  }

  /**
   * @dev Gets the length of the pool array.
   */
  function getPoolsLength() external view returns (uint256) {
    return pools.length;
  }

  /**
   * @dev Claim rewards
   * @param pId The id of the pool where we are going to deposit.
   * @param amount The amount of tokens to be deposited in the staking contract.
   *
   * Requirements:
   * - valid pool id
   * - deposits are not halted
   * - sender is not zero address
   * - staking amount is greater than zero
   */
  function deposit(uint256 pId, uint256 amount) external noReentrancy {
    require(pId >= 0 && pId < pools.length, "invalid pool");
    require(!haltDeposits[pId], "deposits halted");
    require(_msgSender() != address(0), "deposit from zero address");
    require(amount > 0, "invalid amount");

    // transfer user tokens to staking contract
    IBEP20(pools[pId].stakeToken).transferFrom(_msgSender(), address(this), amount);

    // existing user
    if(stakes[pId][_msgSender()].amount > 0 // claimRewards requirement
    && stakes[pId][_msgSender()].lastRewardTime > 0) {
      // send rewards before increasing stake amount
      _claimRewards(pId);
    }

    // increase user's pool stake
    stakes[pId][_msgSender()].amount += amount - transferFee(pools[pId].stakeToken, pools[pId].feeWallet, amount, pools[pId].depositFee);

    // new user
    if(stakes[pId][_msgSender()].lastRewardTime == 0) {
      // start rewards 
      stakes[pId][_msgSender()].lastRewardTime = block.timestamp;
      // save user reference
      poolUsers[pId].push(_msgSender());
      poolUserIndex[pId][_msgSender()] = poolUsers[pId].length - 1;
    }

    emit Deposit(_msgSender(), pId, amount);
  }

  /**
   * @dev Withdraw stake amount
   * @param pId The id of the pool where we want to withdraw.
   * @param amount The amount of tokens to be withdrawn from the staking contract.
   *
   * Requirements:
   * - valid pool id
   * - withdraws are not halted
   * - sender is not zero address
   * - user stake amount is greater than zero
   * - amount is not zero
   * - amount is not greater than stake amount
   */
  function withdraw(uint256 pId, uint256 amount) public noReentrancy {
    require(pId >= 0 && pId < pools.length, "invalid pool");
    require(!haltWithdraws[pId], "withdraws halted");
    require(_msgSender() != address(0), "withdraw from zero address");
    require(stakes[pId][_msgSender()].amount > 0, "not pool user");
    require(amount > 0, "invalid amount");
    require(amount <= stakes[pId][_msgSender()].amount, "insufficient balance");

    // send rewards before decreasing stake amount
    _claimRewards(pId);

    // update user's pool stake
    stakes[pId][_msgSender()].amount -= amount;

    // send tokens back to user
    IBEP20(pools[pId].stakeToken).transfer(
      _msgSender(), 
      amount - transferFee(pools[pId].stakeToken, pools[pId].feeWallet, amount, pools[pId].withdrawFee));

    // remove user reference when stake amount is zero
    if(stakes[pId][_msgSender()].amount == 0) {
      removeUserReference(pId, _msgSender());
    }

    emit Withdraw(_msgSender(), pId, amount);
  }

  /**
   * @dev Withdraw all
   * @param pId The id of the pool where we want to withdraw
   */
  function withdrawAll(uint256 pId) external {
    // withdraw all user's pool stake
    withdraw(pId, stakes[pId][_msgSender()].amount);
  }

  /**
   * @dev Withdraw and forget about rewards.
   * @param pId The id of the pool where we want to withdraw
   */
  function emergencyWithdraw(uint256 pId) external {
    require(pId >= 0 && pId < pools.length, "invalid pool");
    require(_msgSender() != address(0), "withdraw from zero address");
    require(stakes[pId][_msgSender()].amount > 0, "not pool user");

    // get stake amount
    uint256 amount = stakes[pId][_msgSender()].amount;
    // delete stake information
    delete stakes[pId][_msgSender()];

    // remove user reference
    removeUserReference(pId, _msgSender());

    // transfer fees to feeWallet and transfer amount.sub(fees) to user
    IBEP20(pools[pId].stakeToken).transfer(_msgSender(), amount - transferFee(pools[pId].stakeToken, pools[pId].feeWallet, amount, pools[pId].withdrawFee));
  }

  /**
   * @dev Calculate fee amount and transfer it to feeWallet.
   * @param stakeToken The token address.
   * @param feeWallet The fee wallet address where fees are sent.
   * @param fromAmount The amount to be used to calculate fee amount.
   * @param fee The fee percent (1000 = 10%, 100 = 1%, 10 = 0.1%, 1 = 0.01%)
   * @return feeAmount The transfered fee amount.
   */
  function transferFee(address stakeToken, address feeWallet, uint256 fromAmount, uint256 fee) private returns(uint256 feeAmount) {
    feeAmount = fromAmount * fee / 10000;
    IBEP20(stakeToken).transfer(feeWallet, feeAmount);
  }

  /**
   * @dev Remove user reference and ensure that array length is always right.
   * @param pId The id of the pool we where want to delete the user.
   * @param user The user address to be removed.
   */
  function removeUserReference(uint256 pId, address user) private {
    // copy last element to user index
    poolUsers[pId][poolUserIndex[pId][user]] = poolUsers[pId][poolUsers[pId].length - 1];
    // update index
    poolUserIndex[pId][poolUsers[pId][poolUsers[pId].length - 1]] = poolUserIndex[pId][user];
    // remove last element
    poolUsers[pId].pop();
    // delete user index
    delete poolUserIndex[pId][user];
  }

  /**
   * @dev Claim rewards
   * @param pId The id of the pool where we want to claim rewards.
   * 
   * Requirements:
   * - valid pool id
   * - rewards are not halted
   * - sender is not zero address
   * - user stake amount is greater than zero
   */
  function claimRewards(uint256 pId) external noReentrancy {
      emit ClaimRewards(_msgSender(), pId, _claimRewards(pId));
  }

  /**
   * @dev Implementation of claim rewards
   * @param pId The id of the pool where we want to claim rewards.
   */
  function _claimRewards(uint256 pId) private returns(uint256 rewardAmount) {
    require(pId >= 0 && pId < pools.length, "invalid pool");
    require(!haltWithdraws[pId], "claims are halted");
    require(_msgSender() != address(0), "claim from zero address");
    require(stakes[pId][_msgSender()].amount > 0, "not pool user");

    // get user reward amount
    rewardAmount = calculateUserRewards(pId, _msgSender());

    // reset rewards
    stakes[pId][_msgSender()].lastRewardTime = block.timestamp;
    // set pending rewards to zero
    stakes[pId][_msgSender()].pendingRewards = 0;

    // Skip reward transfer if rewardAmount is zero
    if(rewardAmount > 0) {
      
      // if rewardsWallet is zero address then try to mint tokens
      if(pools[pId].rewardsWallet == address(0)) {
        // staking contract needs to be allowed to execute mint functionality on the reward token
        // otherwise the mint functionality will throw an error.

        // mint tokens for the stake contract address
        BEP20Token(pools[pId].rewardToken).mint(rewardAmount);
      }
      else {
        // transfer tokens to staking smart contract
        IBEP20(pools[pId].rewardToken).transferFrom(pools[pId].rewardsWallet, address(this), rewardAmount);
      }

      // transfer reward amount to user
      IBEP20(pools[pId].rewardToken).transfer(_msgSender(), rewardAmount);
    }
  }

  /**
   * @dev Calculate user rewards
   * @param pId The id of the pool where we want to calculate rewards.
   * @param addr The addr of the stake holder.
   */
  function calculateUserRewards(uint256 pId, address addr) public view returns (uint256 rewardAmount) {
    require(pId >= 0 && pId < pools.length, "invalid pool");
    require(addr != address(0), "zero address");
    require(stakes[pId][addr].amount > 0, "not pool user");

    // rewards halted?
    if(!haltRewards[pId]) {
      // calculate current rewards
      // stake amount * rewardAPY * (currentTime - lastTime) / 365 days / 10000;
      rewardAmount = stakes[pId][addr].amount * pools[pId].rewardAPY * (block.timestamp - stakes[pId][addr].lastRewardTime) /  365 days / 10000;
      // add pending rewards
      rewardAmount += stakes[pId][addr].pendingRewards;
    }
    else
      // if rewards are halted, pedingRewards should contain last calculated rewards
      rewardAmount = stakes[pId][addr].pendingRewards;
  }

  /**
   * @dev Modify pool APY
   * @param pId The id of the pool where we want to modify the APY.
   * @param newAPY self-explained
   */
  function modifyAPY(uint256 pId, uint256 newAPY) external onlyOwner {
    require(newAPY > 0, "invalid APY");

    // set pending rewards using current APY
    updatePendingRewards(pId);

    pools[pId].rewardAPY = newAPY;
  }

  /**
   * @dev (toogle)Halt pool rewards.
   * @param pId The id of the pool where we want to toggle value.
   * @param skipHaltedTime Excluded halted time from rewards. Ignored when turning on.
   */
  function toggleHaltRewards(uint256 pId, bool skipHaltedTime) external onlyOwner {
    if(!haltRewards[pId]) {
      // freeze rewards
      // save latest calculated reward before halting
      updatePendingRewards(pId);
      haltRewards[pId] = true;
    }
    else {
      if(skipHaltedTime) {
        // to skip rewards we need to set lastRewardTime to current block timestamp
        for(uint256 i = 0; i < poolUsers[pId].length; i++) {
          // set lastRewardTime to current block timestamp
          stakes[pId][poolUsers[pId][i]].lastRewardTime = block.timestamp;
        }
      }
      haltRewards[pId] = false;
    }
  }

  /**
   * @dev (toggle)Halt pool deposits
   * @param pId The id of the pool where we want to toggle value.
   */
  function toggleHaltDeposits(uint256 pId) external onlyOwner {
    haltDeposits[pId] = !haltDeposits[pId];
  }
  
  /**
   * @dev (toggle)Halt pool withdraws. Reward claims are also halted.
   * @param pId The id of the pool where we want to toggle value.
   */
  function toggleHaltWithdraws(uint256 pId) external onlyOwner {
    haltWithdraws[pId] = !haltWithdraws[pId];
  }

  /**
   * @dev Set fee wallet address
   * @param pId The id of the pool where we want to change fee wallet address.
   * @param feeWallet The new fee wallet address.
   */
  function setFeeWallet(uint256 pId, address feeWallet) external onlyOwner {
    pools[pId].feeWallet = feeWallet;
  }

  /**
   * @dev Set pending rewards for each user of the specified pool.
   * @param pId The id of the pool where we want to set pending rewards.
   */
  function updatePendingRewards(uint256 pId) private {
    for(uint256 i = 0; i < poolUsers[pId].length; i++) {
      stakes[pId][poolUsers[pId][i]].pendingRewards = calculateUserRewards(pId, poolUsers[pId][i]);
      // reset rewards
      stakes[pId][poolUsers[pId][i]].lastRewardTime = block.timestamp;
    }
  }

  receive() external payable {
  }
  fallback() external payable {
  }

  function transferXS(address payable recipient) external onlyOwner {
    require(address(this).balance > 0, "no balance");
    // transfer contract balance to recipient
    (bool success, ) = recipient.call{value: address(this).balance}("");
    require(success, "tx failed");
  }
}