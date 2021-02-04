pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";


contract VestingAndRewardDistribution {
  string public constant name = "CRT.finance vesting & pool reward distribution contract"; // team tokens (2.5%) vested over 6 months.

  using SafeMath for uint256;

  address public immutable crt;

  uint256 public immutable vestingAmount;
  uint256 public immutable vestingBegin;
  uint256 public immutable vestingEnd;
  address public liquidity;
  address public randomizedpool;
  address public governancepool;
  uint256 public timestamped;
  uint256 public timestamped2;
  uint256 public timestamped3;
  address public pooleth;
  uint256 public deployment = 1612987709;
  uint256 public endchange = 1612404000;


  address public recipient;
  uint256 public lastUpdate;
  
  constructor(
    address crt_,
    address recipient_,
    uint256 vestingAmount_,
    uint256 vestingBegin_,
    uint256 vestingEnd_
  ) public {
    require(
      vestingBegin_ >= block.timestamp,
      "VestingAndRewardDistribution::constructor: vesting begin too early"
    );
    require(
      vestingEnd_ > vestingBegin_,
      "VestingAndRewardDistribution::constructor: vesting end too early"
    );

    crt = crt_;
    recipient = recipient_;

    vestingAmount = vestingAmount_;
    vestingBegin = vestingBegin_;
    vestingEnd = vestingEnd_;

    lastUpdate = vestingBegin_;
  }

  function delegate(address delegatee) external {
    require(
      msg.sender == recipient,
      "VestingAndRewardDistribution::delegate: unauthorized"
    );
    ICrt(crt).delegate(delegatee);
  }

  function setRecipient(address recipient_) external {
    require(
      msg.sender == recipient,
      "VestingAndRewardDistribution::setRecipient: unauthorized"
    );
    recipient = recipient_;
  }
  
  function setGovernancePool(address governancepool_) external {
    require(
      msg.sender == recipient,
      "VestingAndRewardDistribution::setGovernancePool: unauthorized"
    );
    require(deployment < block.timestamp);
    governancepool = governancepool_;
  }
  
  function setLP(address liquidity_) external {
    require(
      msg.sender == recipient,
      "VestingAndRewardDistribution::setRecipient: unauthorized"
    );
    require(endchange < block.timestamp);
    liquidity = liquidity_;
  }
  
  function setRandomizedPool(address randomizedpool_) external {
    require(
      msg.sender == recipient,
      "VestingAndRewardDistribution::setRandomizedPool: unauthorized"
    );
    require(deployment < block.timestamp);
    randomizedpool = randomizedpool_;
  }

  function setETHPool(address pooleth_) external {
    require(
      msg.sender == recipient,
      "VestingAndRewardDistribution::setRandomizedPool: unauthorized"
    );
    require(endchange < block.timestamp);
    pooleth = pooleth_;
  }

  function claim() external {
    uint256 amount;
    if (block.timestamp >= vestingEnd) {
      amount = ICrt(crt).balanceOf(address(this));
    } else {
      amount = vestingAmount.mul(block.timestamp - lastUpdate).div(
        vestingEnd - vestingBegin
      );
      lastUpdate = block.timestamp;
    }
    ICrt(crt).transfer(recipient, amount);
  }
  
  
  function rewardLPandPools() external {
    require(block.timestamp > timestamped);
    timestamped = block.timestamp + 86400;
    ICrt(crt).transfer(pooleth, 150 ether);
    ICrt(crt).transfer(liquidity, 25 ether);
    ICrt(crt).transfer(msg.sender, 2 ether);
  }
  
    function rewardPoolGovernance() external {
    require(block.timestamp > deployment); // can be used in 7 days when pool goes live
    require(block.timestamp > timestamped2);
    timestamped2 = block.timestamp + 86400;
    ICrt(crt).transfer(governancepool, 50 ether);
    ICrt(crt).transfer(msg.sender, 2 ether);
  }
  
    function rewardPoolRandomized() external {
    require(block.timestamp > deployment); // can be used in 7 days when pool goes live
    require(block.timestamp > timestamped3);
    timestamped3 = block.timestamp + 86400;
    ICrt(crt).transfer(randomizedpool, 50 ether);
    ICrt(crt).transfer(msg.sender, 2 ether);
  }
  
  
}

interface ICrt {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address dst, uint256 rawAmount) external returns (bool);
  function delegate(address delegatee) external;
}