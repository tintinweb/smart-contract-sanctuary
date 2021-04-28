// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./StrongPoolInterface.sol";
import "./IERC1155Preset.sol";
import "./StrongNFTBonusInterface.sol";
import "./rewards.sol";

contract ServiceV13 {
  event Requested(address indexed miner);
  event Claimed(address indexed miner, uint256 reward);

  using SafeMath for uint256;
  bool public initDone;
  address public admin;
  address public pendingAdmin;
  address public superAdmin;
  address public pendingSuperAdmin;
  address public serviceAdmin;
  address public parameterAdmin;
  address payable public feeCollector;

  IERC20 public strongToken;
  StrongPoolInterface public strongPool;

  uint256 public rewardPerBlockNumerator;
  uint256 public rewardPerBlockDenominator;

  uint256 public naasRewardPerBlockNumerator;
  uint256 public naasRewardPerBlockDenominator;

  uint256 public claimingFeeNumerator;
  uint256 public claimingFeeDenominator;

  uint256 public requestingFeeInWei;

  uint256 public strongFeeInWei;

  uint256 public recurringFeeInWei;
  uint256 public recurringNaaSFeeInWei;
  uint256 public recurringPaymentCycleInBlocks;

  uint256 public rewardBalance;

  mapping(address => uint256) public entityBlockLastClaimedOn;

  address[] public entities;
  mapping(address => uint256) public entityIndex;
  mapping(address => bool) public entityActive;
  mapping(address => bool) public requestPending;
  mapping(address => bool) public entityIsNaaS;
  mapping(address => uint256) public paidOnBlock;
  uint256 public activeEntities;

  string public desciption;

  uint256 public claimingFeeInWei;

  uint256 public naasRequestingFeeInWei;

  uint256 public naasStrongFeeInWei;

  bool public removedTokens;

  mapping(address => uint256) public traunch;

  uint256 public currentTraunch;

  mapping(bytes => bool) public entityNodeIsActive;
  mapping(bytes => bool) public entityNodeIsBYON;
  mapping(bytes => uint256) public entityNodeTraunch;
  mapping(bytes => uint256) public entityNodePaidOnBlock;
  mapping(bytes => uint256) public entityNodeClaimedOnBlock;
  mapping(address => uint128) public entityNodeCount;

  event Paid(address indexed entity, uint128 nodeId, bool isBYON, bool isRenewal, uint256 upToBlockNumber);
  event Migrated(address indexed from, address indexed to, uint128 fromNodeId, uint128 toNodeId, bool isBYON);

  uint256 public rewardPerBlockNumeratorNew;
  uint256 public rewardPerBlockDenominatorNew;
  uint256 public naasRewardPerBlockNumeratorNew;
  uint256 public naasRewardPerBlockDenominatorNew;
  uint256 public rewardPerBlockNewEffectiveBlock;

  StrongNFTBonusInterface public strongNFTBonus;

  uint256 public gracePeriodInBlocks;

  uint128 public maxNodes;
  uint256 public maxPaymentPeriods;

  function init(
    address strongTokenAddress,
    address strongPoolAddress,
    address adminAddress,
    address superAdminAddress,
    uint256 rewardPerBlockNumeratorValue,
    uint256 rewardPerBlockDenominatorValue,
    uint256 naasRewardPerBlockNumeratorValue,
    uint256 naasRewardPerBlockDenominatorValue,
    uint256 requestingFeeInWeiValue,
    uint256 strongFeeInWeiValue,
    uint256 recurringFeeInWeiValue,
    uint256 recurringNaaSFeeInWeiValue,
    uint256 recurringPaymentCycleInBlocksValue,
    uint256 claimingFeeNumeratorValue,
    uint256 claimingFeeDenominatorValue,
    string memory desc
  ) public {
    require(!initDone, "init done");
    strongToken = IERC20(strongTokenAddress);
    strongPool = StrongPoolInterface(strongPoolAddress);
    admin = adminAddress;
    superAdmin = superAdminAddress;
    rewardPerBlockNumerator = rewardPerBlockNumeratorValue;
    rewardPerBlockDenominator = rewardPerBlockDenominatorValue;
    naasRewardPerBlockNumerator = naasRewardPerBlockNumeratorValue;
    naasRewardPerBlockDenominator = naasRewardPerBlockDenominatorValue;
    requestingFeeInWei = requestingFeeInWeiValue;
    strongFeeInWei = strongFeeInWeiValue;
    recurringFeeInWei = recurringFeeInWeiValue;
    recurringNaaSFeeInWei = recurringNaaSFeeInWeiValue;
    claimingFeeNumerator = claimingFeeNumeratorValue;
    claimingFeeDenominator = claimingFeeDenominatorValue;
    recurringPaymentCycleInBlocks = recurringPaymentCycleInBlocksValue;
    desciption = desc;
    initDone = true;
  }

  function updateServiceAdmin(address newServiceAdmin) public {
    require(msg.sender == superAdmin);
    serviceAdmin = newServiceAdmin;
  }

  function updateParameterAdmin(address newParameterAdmin) public {
    require(newParameterAdmin != address(0));
    require(msg.sender == superAdmin);
    parameterAdmin = newParameterAdmin;
  }

  function updateFeeCollector(address payable newFeeCollector) public {
    require(newFeeCollector != address(0));
    require(msg.sender == superAdmin);
    feeCollector = newFeeCollector;
  }

  function setPendingAdmin(address newPendingAdmin) public {
    require(msg.sender == admin);
    pendingAdmin = newPendingAdmin;
  }

  function acceptAdmin() public {
    require(msg.sender == pendingAdmin && msg.sender != address(0), "not pendingAdmin");
    admin = pendingAdmin;
    pendingAdmin = address(0);
  }

  function setPendingSuperAdmin(address newPendingSuperAdmin) public {
    require(msg.sender == superAdmin, "not superAdmin");
    pendingSuperAdmin = newPendingSuperAdmin;
  }

  function acceptSuperAdmin() public {
    require(msg.sender == pendingSuperAdmin && msg.sender != address(0), "not pendingSuperAdmin");
    superAdmin = pendingSuperAdmin;
    pendingSuperAdmin = address(0);
  }

  function isEntityActive(address entity) public view returns (bool) {
    return entityActive[entity] || (doesNodeExist(entity, 1) && !hasNodeExpired(entity, 1));
  }

  function updateRewardPerBlock(uint256 numerator, uint256 denominator) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
    require(denominator != 0);
    rewardPerBlockNumerator = numerator;
    rewardPerBlockDenominator = denominator;
  }

  function updateNaaSRewardPerBlock(uint256 numerator, uint256 denominator) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
    require(denominator != 0);
    naasRewardPerBlockNumerator = numerator;
    naasRewardPerBlockDenominator = denominator;
  }

  function updateRewardPerBlockNew(
    uint256 numerator,
    uint256 denominator,
    uint256 numeratorNass,
    uint256 denominatorNass,
    uint256 effectiveBlock
  ) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);

    rewardPerBlockNumeratorNew = numerator;
    rewardPerBlockDenominatorNew = denominator;
    naasRewardPerBlockNumeratorNew = numeratorNass;
    naasRewardPerBlockDenominatorNew = denominatorNass;
    rewardPerBlockNewEffectiveBlock = effectiveBlock != 0 ? effectiveBlock : block.number;
  }

  function deposit(uint256 amount) public {
    require(msg.sender == superAdmin);
    require(amount > 0);
    strongToken.transferFrom(msg.sender, address(this), amount);
    rewardBalance = rewardBalance.add(amount);
  }

  function withdraw(address destination, uint256 amount) public {
    require(msg.sender == superAdmin);
    require(amount > 0);
    require(rewardBalance >= amount, "not enough");
    strongToken.transfer(destination, amount);
    rewardBalance = rewardBalance.sub(amount);
  }

  function updateRequestingFee(uint256 feeInWei) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
    requestingFeeInWei = feeInWei;
  }

  function updateStrongFee(uint256 feeInWei) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
    strongFeeInWei = feeInWei;
  }

  function updateNaasRequestingFee(uint256 feeInWei) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
    naasRequestingFeeInWei = feeInWei;
  }

  function updateNaasStrongFee(uint256 feeInWei) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
    naasStrongFeeInWei = feeInWei;
  }

  function updateClaimingFee(uint256 numerator, uint256 denominator) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
    require(denominator != 0);
    claimingFeeNumerator = numerator;
    claimingFeeDenominator = denominator;
  }

  function updateRecurringFee(uint256 feeInWei) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
    recurringFeeInWei = feeInWei;
  }

  function updateRecurringNaaSFee(uint256 feeInWei) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
    recurringNaaSFeeInWei = feeInWei;
  }

  function updateRecurringPaymentCycleInBlocks(uint256 blocks) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
    require(blocks > 0);
    recurringPaymentCycleInBlocks = blocks;
  }

  function updateGracePeriodInBlocks(uint256 blocks) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
    require(blocks > 0);
    gracePeriodInBlocks = blocks;
  }

  function requestAccess(bool isNaaS) public payable {
    require(entityNodeCount[msg.sender] < maxNodes, "limit reached");

    uint256 rFee;
    uint256 sFee;

    if (hasLegacyNode(msg.sender)) {
      migrateLegacyNode(msg.sender);
    }

    uint128 nodeId = entityNodeCount[msg.sender] + 1;
    bytes memory id = getNodeId(msg.sender, nodeId);

    if (isNaaS) {
      rFee = naasRequestingFeeInWei;
      sFee = naasStrongFeeInWei;
      activeEntities = activeEntities.add(1);
    } else {
      rFee = requestingFeeInWei;
      sFee = strongFeeInWei;
      entityNodeIsBYON[id] = true;
    }

    require(msg.value == rFee, "invalid fee");

    entityNodePaidOnBlock[id] = block.number;
    entityNodeClaimedOnBlock[id] = block.number;
    entityNodeCount[msg.sender] = entityNodeCount[msg.sender] + 1;

    feeCollector.transfer(msg.value);
    strongToken.transferFrom(msg.sender, address(this), sFee);
    strongToken.transfer(feeCollector, sFee);

    emit Paid(msg.sender, nodeId, entityNodeIsBYON[id], false, entityNodePaidOnBlock[id].add(recurringPaymentCycleInBlocks));
  }

  function setEntityActiveStatus(address entity, bool status) public {
    require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin);
    uint256 index = entityIndex[entity];
    require(entities[index] == entity, "invalid entity");
    require(entityActive[entity] != status, "already set");
    entityActive[entity] = status;
    if (status) {
      activeEntities = activeEntities.add(1);
      entityBlockLastClaimedOn[entity] = block.number;
    } else {
      activeEntities = activeEntities.sub(1);
      entityBlockLastClaimedOn[entity] = 0;
    }
  }

  function payFee(uint128 nodeId) public payable {
    address sender = msg.sender == address(this) ? tx.origin : msg.sender;
    bytes memory id = getNodeId(sender, nodeId);

    if (hasLegacyNode(sender)) {
      migrateLegacyNode(sender);
    }

    require(doesNodeExist(sender, nodeId), "doesnt exist");
    require(hasNodeExpired(sender, nodeId) == false, "too late");
    require(hasMaxPayments(sender, nodeId) == false, "too soon");

    if (entityNodeIsBYON[id]) {
      require(msg.value == recurringFeeInWei, "invalid fee");
    } else {
      require(msg.value == recurringNaaSFeeInWei, "invalid fee");
    }

    feeCollector.transfer(msg.value);
    entityNodePaidOnBlock[id] = entityNodePaidOnBlock[id].add(recurringPaymentCycleInBlocks);

    emit Paid(sender, nodeId, entityNodeIsBYON[id], true, entityNodePaidOnBlock[id]);
  }

  function getReward(address entity, uint128 nodeId) public view returns (uint256) {
    return getRewardByBlock(entity, nodeId, block.number);
  }

  function getRewardByBlock(address entity, uint128 nodeId, uint256 blockNumber) public view returns (uint256) {
    bytes memory id = getNodeId(entity, nodeId);

    if (hasLegacyNode(entity)) {
      return getRewardByBlockLegacy(entity, blockNumber);
    }

    uint256 blockLastClaimedOn = entityNodeClaimedOnBlock[id] != 0 ? entityNodeClaimedOnBlock[id] : entityNodePaidOnBlock[id];

    if (blockNumber > block.number) return 0;
    if (blockLastClaimedOn == 0) return 0;
    if (blockNumber < blockLastClaimedOn) return 0;
    if (activeEntities == 0) return 0;
    if (entityNodeIsBYON[id] && !entityNodeIsActive[id]) return 0;

    uint256 rewardNumerator = entityNodeIsBYON[id] ? rewardPerBlockNumerator : naasRewardPerBlockNumerator;
    uint256 rewardDenominator = entityNodeIsBYON[id] ? rewardPerBlockDenominator : naasRewardPerBlockDenominator;
    uint256 newRewardNumerator = entityNodeIsBYON[id] ? rewardPerBlockNumeratorNew : naasRewardPerBlockNumeratorNew;
    uint256 newRewardDenominator = entityNodeIsBYON[id] ? rewardPerBlockDenominatorNew : naasRewardPerBlockDenominatorNew;

    uint256 bonus = address(strongNFTBonus) != address(0)
    ? strongNFTBonus.getBonus(entity, nodeId, blockLastClaimedOn, blockNumber)
    : 0;

    uint256[2] memory rewardBlocks = rewards.blocks(blockLastClaimedOn, rewardPerBlockNewEffectiveBlock, blockNumber);
    uint256 rewardOld = rewardDenominator > 0 ? rewardBlocks[0].mul(rewardNumerator).div(rewardDenominator) : 0;
    uint256 rewardNew = newRewardDenominator > 0 ? rewardBlocks[1].mul(newRewardNumerator).div(newRewardDenominator) : 0;

    return rewardOld.add(rewardNew).add(bonus);
  }

  function getRewardByBlockLegacy(address entity, uint256 blockNumber) public view returns (uint256) {
    if (blockNumber > block.number) return 0;
    if (entityBlockLastClaimedOn[entity] == 0) return 0;
    if (blockNumber < entityBlockLastClaimedOn[entity]) return 0;
    if (activeEntities == 0) return 0;
    uint256 blockResult = blockNumber.sub(entityBlockLastClaimedOn[entity]);
    uint256 rewardNumerator;
    uint256 rewardDenominator;
    if (entityIsNaaS[entity]) {
      rewardNumerator = naasRewardPerBlockNumerator;
      rewardDenominator = naasRewardPerBlockDenominator;
    } else {
      rewardNumerator = rewardPerBlockNumerator;
      rewardDenominator = rewardPerBlockDenominator;
    }
    uint256 rewardPerBlockResult = blockResult.mul(rewardNumerator).div(rewardDenominator);

    return rewardPerBlockResult;
  }

  function claim(uint128 nodeId, uint256 blockNumber, bool toStrongPool) public payable {
    address sender = msg.sender == address(this) || msg.sender == address(strongNFTBonus) ? tx.origin : msg.sender;
    bytes memory id = getNodeId(sender, nodeId);

    if (hasLegacyNode(sender)) {
      migrateLegacyNode(sender);
    }

    uint256 blockLastClaimedOn = entityNodeClaimedOnBlock[id] != 0 ? entityNodeClaimedOnBlock[id] : entityNodePaidOnBlock[id];
    uint256 blockLastPaidOn = entityNodePaidOnBlock[id];

    require(blockLastClaimedOn != 0, "never claimed");
    require(blockNumber <= block.number, "invalid block");
    require(blockNumber > blockLastClaimedOn, "too soon");
    require(!entityNodeIsBYON[id] || entityNodeIsActive[id], "not active");

    if (
      (!entityNodeIsBYON[id] && recurringNaaSFeeInWei != 0) || (entityNodeIsBYON[id] && recurringFeeInWei != 0)
    ) {
      require(blockNumber < blockLastPaidOn.add(recurringPaymentCycleInBlocks), "pay fee");
    }

    uint256 reward = getRewardByBlock(sender, nodeId, blockNumber);
    require(reward > 0, "no reward");

    uint256 fee = reward.mul(claimingFeeNumerator).div(claimingFeeDenominator);
    require(msg.value >= fee, "invalid fee");

    feeCollector.transfer(msg.value);

    if (toStrongPool) {
      strongToken.approve(address(strongPool), reward);
      strongPool.mineFor(sender, reward);
    } else {
      strongToken.transfer(sender, reward);
    }

    rewardBalance = rewardBalance.sub(reward);
    entityNodeClaimedOnBlock[id] = blockNumber;
    emit Claimed(sender, reward);
  }

  function getRewardAll(address entity, uint256 blockNumber) public view returns (uint256) {
    uint256 rewardsAll = 0;

    for (uint128 i = 1; i <= entityNodeCount[entity]; i++) {
      rewardsAll = rewardsAll.add(getRewardByBlock(entity, i, blockNumber > 0 ? blockNumber : block.number));
    }

    return rewardsAll;
  }

  function canBePaid(address entity, uint128 nodeId) public view returns (bool) {
    return !isNodeBYON(entity, nodeId) && !hasNodeExpired(entity, nodeId) && !hasMaxPayments(entity, nodeId);
  }

  function doesNodeExist(address entity, uint128 nodeId) public view returns (bool) {
    bytes memory id = getNodeId(entity, nodeId);
    return entityNodePaidOnBlock[id] > 0;
  }

  function hasNodeExpired(address entity, uint128 nodeId) public view returns (bool) {
    bytes memory id = getNodeId(entity, nodeId);
    uint256 blockLastPaidOn = entityNodePaidOnBlock[id];
    return block.number > blockLastPaidOn.add(recurringPaymentCycleInBlocks).add(gracePeriodInBlocks);
  }

  function hasMaxPayments(address entity, uint128 nodeId) public view returns (bool) {
    bytes memory id = getNodeId(entity, nodeId);
    uint256 blockLastPaidOn = entityNodePaidOnBlock[id];
    uint256 limit = block.number.add(recurringPaymentCycleInBlocks.mul(maxPaymentPeriods));

    return blockLastPaidOn.add(recurringPaymentCycleInBlocks) >= limit;
  }

  function getNodeId(address entity, uint128 nodeId) public view returns (bytes memory) {
    uint128 id = nodeId != 0 ? nodeId : entityNodeCount[entity] + 1;
    return abi.encodePacked(entity, id);
  }

  function getNodePaidOn(address entity, uint128 nodeId) public view returns (uint256) {
    bytes memory id = getNodeId(entity, nodeId);
    return entityNodePaidOnBlock[id];
  }

  function isNodeActive(address entity, uint128 nodeId) public view returns (bool) {
    bytes memory id = getNodeId(entity, nodeId);
    return entityNodeIsActive[id] || !entityNodeIsBYON[id];
  }

  function isNodeBYON(address entity, uint128 nodeId) public view returns (bool) {
    bytes memory id = getNodeId(entity, nodeId);
    return entityNodeIsBYON[id];
  }

  function hasLegacyNode(address entity) public view returns (bool) {
    return entityActive[entity] && entityNodeCount[entity] == 0;
  }

  function approveBYONNode(address entity, uint128 nodeId) public {
    require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin);

    bytes memory id = getNodeId(entity, nodeId);
    entityNodeIsActive[id] = true;
    entityNodeClaimedOnBlock[id] = block.number;
    activeEntities = activeEntities.add(1);
  }

  function suspendBYONNode(address entity, uint128 nodeId) public {
    require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin);

    bytes memory id = getNodeId(entity, nodeId);
    entityNodeIsActive[id] = false;
    activeEntities = activeEntities.sub(1);
  }

  function setNodeIsActive(address entity, uint128 nodeId, bool isActive) public {
    require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin);
    bytes memory id = getNodeId(entity, nodeId);

    if (isActive && !entityNodeIsActive[id]) {
      activeEntities = activeEntities.add(1);
      entityNodeClaimedOnBlock[id] = block.number;
    }

    if (!isActive && entityNodeIsActive[id]) {
      activeEntities = activeEntities.sub(1);
    }

    entityNodeIsActive[id] = isActive;
  }

  function setNodeIsNaaS(address entity, uint128 nodeId, bool isNaaS) public {
    require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin);
    bytes memory id = getNodeId(entity, nodeId);

    entityNodeIsBYON[id] = !isNaaS;
  }

  function migrateLegacyNode(address entity) private {
    bytes memory id = getNodeId(entity, 1);
    entityNodeClaimedOnBlock[id] = entityBlockLastClaimedOn[entity];
    entityNodePaidOnBlock[id] = paidOnBlock[entity];
    entityNodeIsBYON[id] = !entityIsNaaS[entity];
    if (entityNodeIsBYON[id]) {
      entityNodeIsActive[id] = true;
    }
    entityNodeCount[msg.sender] = 1;
  }

  function migrateNode(uint128 nodeId, address to) public {
    if (hasLegacyNode(msg.sender)) {
      migrateLegacyNode(msg.sender);
    }

    if (hasLegacyNode(to)) {
      migrateLegacyNode(to);
    }

    require(doesNodeExist(msg.sender, nodeId), "doesnt exist");

    uint128 toNodeId = entityNodeCount[to] + 1;
    bytes memory fromId = getNodeId(msg.sender, nodeId);
    bytes memory toId = getNodeId(to, toNodeId);

    // move node to another address
    entityNodeIsActive[toId] = entityNodeIsActive[fromId];
    entityNodeIsBYON[toId] = entityNodeIsBYON[fromId];
    entityNodePaidOnBlock[toId] = entityNodePaidOnBlock[fromId];
    entityNodeClaimedOnBlock[toId] = entityNodeClaimedOnBlock[fromId];
    entityNodeCount[to] = entityNodeCount[to] + 1;

    // deactivate node
    entityNodeIsActive[fromId] = false;
    entityNodePaidOnBlock[fromId] = 0;
    entityNodeClaimedOnBlock[fromId] = 0;
    entityNodeCount[msg.sender] = entityNodeCount[msg.sender] - 1;

    emit Migrated(msg.sender, to, nodeId, toNodeId, entityNodeIsBYON[fromId]);
  }

  function claimAll(uint256 blockNumber, bool toStrongPool) public payable {
    for (uint16 i = 1; i <= entityNodeCount[msg.sender]; i++) {
      uint256 reward = getRewardByBlock(msg.sender, i, blockNumber);
      uint256 fee = reward.mul(claimingFeeNumerator).div(claimingFeeDenominator);
      this.claim{value : fee}(i, blockNumber, toStrongPool);
    }
  }

  function payAll(uint256 nodeCount) public payable {
    require(nodeCount > 0, "invalid value");
    require(msg.value == recurringNaaSFeeInWei.mul(nodeCount), "invalid fee");

    for (uint16 nodeId = 1; nodeId <= entityNodeCount[msg.sender]; nodeId++) {
      if (!canBePaid(msg.sender, nodeId)) {
        continue;
      }

      this.payFee{value : recurringNaaSFeeInWei}(nodeId);
      nodeCount = nodeCount.sub(1);
    }

    require(nodeCount == 0, "invalid count");
  }

  function addNFTBonusContract(address _contract) public {
    require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin);

    strongNFTBonus = StrongNFTBonusInterface(_contract);
  }

  function payFeeAdmin(address entity, uint128[] memory nodes) public {
    require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin);

    for (uint256 i = 0; i < nodes.length; i++) {
      uint128 nodeId = nodes[i];
      bytes memory id = getNodeId(entity, nodeId);
      entityNodePaidOnBlock[id] = entityNodePaidOnBlock[id].add(recurringPaymentCycleInBlocks);

      emit Paid(entity, nodeId, entityNodeIsBYON[id], true, entityNodePaidOnBlock[id]);
    }
  }

  function updateLimits(uint128 _maxNodes, uint256 _maxPaymentPeriods) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);

    maxNodes = _maxNodes;
    maxPaymentPeriods = _maxPaymentPeriods;
  }
}