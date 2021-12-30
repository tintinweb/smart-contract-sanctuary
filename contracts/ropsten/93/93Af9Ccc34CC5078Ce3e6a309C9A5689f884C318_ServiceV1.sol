//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ServiceV1 {
  event Claimed(address indexed entity, uint256 reward);
  event Paid(address indexed entity, uint128 nodeId, uint256 upToBlockNumber);
  event Created(address indexed entity, bytes nodeId, uint256 blockNumber, uint256 paidOn);

  struct NodeEntity {
      string name;
      uint256 creationBlockNumber;
      uint256 lastClaimBlockNumber;
      uint256 lastPaidBlockNumber;
  }

  mapping(bytes => uint256) public entityNodePaidOnBlock;
  mapping(bytes => uint256) public entityNodeClaimedOnBlock;
  mapping(address => uint128) public entityNodeCount;
  mapping(address => bool) public _isBlacklisted;

  IERC20 public nodeifyToken;
  address public admin = 0xE5CaB58b538CC570388bF8550B5Ecb71A824EFB4;
  address public feeCollectorAddress = 0x0788a572c51802eEF7d198afaD100627B59e9DEC;
  uint128 public maxNodesPerAddress = 100;
  uint256 public nodePrice = 100000000000000000000 wei;
  uint256 public totalNodesCreated;
  uint256 public nodeifyFeeInWei = 2929616229135700 wei; // Random amounts for now
  uint256 public requestingFeeInWei = 1929616229135700 wei; // Random amounts for now
  uint128 public rewardPerBlock = 10000000000000000000 wei; // 1 token 
  uint128 public maxPaymentPeriods = 3;
  uint256 public rewardBalance;
  uint256 public gracePeriodInBlocks = 70000;
  uint256 public recurringPaymentCycleInBlocks = 210000;
  uint256 public recurringFeeInWei = 2929616229135700 wei; // $13 USD
  uint256 public claimingFeeNumerator = 3; // 6%
  uint256 public claimingFeeDenominator = 50; // 6%

  constructor(address _nodeifyTokenAddress) {
    nodeifyToken = IERC20(_nodeifyTokenAddress);
  }

  function createNode(string memory name) public payable {
      require(entityNodeCount[msg.sender] < maxNodesPerAddress, "limit reached");
      require(
          bytes(name).length > 3 && bytes(name).length < 32,
          "Name Size Invalid"
      );
      address sender = msg.sender;
      require(
          sender != address(0),
          "Creation from the zero address"
      );
      require(!_isBlacklisted[sender], "Blacklisted address");
      require(
          nodeifyToken.balanceOf(sender) >= nodePrice,
          "Balance too low for creation"
      );
      uint128 nodeId = entityNodeCount[msg.sender] + 1;
      bytes memory id = getNodeId(msg.sender, nodeId);

      uint256 rFee;
      uint256 sFee;

      entityNodePaidOnBlock[id] = block.number;
      entityNodeClaimedOnBlock[id] = block.number;
      entityNodeCount[msg.sender] = entityNodeCount[msg.sender] + 1;

      rFee = requestingFeeInWei;
      sFee = nodeifyFeeInWei;

      totalNodesCreated = totalNodesCreated + 1;
      payable(feeCollectorAddress).transfer(msg.value);
      nodeifyToken.transferFrom(msg.sender, address(this), sFee);
      nodeifyToken.transfer(feeCollectorAddress, sFee);

      emit Created(msg.sender, id, block.number, entityNodePaidOnBlock[id] + recurringPaymentCycleInBlocks);
  }

  function claimAll() public payable {
    uint256 value = msg.value;
    for (uint16 i = 1; i <= entityNodeCount[msg.sender]; i++) {
      uint256 reward = getRewardByBlock(msg.sender, i);
      uint256 fee = (reward * 3) / 50;
      require(value >= fee, "invalid fee");
      if (reward > 0) {
        require(this.claim{value : fee}(i, block.number), "claim failed");
      }
      value = value - fee;
    }
  }

  modifier onlyOwner {
    require(msg.sender == admin, "Not Owner");
    _;
  }

  function updateNaasRequestingFee(uint256 feeInWei) public onlyOwner {
    requestingFeeInWei = feeInWei;
  }

  function updateNaasNodeifyFee(uint256 feeInWei) public onlyOwner {
    nodeifyFeeInWei = feeInWei;
  }

  function updateClaimingFee(uint256 numerator, uint256 denominator) public onlyOwner {
    require(denominator != 0, "Claiming fee required");
    claimingFeeNumerator = numerator;
    claimingFeeDenominator = denominator;
  }

  function updateRecurringFee(uint256 feeInWei) public onlyOwner {
    recurringFeeInWei = feeInWei;
  }

  function updateRecurringPaymentCycleInBlocks(uint256 blocks) public onlyOwner {
    require(blocks > 0, "Period Blocks Must be above 0");
    recurringPaymentCycleInBlocks = blocks;
  }

  function updateGracePeriodInBlocks(uint256 blocks) public onlyOwner {
    require(blocks > 0, "Period Blocks Must be above 0");
    gracePeriodInBlocks = blocks;
  }

  modifier nonNillValue(uint256 _amount) {
    require(_amount > 0, "Not Nill Value");
    _;
  }

  function deposit(uint256 amount) public onlyOwner nonNillValue(amount) {
    nodeifyToken.transferFrom(msg.sender, address(this), amount);
    rewardBalance = rewardBalance + amount;
  }

  function withdraw(address destination, uint256 amount) public onlyOwner nonNillValue(amount) {
    require(rewardBalance >= amount, "not enough");
    rewardBalance = rewardBalance - amount;
    nodeifyToken.transfer(destination, amount);
  }

  function claim(uint128 nodeId, uint256 blockNumber) public payable returns (bool) {
    address sender = msg.sender;
    bytes memory id = getNodeId(sender, nodeId);

    uint256 blockLastClaimedOn = entityNodeClaimedOnBlock[id] != 0 ? entityNodeClaimedOnBlock[id] : entityNodeClaimedOnBlock[id];
    uint256 blockLastPaidOn = entityNodePaidOnBlock[id];

    require(blockLastClaimedOn != 0, "never claimed");
    require(blockNumber <= block.number, "invalid block");
    require(blockNumber > blockLastClaimedOn, "too soon");
    require(blockNumber < blockLastPaidOn + recurringPaymentCycleInBlocks, "pay fee");
    
    uint256 reward = getRewardByBlock(sender, nodeId);
    require(reward > 0, "no reward");

    uint256 fee = reward * claimingFeeNumerator / claimingFeeDenominator;
    require(msg.value >= fee, "invalid fee");
    
    rewardBalance = rewardBalance - reward;
    entityNodeClaimedOnBlock[id] = blockNumber;

    payable(feeCollectorAddress).transfer(msg.value);
    nodeifyToken.transfer(sender, reward);
  
    emit Claimed(sender, reward);

    return true;
  }

  function canBePaid(address entity, uint128 nodeId) public view returns (bool) {
    return !hasNodeExpired(entity, nodeId) && !hasMaxPayments(entity, nodeId);
  }

  function getNodeId(address entity, uint128 nodeId) public view returns (bytes memory) {
    uint128 id = nodeId != 0 ? nodeId : entityNodeCount[entity] + 1;
    return abi.encodePacked(entity, id);
  }

  function doesNodeExist(address entity, uint128 nodeId) public view returns (bool) {
    bytes memory id = getNodeId(entity, nodeId);
    return entityNodePaidOnBlock[id] > 0;
  }

  function hasNodeExpired(address entity, uint128 nodeId) public view returns (bool) {
    bytes memory id = getNodeId(entity, nodeId);
    uint256 blockLastPaidOn = entityNodePaidOnBlock[id];

    if (doesNodeExist(entity, nodeId) == false) return true;

    return block.number > blockLastPaidOn + recurringPaymentCycleInBlocks + gracePeriodInBlocks;
  }

  function hasMaxPayments(address entity, uint128 nodeId) public view returns (bool) {
    bytes memory id = getNodeId(entity, nodeId);
    uint256 blockLastPaidOn = entityNodePaidOnBlock[id];
    uint256 limit = block.number + recurringPaymentCycleInBlocks * maxPaymentPeriods;

    return blockLastPaidOn + recurringPaymentCycleInBlocks >= limit;
  }

  function payAll(uint256 nodeCount) public payable {
    require(nodeCount > 0, "invalid value");
    require(msg.value == recurringFeeInWei * nodeCount, "invalid fee");

    for (uint16 nodeId = 1; nodeId <= entityNodeCount[msg.sender]; nodeId++) {
      if (!canBePaid(msg.sender, nodeId)) {
        continue;
      }

      this.payFee{value : recurringFeeInWei}(nodeId);
      nodeCount = nodeCount - 1;
    }

    require(nodeCount == 0, "invalid count");
  }

  function payFee(uint128 nodeId) public payable {
    address sender = msg.sender;
    bytes memory id = getNodeId(sender, nodeId);

    require(doesNodeExist(sender, nodeId), "doesnt exist");
    require(hasNodeExpired(sender, nodeId) == false, "too late");
    require(hasMaxPayments(sender, nodeId) == false, "too soon");
    require(msg.value == recurringFeeInWei, "invalid fee");

    entityNodePaidOnBlock[id] = entityNodePaidOnBlock[id] + recurringPaymentCycleInBlocks;
    payable(feeCollectorAddress).transfer(msg.value);

    emit Paid(sender, nodeId, entityNodePaidOnBlock[id]);
  }

  function getReward(address entity, uint128 nodeId) public view returns (uint256) {
    return getRewardByBlock(entity, nodeId);
  }

  function getRewardAll(address entity) public view returns (uint256) {
    uint256 rewardsAll = 0;

    for (uint128 i = 1; i <= entityNodeCount[entity]; i++) {
      rewardsAll = rewardsAll + getRewardByBlock(entity, i);
    }

    return rewardsAll;
  }

  function getRewardByBlock(address entity, uint128 nodeId) public view returns (uint256) {
    bytes memory id = getNodeId(msg.sender, nodeId);

    uint256 blockLastClaimedOn = entityNodeClaimedOnBlock[id] != 0 ? entityNodeClaimedOnBlock[id] : entityNodePaidOnBlock[id];
    // TODO add many checks here to ensure the reward is correct
    // if (hasNodeExpired(entity, nodeId)) return 0;
    // if (blockLastClaimedOn == 0) return 0;
    // if (block.number < blockLastClaimedOn) return 0;

    uint256 reward = (block.number - blockLastClaimedOn) * rewardPerBlock;
    return reward;
  }

  function blacklistMalicious(address account, bool value)
      external
      onlyOwner
  {
      _isBlacklisted[account] = value;
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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