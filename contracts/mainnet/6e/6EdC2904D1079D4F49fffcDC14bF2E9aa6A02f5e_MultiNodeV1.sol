// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./interfaces/IERC20.sol";
import "./interfaces/IMultiNode.sol";
import "./interfaces/IStrongPool.sol";
import "./interfaces/IStrongNFTBonus.sol";
import "./lib/InternalCalls.sol";
import "./lib/MultiNodeSettings.sol";
import "./lib/SbMath.sol";

contract MultiNodeV1 is IMultiNode, InternalCalls, MultiNodeSettings {

  uint private constant _SECONDS_IN_ONE_MINUTE = 60;

  IERC20 public strongToken;
  IStrongNFTBonus public strongNFTBonus;

  uint public totalNodes;
  uint public nodesLimit;
  uint public takeStrongBips;
  address payable public feeCollector;
  mapping(address => bool) private serviceContractEnabled;

  mapping(address => uint) public entityNodeCount;
  mapping(address => uint) public entityCreditUsed;
  mapping(address => mapping(uint => uint)) public entityNodeTypeCount;
  mapping(bytes => uint) public entityNodeType;
  mapping(bytes => uint) public entityNodeCreatedAt;
  mapping(bytes => uint) public entityNodeLastPaidAt;
  mapping(bytes => uint) public entityNodeLastClaimedAt;

  // Events

  event Created(address indexed entity, uint nodeType, uint nodeId, bool usedCredit, uint timestamp);
  event Paid(address indexed entity, uint nodeType, uint nodeId, uint timestamp);
  event Claimed(address indexed entity, uint nodeId, uint reward);
  event MigratedFromService(address indexed service, address indexed entity, uint nodeType, uint nodeId, uint lastPaidAt);
  event SetFeeCollector(address payable collector);
  event SetNFTBonusContract(address strongNFTBonus);
  event SetNodesLimit(uint limit);
  event SetServiceContractEnabled(address service, bool enabled);
  event SetTakeStrongBips(uint bips);

  function init(
    IERC20 _strongToken,
    IStrongNFTBonus _strongNFTBonus,
    address payable _feeCollector
  ) external onlyRole(adminControl.SUPER_ADMIN()) {
    require(_feeCollector != address(0), "no address");

    strongToken = _strongToken;
    strongNFTBonus = _strongNFTBonus;
    feeCollector = _feeCollector;

    InternalCalls.init();
  }

  //
  // Getters
  // -------------------------------------------------------------------------------------------------------------------

  function getRewardBalance() external view returns (uint) {
    return strongToken.balanceOf(address(this));
  }

  function calcDecayedReward(uint _baseRate, uint _decayFactor, uint _minutesPassed) public pure returns (uint) {
    uint power = SbMath._decPow(_decayFactor, _minutesPassed);
    uint cumulativeFraction = SbMath.DECIMAL_PRECISION - power;

    return _baseRate * cumulativeFraction / SbMath.DECIMAL_PRECISION;
  }

  function canNodeBePaid(address _entity, uint _nodeId) public view returns (bool) {
    return doesNodeExist(_entity, _nodeId) && !hasNodeExpired(_entity, _nodeId) && !hasMaxPayments(_entity, _nodeId);
  }

  function doesNodeExist(address _entity, uint _nodeId) public view returns (bool) {
    return entityNodeLastPaidAt[getNodeId(_entity, _nodeId)] > 0;
  }

  function isNodePastDue(address _entity, uint _nodeId) public view returns (bool) {
    bytes memory id = getNodeId(_entity, _nodeId);
    uint nodeType = entityNodeType[id];
    uint lastPaidAt = entityNodeLastPaidAt[id];

    return block.timestamp > (lastPaidAt + getRecurringPaymentCycle(nodeType));
  }

  function hasNodeExpired(address _entity, uint _nodeId) public view returns (bool) {
    bytes memory id = getNodeId(_entity, _nodeId);
    uint nodeType = entityNodeType[id];
    uint lastPaidAt = entityNodeLastPaidAt[id];
    if (lastPaidAt == 0) return true;

    return block.timestamp > (lastPaidAt + getRecurringPaymentCycle(nodeType) + getGracePeriod(nodeType));
  }

  function hasMaxPayments(address _entity, uint _nodeId) public view returns (bool) {
    bytes memory id = getNodeId(_entity, _nodeId);
    uint nodeType = entityNodeType[id];
    uint lastPaidAt = entityNodeLastPaidAt[id];
    uint recurringPaymentCycle = getRecurringPaymentCycle(nodeType);
    uint limit = block.timestamp + recurringPaymentCycle * getPayCyclesLimit(nodeType);

    return lastPaidAt + recurringPaymentCycle >= limit;
  }

  function getNodeId(address _entity, uint _nodeId) public view returns (bytes memory) {
    uint id = _nodeId != 0 ? _nodeId : entityNodeCount[_entity] + 1;
    return abi.encodePacked(_entity, id);
  }

  function getNodeType(address _entity, uint _nodeId) public view returns (uint) {
    return entityNodeType[getNodeId(_entity, _nodeId)];
  }

  function getNodeRecurringFee(address _entity, uint _nodeId) external view returns (uint) {
    return getRecurringFeeInWei(entityNodeType[getNodeId(_entity, _nodeId)]);
  }

  function getNodeClaimingFee(address _entity, uint _nodeId, uint _timestamp) external view returns (uint) {
    uint nodeType = entityNodeType[getNodeId(_entity, _nodeId)];
    uint reward = getRewardAt(_entity, _nodeId, _timestamp);
    return reward * getClaimingFeeNumerator(nodeType) / getClaimingFeeDenominator(nodeType);
  }

  function getNodePaidOn(address _entity, uint _nodeId) external view returns (uint) {
    return entityNodeLastPaidAt[getNodeId(_entity, _nodeId)];
  }

  function getNodeReward(address _entity, uint _nodeId) external view returns (uint) {
    return getRewardAt(_entity, _nodeId, block.timestamp);
  }

  function getRewardAt(address _entity, uint _nodeId, uint _timestamp) public view returns (uint) {
    bytes memory id = getNodeId(_entity, _nodeId);
    uint nodeType = entityNodeType[id];
    uint lastClaimedAt = entityNodeLastClaimedAt[id] != 0 ? entityNodeLastClaimedAt[id] : entityNodeCreatedAt[id];
    uint registeredAt = entityNodeCreatedAt[id];

    if (!doesNodeExist(_entity, _nodeId)) return 0;
    if (hasNodeExpired(_entity, _nodeId)) return 0;
    if (_timestamp > block.timestamp) return 0;
    if (_timestamp <= lastClaimedAt) return 0;

    uint minutesTotal = (_timestamp - registeredAt) / _SECONDS_IN_ONE_MINUTE;

    uint reward = calcDecayedReward(
      getRewardBaseRate(nodeType),
      getRewardDecayFactor(nodeType),
      minutesTotal
    );

    if (lastClaimedAt > 0) {
      uint minutesToLastClaim = (lastClaimedAt - registeredAt) / _SECONDS_IN_ONE_MINUTE;
      uint rewardAtLastClaim = calcDecayedReward(getRewardBaseRate(nodeType), getRewardDecayFactor(nodeType), minutesToLastClaim);
      reward = reward - rewardAtLastClaim;
    }

    uint bonus = getNftBonusAt(_entity, _nodeId, _timestamp);

    return reward + bonus;
  }

  function getNftBonusAt(address _entity, uint _nodeId, uint _timestamp) public view returns (uint) {
    if (address(strongNFTBonus) == address(0)) return 0;

    bytes memory id = getNodeId(_entity, _nodeId);
    uint nodeType = entityNodeType[id];
    uint lastClaimedAt = entityNodeLastClaimedAt[id] != 0 ? entityNodeLastClaimedAt[id] : entityNodeCreatedAt[id];
    string memory bonusName = strongNFTBonus.getStakedNftBonusName(_entity, uint128(_nodeId), address(this));

    if (keccak256(abi.encode(bonusName)) == keccak256(abi.encode(""))) return 0;

    uint bonusValue = getNftBonusValue(nodeType, bonusName);

    return bonusValue > 0
    ? strongNFTBonus.getBonusValue(_entity, uint128(_nodeId), lastClaimedAt, _timestamp, bonusValue)
    : 0;
  }

  function getEntityRewards(address _entity, uint _timestamp) public view returns (uint) {
    uint reward = 0;

    for (uint nodeId = 1; nodeId <= entityNodeCount[_entity]; nodeId++) {
      reward = reward + getRewardAt(_entity, nodeId, _timestamp > 0 ? _timestamp : block.timestamp);
    }

    return reward;
  }

  function getEntityCreditAvailable(address _entity, uint _timestamp) public view returns (uint) {
    return getEntityRewards(_entity, _timestamp) - entityCreditUsed[_entity];
  }

  function getNodesRecurringFee(address _entity, uint _fromNode, uint _toNode) external view returns (uint) {
    uint fee = 0;
    uint fromNode = _fromNode > 0 ? _fromNode : 1;
    uint toNode = _toNode > 0 ? _toNode : entityNodeCount[_entity];

    for (uint nodeId = fromNode; nodeId <= toNode; nodeId++) {
      if (canNodeBePaid(_entity, nodeId)) fee = fee + getRecurringFeeInWei(getNodeType(_entity, nodeId));
    }

    return fee;
  }

  function getNodesClaimingFee(address _entity, uint _timestamp, uint _fromNode, uint _toNode) external view returns (uint) {
    uint fee = 0;
    uint fromNode = _fromNode > 0 ? _fromNode : 1;
    uint toNode = _toNode > 0 ? _toNode : entityNodeCount[_entity];

    for (uint nodeId = fromNode; nodeId <= toNode; nodeId++) {
      uint reward = getRewardAt(_entity, nodeId, _timestamp > 0 ? _timestamp : block.timestamp);
      if (reward > 0) {
        uint nodeType = getNodeType(_entity, nodeId);
        fee = fee + reward * getClaimingFeeNumerator(nodeType) / getClaimingFeeDenominator(nodeType);
      }
    }

    return fee;
  }

  //
  // Actions
  // -------------------------------------------------------------------------------------------------------------------

  function createNode(uint _nodeType, bool _useCredit) external payable {
    uint fee = getCreatingFeeInWei(_nodeType);
    uint strongFee = getStrongFeeInWei(_nodeType);
    uint nodeTypeLimit = getNodesLimit(_nodeType);

    require(nodeTypeActive[_nodeType], "invalid type");
    require(nodesLimit == 0 || entityNodeCount[msg.sender] < nodesLimit, "over limit");
    require(nodeTypeLimit == 0 || entityNodeTypeCount[msg.sender][_nodeType] < nodeTypeLimit, "over limit");
    require(msg.value >= fee, "invalid fee");

    uint nodeId = entityNodeCount[msg.sender] + 1;
    bytes memory id = getNodeId(msg.sender, nodeId);

    totalNodes = totalNodes + 1;
    entityNodeType[id] = _nodeType;
    entityNodeCreatedAt[id] = block.timestamp;
    entityNodeLastPaidAt[id] = block.timestamp;
    entityNodeCount[msg.sender] = entityNodeCount[msg.sender] + 1;
    entityNodeTypeCount[msg.sender][_nodeType] = entityNodeTypeCount[msg.sender][_nodeType] + 1;

    emit Created(msg.sender, _nodeType, nodeId, _useCredit, block.timestamp);

    if (_useCredit) {
      require(getEntityCreditAvailable(msg.sender, block.timestamp) >= strongFee, "not enough");
      entityCreditUsed[msg.sender] = entityCreditUsed[msg.sender] + strongFee;
    } else {
      uint takeStrong = strongFee * takeStrongBips / 10000;
      require(strongToken.transferFrom(msg.sender, feeCollector, takeStrong), "transfer failed");
      if (strongFee > takeStrong) {
        require(strongToken.transferFrom(msg.sender, address(this), strongFee - takeStrong), "transfer failed");
      }
    }

    sendValue(feeCollector, fee);
    if (msg.value > fee) sendValue(payable(msg.sender), msg.value - fee);
  }

  function claim(uint _nodeId, uint _timestamp, address _toStrongPool) public payable returns (uint) {
    address entity = msg.sender == address(strongNFTBonus) ? tx.origin : msg.sender;
    bytes memory id = getNodeId(entity, _nodeId);
    uint nodeType = entityNodeType[id];
    uint lastClaimedAt = entityNodeLastClaimedAt[id] != 0 ? entityNodeLastClaimedAt[id] : entityNodeCreatedAt[id];

    require(doesNodeExist(entity, _nodeId), "doesnt exist");
    require(!hasNodeExpired(entity, _nodeId), "node expired");
    require(!isNodePastDue(entity, _nodeId), "past due");
    require(_timestamp <= block.timestamp, "bad timestamp");
    require(lastClaimedAt + 900 < _timestamp, "too soon");

    uint reward = getRewardAt(entity, _nodeId, _timestamp);
    require(reward > 0, "no reward");
    require(strongToken.balanceOf(address(this)) >= reward, "over balance");

    uint fee = reward * getClaimingFeeNumerator(nodeType) / getClaimingFeeDenominator(nodeType);
    require(msg.value >= fee, "invalid fee");

    entityNodeLastClaimedAt[id] = _timestamp;

    emit Claimed(entity, _nodeId, reward);

    if (entityCreditUsed[msg.sender] > 0) {
      if (entityCreditUsed[msg.sender] > reward) {
        entityCreditUsed[msg.sender] = entityCreditUsed[msg.sender] - reward;
        reward = 0;
      } else {
        reward = reward - entityCreditUsed[msg.sender];
        entityCreditUsed[msg.sender] = 0;
      }
    }

    if (reward > 0) {
      if (_toStrongPool != address(0)) IStrongPool(_toStrongPool).mineFor(entity, reward);
      else require(strongToken.transfer(entity, reward), "transfer failed");
    }

    sendValue(feeCollector, fee);
    if (isUserCall() && msg.value > fee) sendValue(payable(msg.sender), msg.value - fee);

    return fee;
  }

  function claimAll(uint _timestamp, address _toStrongPool, uint _fromNode, uint _toNode) external payable makesInternalCalls {
    require(entityNodeCount[msg.sender] > 0, "no nodes");

    uint valueLeft = msg.value;
    uint fromNode = _fromNode > 0 ? _fromNode : 1;
    uint toNode = _toNode > 0 ? _toNode : entityNodeCount[msg.sender];

    for (uint nodeId = fromNode; nodeId <= toNode; nodeId++) {
      uint reward = getRewardAt(msg.sender, nodeId, _timestamp);

      if (reward > 0) {
        require(valueLeft > 0, "not enough");
        uint paid = claim(nodeId, _timestamp, _toStrongPool);
        valueLeft = valueLeft - paid;
      }
    }

    if (valueLeft > 0) sendValue(payable(msg.sender), valueLeft);
  }

  function pay(uint _nodeId) public payable returns (uint) {
    bytes memory id = getNodeId(msg.sender, _nodeId);
    uint nodeType = entityNodeType[id];
    uint fee = getRecurringFeeInWei(nodeType);

    require(canNodeBePaid(msg.sender, _nodeId), "cant pay");
    require(msg.value >= fee, "invalid fee");

    entityNodeLastPaidAt[id] = entityNodeLastPaidAt[id] + getRecurringPaymentCycle(nodeType);
    emit Paid(msg.sender, nodeType, _nodeId, entityNodeLastPaidAt[id]);

    sendValue(feeCollector, fee);
    if (isUserCall() && msg.value > fee) sendValue(payable(msg.sender), msg.value - fee);

    return fee;
  }

  function payAll(uint _fromNode, uint _toNode) external payable makesInternalCalls {
    require(entityNodeCount[msg.sender] > 0, "no nodes");

    uint valueLeft = msg.value;
    uint fromNode = _fromNode > 0 ? _fromNode : 1;
    uint toNode = _toNode > 0 ? _toNode : entityNodeCount[msg.sender];

    for (uint nodeId = fromNode; nodeId <= toNode; nodeId++) {
      if (!canNodeBePaid(msg.sender, nodeId)) continue;

      require(valueLeft > 0, "not enough");
      uint paid = pay(nodeId);
      valueLeft = valueLeft - paid;
    }

    if (valueLeft > 0) sendValue(payable(msg.sender), valueLeft);
  }

  function migrateNode(address _entity, uint _nodeType, uint _lastPaidAt) external returns (uint) {
    require(serviceContractEnabled[msg.sender], "no service");
    require(nodeTypeActive[_nodeType], "invalid type");

    uint nodeId = entityNodeCount[_entity] + 1;
    bytes memory id = getNodeId(_entity, nodeId);

    totalNodes = totalNodes + 1;

    entityNodeType[id] = _nodeType;
    entityNodeCreatedAt[id] = _lastPaidAt;
    entityNodeLastPaidAt[id] = _lastPaidAt;
    entityNodeCount[_entity] = entityNodeCount[_entity] + 1;
    entityNodeTypeCount[_entity][_nodeType] = entityNodeTypeCount[_entity][_nodeType] + 1;

    emit MigratedFromService(msg.sender, _entity, _nodeType, nodeId, _lastPaidAt);

    return nodeId;
  }

  //
  // Admin
  // -------------------------------------------------------------------------------------------------------------------

  function deposit(uint _amount) external onlyRole(adminControl.SUPER_ADMIN()) {
    require(_amount > 0);
    require(strongToken.transferFrom(msg.sender, address(this), _amount), "transfer failed");
  }

  function withdraw(address _destination, uint _amount) external onlyRole(adminControl.SUPER_ADMIN()) {
    require(_amount > 0);
    require(strongToken.balanceOf(address(this)) >= _amount, "over balance");
    require(strongToken.transfer(_destination, _amount), "transfer failed");
  }

  function approveStrongPool(IStrongPool _strongPool, uint _amount) external onlyRole(adminControl.SUPER_ADMIN()) {
    require(strongToken.approve(address(_strongPool), _amount), "approve failed");
  }

  function setFeeCollector(address payable _feeCollector) external onlyRole(adminControl.SUPER_ADMIN()) {
    require(_feeCollector != address(0));
    feeCollector = _feeCollector;
    emit SetFeeCollector(_feeCollector);
  }

  function setNFTBonusContract(address _contract) external onlyRole(adminControl.SERVICE_ADMIN()) {
    strongNFTBonus = IStrongNFTBonus(_contract);
    emit SetNFTBonusContract(_contract);
  }

  function setNodesLimit(uint _limit) external onlyRole(adminControl.SERVICE_ADMIN()) {
    nodesLimit = _limit;
    emit SetNodesLimit(_limit);
  }

  function setServiceContractEnabled(address _contract, bool _enabled) external onlyRole(adminControl.SERVICE_ADMIN()) {
    serviceContractEnabled[_contract] = _enabled;
    emit SetServiceContractEnabled(_contract, _enabled);
  }

  function setTakeStrongBips(uint _bips) external onlyRole(adminControl.SUPER_ADMIN()) {
    require(_bips <= 10000, "invalid value");
    takeStrongBips = _bips;
    emit SetTakeStrongBips(_bips);
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "insufficient balance");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success,) = recipient.call{value : amount}("");
    require(success, "send failed");
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IMultiNode {
  function doesNodeExist(address entity, uint nodeId) external view returns (bool);

  function hasNodeExpired(address entity, uint nodeId) external view returns (bool);

  function claim(uint nodeId, uint timestamp, address toStrongPool) external payable returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IStrongPool {
  function mineFor(address miner, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IStrongNFTBonus {
  function getBonus(address _entity, uint128 _nodeId, uint256 _from, uint256 _to) external view returns (uint256);

  function getBonusValue(address _entity, uint128 _nodeId, uint256 _from, uint256 _to, uint256 _bonusValue) external view returns (uint256);

  function getStakedNftBonusName(address _entity, uint128 _nodeId, address _serviceContract) external view returns (string memory);

  function migrateNFT(address _entity, uint128 _fromNodeId, uint128 _toNodeId, address _toServiceContract) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./Context.sol";

abstract contract InternalCalls is Context {

  uint private constant _NOT_MAKING_INTERNAL_CALLS = 1;
  uint private constant _MAKING_INTERNAL_CALLS = 2;

  uint private _internal_calls_status;

  modifier makesInternalCalls() {
    _internal_calls_status = _MAKING_INTERNAL_CALLS;
    _;
    _internal_calls_status = _NOT_MAKING_INTERNAL_CALLS;
  }

  function init() internal {
    _internal_calls_status = _NOT_MAKING_INTERNAL_CALLS;
  }

  function isInternalCall() internal view returns (bool) {
    return _internal_calls_status == _MAKING_INTERNAL_CALLS;
  }

  function isContractCall() internal view returns (bool) {
    return _msgSender() != tx.origin;
  }

  function isUserCall() internal view returns (bool) {
    return !isInternalCall() && !isContractCall();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./AdminAccess.sol";

contract MultiNodeSettings is AdminAccess {

  uint constant public NODE_TYPE_REWARD_BASE_RATE = 0;
  uint constant public NODE_TYPE_REWARD_DECAY_FACTOR = 1;
  uint constant public NODE_TYPE_FEE_STRONG = 2;
  uint constant public NODE_TYPE_FEE_CREATE = 3;
  uint constant public NODE_TYPE_FEE_RECURRING = 4;
  uint constant public NODE_TYPE_FEE_CLAIMING_NUMERATOR = 5;
  uint constant public NODE_TYPE_FEE_CLAIMING_DENOMINATOR = 6;
  uint constant public NODE_TYPE_RECURRING_CYCLE_SECONDS = 7;
  uint constant public NODE_TYPE_GRACE_PERIOD_SECONDS = 8;
  uint constant public NODE_TYPE_PAY_CYCLES_LIMIT = 9;
  uint constant public NODE_TYPE_NODES_LIMIT = 10;

  mapping(uint => bool) public nodeTypeActive;
  mapping(uint => bool) public nodeTypeHasSettings;
  mapping(uint => mapping(uint => uint)) public nodeTypeSettings;
  mapping(uint => mapping(string => uint)) public nodeTypeNFTBonus;

  // Events

  event SetNodeTypeActive(uint nodeType, bool active);
  event SetNodeTypeSetting(uint nodeType, uint settingId, uint value);
  event SetNodeTypeHasSettings(uint nodeType, bool hasSettings);
  event SetNodeTypeNFTBonus(uint nodeType, string bonusName, uint value);

  //
  // Getters
  // -------------------------------------------------------------------------------------------------------------------

  function getRewardBaseRate(uint _nodeType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_nodeType, NODE_TYPE_REWARD_BASE_RATE);
  }

  function getRewardDecayFactor(uint _nodeType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_nodeType, NODE_TYPE_REWARD_DECAY_FACTOR);
  }

  function getClaimingFeeNumerator(uint _nodeType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_nodeType, NODE_TYPE_FEE_CLAIMING_NUMERATOR);
  }

  function getClaimingFeeDenominator(uint _nodeType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_nodeType, NODE_TYPE_FEE_CLAIMING_DENOMINATOR);
  }

  function getCreatingFeeInWei(uint _nodeType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_nodeType, NODE_TYPE_FEE_CREATE);
  }

  function getRecurringFeeInWei(uint _nodeType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_nodeType, NODE_TYPE_FEE_RECURRING);
  }

  function getStrongFeeInWei(uint _nodeType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_nodeType, NODE_TYPE_FEE_STRONG);
  }

  function getRecurringPaymentCycle(uint _nodeType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_nodeType, NODE_TYPE_RECURRING_CYCLE_SECONDS);
  }

  function getGracePeriod(uint _nodeType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_nodeType, NODE_TYPE_GRACE_PERIOD_SECONDS);
  }

  function getPayCyclesLimit(uint _nodeType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_nodeType, NODE_TYPE_PAY_CYCLES_LIMIT);
  }

  function getNodesLimit(uint _nodeType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_nodeType, NODE_TYPE_NODES_LIMIT);
  }

  function getNftBonusValue(uint _nodeType, string memory _bonusName) public view returns (uint) {
    return nodeTypeNFTBonus[_nodeType][_bonusName] > 0
    ? nodeTypeNFTBonus[_nodeType][_bonusName]
    : nodeTypeNFTBonus[0][_bonusName];
  }

  //
  // Setters
  // -------------------------------------------------------------------------------------------------------------------

  function setNodeTypeActive(uint _nodeType, bool _active) external onlyRole(adminControl.SERVICE_ADMIN()) {
    // Node type 0 is being used as a placeholder for the default settings for node types that don't have custom ones,
    // So it shouldn't be activated and used to create nodes
    require(_nodeType > 0, "invalid type");
    nodeTypeActive[_nodeType] = _active;
    emit SetNodeTypeActive(_nodeType, _active);
  }

  function setNodeTypeHasSettings(uint _nodeType, bool _hasSettings) external onlyRole(adminControl.SERVICE_ADMIN()) {
    nodeTypeHasSettings[_nodeType] = _hasSettings;
    emit SetNodeTypeHasSettings(_nodeType, _hasSettings);
  }

  function setNodeTypeSetting(uint _nodeType, uint _settingId, uint _value) external onlyRole(adminControl.SERVICE_ADMIN()) {
    nodeTypeHasSettings[_nodeType] = true;
    nodeTypeSettings[_nodeType][_settingId] = _value;
    emit SetNodeTypeSetting(_nodeType, _settingId, _value);
  }

  function setNodeTypeNFTBonus(uint _nodeType, string memory _bonusName, uint _value) external onlyRole(adminControl.SERVICE_ADMIN()) {
    nodeTypeNFTBonus[_nodeType][_bonusName] = _value;
    emit SetNodeTypeNFTBonus(_nodeType, _bonusName, _value);
  }

  // -------------------------------------------------------------------------------------------------------------------

  function getCustomSettingOrDefaultIfZero(uint _nodeType, uint _setting) internal view returns (uint) {
    return nodeTypeHasSettings[_nodeType] && nodeTypeSettings[_nodeType][_setting] > 0
    ? nodeTypeSettings[_nodeType][_setting]
    : nodeTypeSettings[0][_setting];
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

library SbMath {

  uint internal constant DECIMAL_PRECISION = 1e18;

  /*
  * Multiply two decimal numbers and use normal rounding rules:
  * -round product up if 19'th mantissa digit >= 5
  * -round product down if 19'th mantissa digit < 5
  *
  * Used only inside the exponentiation, _decPow().
  */
  function decMul(uint x, uint y) internal pure returns (uint decProd) {
    uint prod_xy = x * y;

    decProd = (prod_xy + (DECIMAL_PRECISION / 2)) / DECIMAL_PRECISION;
  }

  /*
  * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
  *
  * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
  *
  * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
  * "minutes in 1000 years": 60 * 24 * 365 * 1000
  */
  function _decPow(uint _base, uint _minutes) internal pure returns (uint) {

    if (_minutes > 525_600_000) _minutes = 525_600_000;  // cap to avoid overflow

    if (_minutes == 0) return DECIMAL_PRECISION;

    uint y = DECIMAL_PRECISION;
    uint x = _base;
    uint n = _minutes;

    // Exponentiation-by-squaring
    while (n > 1) {
      if (n % 2 == 0) {
        x = decMul(x, x);
        n = n / 2;
      } else { // if (n % 2 != 0)
        y = decMul(x, y);
        x = decMul(x, x);
        n = (n - 1) / 2;
      }
    }

    return decMul(x, y);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../interfaces/IAdminControl.sol";

abstract contract AdminAccess {

  IAdminControl public adminControl;

  modifier onlyRole(uint8 _role) {
    require(address(adminControl) == address(0) || adminControl.hasRole(_role, msg.sender), "no access");
    _;
  }

  function addAdminControlContract(IAdminControl _contract) external onlyRole(0) {
    adminControl = _contract;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IAdminControl {
  function hasRole(uint8 _role, address _account) external view returns (bool);

  function SUPER_ADMIN() external view returns (uint8);

  function ADMIN() external view returns (uint8);

  function SERVICE_ADMIN() external view returns (uint8);
}