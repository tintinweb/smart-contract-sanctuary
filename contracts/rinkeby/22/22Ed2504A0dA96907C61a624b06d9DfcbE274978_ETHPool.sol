// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

/// @title Exactly Challenge
/// @author Blackscale
/// @notice ETHPool provides a service where people can deposit ETH and they will receive weekly rewards. Users are be able to take out their deposits along with their portion of rewards at any time. New rewards are deposited manually into the pool by the ETHPool team each week using a contract function.
/// @dev Assumptions: 1. if ETH is forcibly sent to this contract, it will be treated as additional rewards.
/// @dev 2. users can deposit only once, i.e. they cannot add to their deposit: withdraw + deposit again to augment the deposit.
/// @dev 3. Users are entitled to a cycle's reward if they had a deposit on the block where the team adds the reward, whether they deposited early or late during the cycle has no impact.

contract ETHPool {
  uint256 constant private HARDLIMIT = uint256(~uint224(0)); // max value for single deposits to prevent errors or reverts.
  address public team; // Should be replaced by a proper (inherited) Ownership contract (e.g. by OZ) before mainnet deployment for safety and flexibility.

  uint32 public currentCycle;
  uint256[] public rewardForCycle;              // reward to be distributed among users present when that cycle ended
  uint256[] public rewardableDepositsForCycle;  // snapshot of total deposits when reward is added. last element collects new deposits for current cycle.

  struct Deposit {
    uint224 value;  // Supports deposits up to unreasonable wealth. In prod it should be capped for safety anyway.
    uint32 cycle;   // Will last well over 1000 years even at one cycle per block, or 136 years if blocktime approaches 1 second.
  }
  
  mapping(address => Deposit) public deposits;

  event RewardAdded(uint256 rewardWeiAdded, uint256 depositsWeiBalance);

  constructor() {
    //console.log("Deploying Exactly ETHPool Challenge, owned by team address :", msg.sender);
    team = msg.sender;
    rewardForCycle.push(0);             // initial conditions for dynamic array
    rewardableDepositsForCycle.push(0); // initial conditions for dynamic array
  }
  
  /// @notice  Accepts deposits and new rewards.
  /// @dev ETH sent to this contract by force will be ignored and forever lost.
  receive() external payable {
    deposit();
  }
  fallback() external {
    revert();
  }

  /// @notice Returns the ETH balance of the ETHPoool contract
  /// @dev 
  /// @return balance The contract's ETH balance in wei.
  function fullBalance() external view returns (uint256 balance){
    return address(this).balance;
  }

  /// @notice Receives ETH and treats it as a pool deposit, or as a reward if called by team.
  /// @dev Do not add any code after last code block, or beware with reentrancy.
  function deposit() private {
    address caller = msg.sender;
    require(msg.value > 0, "E0");           // tx must include ETH to deposit
    require(msg.value <= HARDLIMIT, "EH");  // deposit too large. consider lowering threshold for prod
    //last code block
    if (caller == team) {
      processNewRewards();
    } else {
      require(deposits[caller].value == 0, "E1"); // User can not deposit twice.
      enter();
    }
  }

  /// @notice Processes user deposit.
  /// @dev Updates all pertinent global variables. Sanity checks are performed in external method (deposit()).
  function enter() private {
    deposits[msg.sender].value = uint224(msg.value);
    deposits[msg.sender].cycle = currentCycle;
    rewardableDepositsForCycle[currentCycle] += msg.value;
  }

  /// @notice Receive deposit and a fraction of the reward according to pool rules.
  /// @dev Sanity checks go here, no code after exit() or beware reentrancy.
  function withdraw() external {
    require(msg.sender != team, "E2"); // team can't deposit, so it can't exit/withdraw either. Also, no clawback on rewards.
    exit();
  }

  /// @notice Execute withdrawal
  /// @dev Call refund if claim can be excluded by blocktime. Safety benefits of not calling claim().
  function exit() private {
    if (deposits[msg.sender].cycle == currentCycle) {
      getRefund();
    }
    else {
      claim();
    }
  }

  /// @notice Sends deposit back to user.
  /// @dev Deletes all deposit data, timestamp included.
  function getRefund() private{
    uint256 refund = deposits[msg.sender].value;
    rewardableDepositsForCycle[currentCycle] -= refund;
    delete deposits[msg.sender];
    sendETH(refund);
  }
  
  /// @notice Sends deposit+reward to user.
  /// @dev Updates global variables.
  function claim() private{
    uint256 userDeposit = deposits[msg.sender].value;
    require(userDeposit > 0, "E3"); // nothing to withdraw
    uint256 amount = userDeposit + getClaimableReward(msg.sender);
    rewardableDepositsForCycle[currentCycle] -= userDeposit;
    delete deposits[msg.sender];
    sendETH(amount);
  }
  
  /// @notice Calculate reward amount for a single user according to pool rules.
  /// @dev Can make for an expensive tx if user stakes for a long time. Assuming one cycle per week, even after 20 years, tx is still well under current blockgaslimit at 5.5M gas.
  /// @param user The user we calculate rewards for.
  /// @return amount The amount of claimable reward for a given user.
  function getClaimableReward(address user) private view returns (uint256 amount) {
    for (uint256 i = deposits[user].cycle; i < currentCycle; i++) {
      amount += rewardForCycle[i] * deposits[user].value / rewardableDepositsForCycle[i];    
    }
  }

  /// @notice Process ETH sent by team.
  /// @dev 
  function processNewRewards() private {
    require(rewardableDepositsForCycle[currentCycle] > 0, "E5"); // No participants. Prevents from locking funds (rewards sent when there are no participants would be unclaimable forever)
    rewardForCycle[currentCycle] = msg.value;
    rewardForCycle.push(0);
    rewardableDepositsForCycle.push(rewardableDepositsForCycle[currentCycle]);
    currentCycle++;
    emit RewardAdded(msg.value, rewardableDepositsForCycle[currentCycle]);
  }

  /// @notice Transfer `amount` wei to caller.
  /// @dev 
  /// @param amount The amount to send, in wei.
  function sendETH(uint256 amount) private {
    payable(msg.sender).transfer(amount);
  }
}

