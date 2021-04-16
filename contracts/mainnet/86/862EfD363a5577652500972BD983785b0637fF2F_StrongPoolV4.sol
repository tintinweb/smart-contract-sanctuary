// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./VoteInterface.sol";
import "./rewards.sol";

contract StrongPoolV4 {
  event MinedFor(address indexed miner, uint256 amount);
  event Mined(address indexed miner, uint256 amount);
  event MinedForVotesOnly(address indexed miner, uint256 amount);
  event UnminedForVotesOnly(address indexed miner, uint256 amount);
  event Unmined(address indexed miner, uint256 amount);
  event Claimed(address indexed miner, uint256 reward);

  using SafeMath for uint256;

  bool public initDone;
  address public admin;
  address public pendingAdmin;
  address public superAdmin;
  address public pendingSuperAdmin;
  address public parameterAdmin;
  address payable public feeCollector;

  IERC20 public strongToken;
  VoteInterface public vote;

  mapping(address => uint256) public minerBalance;
  uint256 public totalBalance;
  mapping(address => uint256) public minerBlockLastClaimedOn;

  mapping(address => uint256) public minerVotes;

  uint256 public rewardBalance;

  uint256 public rewardPerBlockNumerator;
  uint256 public rewardPerBlockDenominator;

  uint256 public miningFeeNumerator;
  uint256 public miningFeeDenominator;

  uint256 public unminingFeeNumerator;
  uint256 public unminingFeeDenominator;

  uint256 public claimingFeeNumerator;
  uint256 public claimingFeeDenominator;

  mapping(address => uint256) public inboundContractIndex;
  address[] public inboundContracts;
  mapping(address => bool) public inboundContractTrusted;

  uint256 public claimingFeeInWei;

  bool public removedTokens;

  uint256 public rewardPerBlockNumeratorNew;
  uint256 public rewardPerBlockDenominatorNew;
  uint256 public rewardPerBlockNewEffectiveBlock;

  function init(
    address voteAddress,
    address strongTokenAddress,
    address adminAddress,
    address superAdminAddress,
    uint256 rewardPerBlockNumeratorValue,
    uint256 rewardPerBlockDenominatorValue,
    uint256 miningFeeNumeratorValue,
    uint256 miningFeeDenominatorValue,
    uint256 unminingFeeNumeratorValue,
    uint256 unminingFeeDenominatorValue,
    uint256 claimingFeeNumeratorValue,
    uint256 claimingFeeDenominatorValue
  ) public {
    require(!initDone, "init done");
    vote = VoteInterface(voteAddress);
    strongToken = IERC20(strongTokenAddress);
    admin = adminAddress;
    superAdmin = superAdminAddress;
    rewardPerBlockNumerator = rewardPerBlockNumeratorValue;
    rewardPerBlockDenominator = rewardPerBlockDenominatorValue;
    miningFeeNumerator = miningFeeNumeratorValue;
    miningFeeDenominator = miningFeeDenominatorValue;
    unminingFeeNumerator = unminingFeeNumeratorValue;
    unminingFeeDenominator = unminingFeeDenominatorValue;
    claimingFeeNumerator = claimingFeeNumeratorValue;
    claimingFeeDenominator = claimingFeeDenominatorValue;
    initDone = true;
  }

  // ADMIN
  // *************************************************************************************
  function updateParameterAdmin(address newParameterAdmin) public {
    require(newParameterAdmin != address(0), "zero");
    require(msg.sender == superAdmin);
    parameterAdmin = newParameterAdmin;
  }

  function updateFeeCollector(address payable newFeeCollector) public {
    require(newFeeCollector != address(0), "zero");
    require(msg.sender == superAdmin);
    feeCollector = newFeeCollector;
  }

  function setPendingAdmin(address newPendingAdmin) public {
    require(newPendingAdmin != address(0), "zero");
    require(msg.sender == admin, "not admin");
    pendingAdmin = newPendingAdmin;
  }

  function acceptAdmin() public {
    require(msg.sender == pendingAdmin && msg.sender != address(0), "not pendingAdmin");
    admin = pendingAdmin;
    pendingAdmin = address(0);
  }

  function setPendingSuperAdmin(address newPendingSuperAdmin) public {
    require(newPendingSuperAdmin != address(0), "zero");
    require(msg.sender == superAdmin, "not superAdmin");
    pendingSuperAdmin = newPendingSuperAdmin;
  }

  function acceptSuperAdmin() public {
    require(msg.sender == pendingSuperAdmin && msg.sender != address(0), "not pendingSuperAdmin");
    superAdmin = pendingSuperAdmin;
    pendingSuperAdmin = address(0);
  }

  // INBOUND CONTRACTS
  // *************************************************************************************
  function addInboundContract(address contr) public {
    require(contr != address(0), "zero");
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not an admin");
    if (inboundContracts.length != 0) {
      uint256 index = inboundContractIndex[contr];
      require(inboundContracts[index] != contr, "exists");
    }
    uint256 len = inboundContracts.length;
    inboundContractIndex[contr] = len;
    inboundContractTrusted[contr] = true;
    inboundContracts.push(contr);
  }

  function inboundContractTrustStatus(address contr, bool trustStatus) public {
    require(contr != address(0), "zero");
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not an admin");
    uint256 index = inboundContractIndex[contr];
    require(inboundContracts[index] == contr, "not exists");
    inboundContractTrusted[contr] = trustStatus;
  }

  // REWARD
  // *************************************************************************************
  function updateRewardPerBlock(uint256 numerator, uint256 denominator) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not an admin");
    require(denominator != 0, "invalid value");
    rewardPerBlockNumerator = numerator;
    rewardPerBlockDenominator = denominator;
  }

  function deposit(uint256 amount) public {
    require(msg.sender == superAdmin, "not an admin");
    require(amount > 0, "zero");
    strongToken.transferFrom(msg.sender, address(this), amount);
    rewardBalance = rewardBalance.add(amount);
  }

  function withdraw(address destination, uint256 amount) public {
    require(msg.sender == superAdmin, "not an admin");
    require(amount > 0, "zero");
    require(rewardBalance >= amount, "not enough");
    strongToken.transfer(destination, amount);
    rewardBalance = rewardBalance.sub(amount);
  }

  // FEES
  // *************************************************************************************
  function updateMiningFee(uint256 numerator, uint256 denominator) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not an admin");
    require(denominator != 0, "invalid value");
    miningFeeNumerator = numerator;
    miningFeeDenominator = denominator;
  }

  function updateUnminingFee(uint256 numerator, uint256 denominator) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not an admin");
    require(denominator != 0, "invalid value");
    unminingFeeNumerator = numerator;
    unminingFeeDenominator = denominator;
  }

  function updateClaimingFee(uint256 numerator, uint256 denominator) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not an admin");
    require(denominator != 0, "invalid value");
    claimingFeeNumerator = numerator;
    claimingFeeDenominator = denominator;
  }

  // CORE
  // *************************************************************************************
  function mineForVotesOnly(uint256 amount) public {
    require(amount > 0, "zero");
    strongToken.transferFrom(msg.sender, address(this), amount);
    minerVotes[msg.sender] = minerVotes[msg.sender].add(amount);
    vote.updateVotes(msg.sender, amount, true);
    emit MinedForVotesOnly(msg.sender, amount);
  }

  function unmineForVotesOnly(uint256 amount) public {
    require(amount > 0, "zero");
    require(minerVotes[msg.sender] >= amount, "not enough");
    minerVotes[msg.sender] = minerVotes[msg.sender].sub(amount);
    vote.updateVotes(msg.sender, amount, false);
    strongToken.transfer(msg.sender, amount);
    emit UnminedForVotesOnly(msg.sender, amount);
  }

  function mineFor(address miner, uint256 amount) public {
    require(inboundContractTrusted[msg.sender], "not trusted");
    require(amount > 0, "zero");
    strongToken.transferFrom(msg.sender, address(this), amount);
    minerBalance[miner] = minerBalance[miner].add(amount);
    totalBalance = totalBalance.add(amount);
    if (minerBlockLastClaimedOn[miner] == 0) {
      minerBlockLastClaimedOn[miner] = block.number;
    }
    vote.updateVotes(miner, amount, true);
    emit MinedFor(miner, amount);
  }

  function mine(uint256 amount) public payable {
    require(amount > 0, "zero");
    uint256 fee = amount.mul(miningFeeNumerator).div(miningFeeDenominator);
    require(msg.value == fee, "invalid fee");
    feeCollector.transfer(msg.value);
    strongToken.transferFrom(msg.sender, address(this), amount);
    if (block.number > minerBlockLastClaimedOn[msg.sender]) {
      uint256 reward = getReward(msg.sender);
      if (reward > 0) {
        minerBalance[msg.sender] = minerBalance[msg.sender].add(reward);
        totalBalance = totalBalance.add(reward);
        rewardBalance = rewardBalance.sub(reward);
        vote.updateVotes(msg.sender, reward, true);
        minerBlockLastClaimedOn[msg.sender] = block.number;
      }
    }
    minerBalance[msg.sender] = minerBalance[msg.sender].add(amount);
    totalBalance = totalBalance.add(amount);
    if (minerBlockLastClaimedOn[msg.sender] == 0) {
      minerBlockLastClaimedOn[msg.sender] = block.number;
    }
    vote.updateVotes(msg.sender, amount, true);
    emit Mined(msg.sender, amount);
  }

  function unmine(uint256 amount) public payable {
    require(amount > 0, "zero");
    uint256 fee = amount.mul(unminingFeeNumerator).div(unminingFeeDenominator);
    require(msg.value == fee, "invalid fee");
    require(minerBalance[msg.sender] >= amount, "not enough");
    feeCollector.transfer(msg.value);
    bool unmineAll = (amount == minerBalance[msg.sender]);
    if (block.number > minerBlockLastClaimedOn[msg.sender]) {
      uint256 reward = getReward(msg.sender);
      if (reward > 0) {
        minerBalance[msg.sender] = minerBalance[msg.sender].add(reward);
        totalBalance = totalBalance.add(reward);
        rewardBalance = rewardBalance.sub(reward);
        vote.updateVotes(msg.sender, reward, true);
        minerBlockLastClaimedOn[msg.sender] = block.number;
      }
    }
    uint256 amountToUnmine = unmineAll ? minerBalance[msg.sender] : amount;
    minerBalance[msg.sender] = minerBalance[msg.sender].sub(amountToUnmine);
    totalBalance = totalBalance.sub(amountToUnmine);
    strongToken.transfer(msg.sender, amountToUnmine);
    vote.updateVotes(msg.sender, amountToUnmine, false);
    if (minerBalance[msg.sender] == 0) {
      minerBlockLastClaimedOn[msg.sender] = 0;
    }
    emit Unmined(msg.sender, amountToUnmine);
  }

  function claim(uint256 blockNumber) public payable {
    require(blockNumber <= block.number, "invalid block number");
    require(minerBlockLastClaimedOn[msg.sender] != 0, "error");
    require(blockNumber > minerBlockLastClaimedOn[msg.sender], "too soon");
    uint256 reward = getRewardByBlock(msg.sender, blockNumber);
    require(reward > 0, "no reward");
    uint256 fee = reward.mul(claimingFeeNumerator).div(claimingFeeDenominator);
    require(msg.value == fee, "invalid fee");
    feeCollector.transfer(msg.value);
    minerBalance[msg.sender] = minerBalance[msg.sender].add(reward);
    totalBalance = totalBalance.add(reward);
    rewardBalance = rewardBalance.sub(reward);
    minerBlockLastClaimedOn[msg.sender] = blockNumber;
    vote.updateVotes(msg.sender, reward, true);
    emit Claimed(msg.sender, reward);
  }

  function getReward(address miner) public view returns (uint256) {
    return getRewardByBlock(miner, block.number);
  }

  function getRewardByBlock(address miner, uint256 blockNumber) public view returns (uint256) {
    uint256 blockLastClaimedOn = minerBlockLastClaimedOn[miner];

    if (blockNumber > block.number) return 0;
    if (blockLastClaimedOn == 0) return 0;
    if (blockNumber < blockLastClaimedOn) return 0;
    if (totalBalance == 0) return 0;

    uint256[2] memory rewardBlocks = rewards.blocks(blockLastClaimedOn, rewardPerBlockNewEffectiveBlock, blockNumber);
    uint256 rewardOld = rewardPerBlockDenominator > 0 ? rewardBlocks[0].mul(rewardPerBlockNumerator).div(rewardPerBlockDenominator) : 0;
    uint256 rewardNew = rewardPerBlockDenominatorNew > 0 ? rewardBlocks[1].mul(rewardPerBlockNumeratorNew).div(rewardPerBlockDenominatorNew) : 0;

    return rewardOld.add(rewardNew).mul(minerBalance[miner]).div(totalBalance);
  }

  function updateRewardPerBlockNew(
    uint256 numerator,
    uint256 denominator,
    uint256 effectiveBlock
  ) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");

    rewardPerBlockNumeratorNew = numerator;
    rewardPerBlockDenominatorNew = denominator;
    rewardPerBlockNewEffectiveBlock = effectiveBlock != 0 ? effectiveBlock : block.number;
  }
}