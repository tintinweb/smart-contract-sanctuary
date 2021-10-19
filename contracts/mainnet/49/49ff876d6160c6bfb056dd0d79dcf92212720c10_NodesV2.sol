// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IERC1155Preset.sol";
import "./interfaces/StrongPoolInterface.sol";
import "./lib/AdminAccessControl.sol";
import "./interfaces/StrongNFTBonusInterface.sol";
import "./lib/rewards.sol";

contract NodesV2 is AdminAccessControl {

  event Requested(address indexed miner);
  event Claimed(address indexed miner, uint256 reward);
  event Paid(address indexed entity, uint128 nodeId, bool isRenewal, uint256 upToBlockNumber);

  using SafeMath for uint256;

  IERC20 public strongToken;
  StrongPoolInterface public strongPool;

  bool public initDone;
  uint256 public activeEntities;
  address payable public feeCollector;
  uint256 public rewardPerBlockNumerator;
  uint256 public rewardPerBlockDenominator;
  uint256 public rewardPerBlockNumeratorNew;
  uint256 public rewardPerBlockDenominatorNew;
  uint256 public rewardPerBlockNewEffectiveBlock;
  uint256 public claimingFeeNumerator;
  uint256 public claimingFeeDenominator;
  uint256 public requestingFeeInWei;
  uint256 public strongFeeInWei;
  uint256 public recurringFeeInWei;
  uint256 public recurringPaymentCycleInBlocks;
  uint256 public rewardBalance;
  uint256 public claimingFeeInWei;
  uint256 public gracePeriodInBlocks;
  uint128 public maxNodes;
  uint256 public maxPaymentPeriods;
  mapping(bytes => uint256) public entityNodePaidOnBlock;
  mapping(bytes => uint256) public entityNodeClaimedOnBlock;
  mapping(address => uint128) public entityNodeCount;

  StrongNFTBonusInterface public strongNFTBonus;

  function init(
    address _strongTokenAddress,
    address _strongPoolAddress,
    uint256 _rewardPerBlockNumeratorValue,
    uint256 _rewardPerBlockDenominatorValue,
    uint256 _requestingFeeInWeiValue,
    uint256 _strongFeeInWeiValue,
    uint256 _recurringFeeInWeiValue,
    uint256 _recurringPaymentCycleInBlocksValue,
    uint256 _claimingFeeNumeratorValue,
    uint256 _claimingFeeDenominatorValue
  ) public {
    require(!initDone, "init done");

    strongToken = IERC20(_strongTokenAddress);
    strongPool = StrongPoolInterface(_strongPoolAddress);
    rewardPerBlockNumerator = _rewardPerBlockNumeratorValue;
    rewardPerBlockDenominator = _rewardPerBlockDenominatorValue;
    requestingFeeInWei = _requestingFeeInWeiValue;
    strongFeeInWei = _strongFeeInWeiValue;
    recurringFeeInWei = _recurringFeeInWeiValue;
    claimingFeeNumerator = _claimingFeeNumeratorValue;
    claimingFeeDenominator = _claimingFeeDenominatorValue;
    recurringPaymentCycleInBlocks = _recurringPaymentCycleInBlocksValue;
    maxNodes = 100;
    initDone = true;
  }

  //
  // Getters
  // -------------------------------------------------------------------------------------------------------------------

  function canBePaid(address _entity, uint128 _nodeId) public view returns (bool) {
    return !hasNodeExpired(_entity, _nodeId) && !hasMaxPayments(_entity, _nodeId);
  }

  function doesNodeExist(address _entity, uint128 _nodeId) public view returns (bool) {
    return entityNodePaidOnBlock[getNodeId(_entity, _nodeId)] > 0;
  }

  function hasNodeExpired(address _entity, uint128 _nodeId) public view returns (bool) {
    uint256 blockLastPaidOn = entityNodePaidOnBlock[getNodeId(_entity, _nodeId)];
    return block.number > blockLastPaidOn.add(recurringPaymentCycleInBlocks).add(gracePeriodInBlocks);
  }

  function hasMaxPayments(address _entity, uint128 _nodeId) public view returns (bool) {
    uint256 blockLastPaidOn = entityNodePaidOnBlock[getNodeId(_entity, _nodeId)];
    uint256 limit = block.number.add(recurringPaymentCycleInBlocks.mul(maxPaymentPeriods));

    return blockLastPaidOn.add(recurringPaymentCycleInBlocks) >= limit;
  }

  function getNodeId(address _entity, uint128 _nodeId) public view returns (bytes memory) {
    uint128 id = _nodeId != 0 ? _nodeId : entityNodeCount[_entity] + 1;
    return abi.encodePacked(_entity, id);
  }

  function getNodePaidOn(address _entity, uint128 _nodeId) public view returns (uint256) {
    return entityNodePaidOnBlock[getNodeId(_entity, _nodeId)];
  }

  function getReward(address _entity, uint128 _nodeId) public view returns (uint256) {
    return getRewardByBlock(_entity, _nodeId, block.number);
  }

  function getRewardAll(address _entity, uint256 _blockNumber) public view returns (uint256) {
    uint256 rewardsAll = 0;

    for (uint128 i = 1; i <= entityNodeCount[_entity]; i++) {
      rewardsAll = rewardsAll.add(getRewardByBlock(_entity, i, _blockNumber > 0 ? _blockNumber : block.number));
    }

    return rewardsAll;
  }

  function getRewardByBlock(address _entity, uint128 _nodeId, uint256 _blockNumber) public view returns (uint256) {
    bytes memory id = getNodeId(_entity, _nodeId);

    uint256 blockLastClaimedOn = entityNodeClaimedOnBlock[id] != 0 ? entityNodeClaimedOnBlock[id] : entityNodePaidOnBlock[id];

    if (_blockNumber > block.number) return 0;
    if (blockLastClaimedOn == 0) return 0;
    if (_blockNumber < blockLastClaimedOn) return 0;

    uint256[2] memory rewardBlocks = rewards.blocks(blockLastClaimedOn, rewardPerBlockNewEffectiveBlock, _blockNumber);
    uint256 rewardOld = rewardPerBlockDenominator > 0 ? rewardBlocks[0].mul(rewardPerBlockNumerator).div(rewardPerBlockDenominator) : 0;
    uint256 rewardNew = rewardPerBlockDenominatorNew > 0 ? rewardBlocks[1].mul(rewardPerBlockNumeratorNew).div(rewardPerBlockDenominatorNew) : 0;

    uint256 bonus = address(strongNFTBonus) != address(0)
    ? strongNFTBonus.getBonus(_entity, _nodeId, blockLastClaimedOn, _blockNumber)
    : 0;

    return rewardOld.add(rewardNew).add(bonus);
  }

  function isEntityActive(address _entity) public view returns (bool) {
    return doesNodeExist(_entity, 1) && !hasNodeExpired(_entity, 1);
  }

  //
  // Actions
  // -------------------------------------------------------------------------------------------------------------------

  function requestAccess() public payable {
    require(entityNodeCount[msg.sender] < maxNodes, "limit reached");
    require(msg.value == requestingFeeInWei, "invalid fee");

    uint128 nodeId = entityNodeCount[msg.sender] + 1;
    bytes memory id = getNodeId(msg.sender, nodeId);

    activeEntities = activeEntities.add(1);

    entityNodePaidOnBlock[id] = block.number;
    entityNodeClaimedOnBlock[id] = block.number;
    entityNodeCount[msg.sender] = entityNodeCount[msg.sender] + 1;

    feeCollector.transfer(msg.value);
    strongToken.transferFrom(msg.sender, feeCollector, strongFeeInWei);

    emit Paid(msg.sender, nodeId, false, entityNodePaidOnBlock[id].add(recurringPaymentCycleInBlocks));
  }

  function payFee(uint128 _nodeId) public payable {
    address sender = msg.sender == address(this) ? tx.origin : msg.sender;
    bytes memory id = getNodeId(sender, _nodeId);

    require(doesNodeExist(sender, _nodeId), "doesnt exist");
    require(hasNodeExpired(sender, _nodeId) == false, "too late");
    require(hasMaxPayments(sender, _nodeId) == false, "too soon");
    require(msg.value == recurringFeeInWei, "invalid fee");

    feeCollector.transfer(msg.value);
    entityNodePaidOnBlock[id] = entityNodePaidOnBlock[id].add(recurringPaymentCycleInBlocks);

    emit Paid(sender, _nodeId, true, entityNodePaidOnBlock[id]);
  }

  function claim(uint128 _nodeId, uint256 _blockNumber, bool _toStrongPool) public payable returns (bool) {
    address sender = msg.sender == address(this) || msg.sender == address(strongNFTBonus) ? tx.origin : msg.sender;
    bytes memory id = getNodeId(sender, _nodeId);

    uint256 blockLastClaimedOn = entityNodeClaimedOnBlock[id] != 0 ? entityNodeClaimedOnBlock[id] : entityNodePaidOnBlock[id];
    uint256 blockLastPaidOn = entityNodePaidOnBlock[id];

    require(blockLastClaimedOn != 0, "never claimed");
    require(_blockNumber <= block.number, "invalid block");
    require(_blockNumber > blockLastClaimedOn, "too soon");

    if (recurringFeeInWei != 0) {
      require(_blockNumber < blockLastPaidOn.add(recurringPaymentCycleInBlocks), "pay fee");
    }

    uint256 reward = getRewardByBlock(sender, _nodeId, _blockNumber);
    require(reward > 0, "no reward");

    uint256 fee = reward.mul(claimingFeeNumerator).div(claimingFeeDenominator);
    require(msg.value >= fee, "invalid fee");

    feeCollector.transfer(msg.value);

    if (_toStrongPool) {
      strongToken.approve(address(strongPool), reward);
      strongPool.mineFor(sender, reward);
    } else {
      strongToken.transfer(sender, reward);
    }

    rewardBalance = rewardBalance.sub(reward);
    entityNodeClaimedOnBlock[id] = _blockNumber;
    emit Claimed(sender, reward);

    return true;
  }

  function claimAll(uint256 _blockNumber, bool _toStrongPool) public payable {
    uint256 value = msg.value;
    for (uint16 i = 1; i <= entityNodeCount[msg.sender]; i++) {
      uint256 reward = getRewardByBlock(msg.sender, i, _blockNumber);
      uint256 fee = reward.mul(claimingFeeNumerator).div(claimingFeeDenominator);
      require(value >= fee, "invalid fee");
      require(this.claim{value : fee}(i, _blockNumber, _toStrongPool), "claim failed");
      value = value.sub(fee);
    }
  }

  function payAll(uint256 _nodeCount) public payable {
    require(_nodeCount > 0, "invalid value");
    require(msg.value == recurringFeeInWei.mul(_nodeCount), "invalid fee");

    for (uint16 nodeId = 1; nodeId <= entityNodeCount[msg.sender]; nodeId++) {
      if (!canBePaid(msg.sender, nodeId)) {
        continue;
      }

      this.payFee{value : recurringFeeInWei}(nodeId);
      _nodeCount = _nodeCount.sub(1);
    }

    require(_nodeCount == 0, "invalid count");
  }

  //
  // Admin
  // -------------------------------------------------------------------------------------------------------------------

  function deposit(uint256 _amount) public onlyRole(adminControl.SUPER_ADMIN()) {
    require(_amount > 0);
    strongToken.transferFrom(msg.sender, address(this), _amount);
    rewardBalance = rewardBalance.add(_amount);
  }

  function withdraw(address _destination, uint256 _amount) public onlyRole(adminControl.SUPER_ADMIN()) {
    require(_amount > 0);
    require(rewardBalance >= _amount, "not enough");
    strongToken.transfer(_destination, _amount);
    rewardBalance = rewardBalance.sub(_amount);
  }

  function updateFeeCollector(address payable _newFeeCollector) public onlyRole(adminControl.SUPER_ADMIN()) {
    require(_newFeeCollector != address(0));
    feeCollector = _newFeeCollector;
  }

  function updateRequestingFee(uint256 _feeInWei) public onlyRole(adminControl.SERVICE_ADMIN()) {
    requestingFeeInWei = _feeInWei;
  }

  function updateStrongFee(uint256 _feeInWei) public onlyRole(adminControl.SERVICE_ADMIN()) {
    strongFeeInWei = _feeInWei;
  }

  function updateClaimingFee(uint256 _numerator, uint256 _denominator) public onlyRole(adminControl.SERVICE_ADMIN()) {
    require(_denominator != 0);
    claimingFeeNumerator = _numerator;
    claimingFeeDenominator = _denominator;
  }

  function updateRecurringFee(uint256 _feeInWei) public onlyRole(adminControl.SERVICE_ADMIN()) {
    recurringFeeInWei = _feeInWei;
  }

  function updateRecurringPaymentCycleInBlocks(uint256 _blocks) public onlyRole(adminControl.SERVICE_ADMIN()) {
    require(_blocks > 0);
    recurringPaymentCycleInBlocks = _blocks;
  }

  function updateGracePeriodInBlocks(uint256 _blocks) public onlyRole(adminControl.SERVICE_ADMIN()) {
    require(_blocks > 0);
    gracePeriodInBlocks = _blocks;
  }

  function updateLimits(uint128 _maxNodes, uint256 _maxPaymentPeriods) public onlyRole(adminControl.SERVICE_ADMIN()) {
    maxNodes = _maxNodes;
    maxPaymentPeriods = _maxPaymentPeriods;
  }

  function updateRewardPerBlock(uint256 _numerator, uint256 _denominator) public onlyRole(adminControl.SERVICE_ADMIN()) {
    require(_denominator != 0);
    rewardPerBlockNumerator = _numerator;
    rewardPerBlockDenominator = _denominator;
  }

  function updateRewardPerBlockNew(uint256 _numerator, uint256 _denominator, uint256 _effectiveBlock) public onlyRole(adminControl.SERVICE_ADMIN()) {
    require(_denominator != 0);
    rewardPerBlockNumeratorNew = _numerator;
    rewardPerBlockDenominatorNew = _denominator;
    rewardPerBlockNewEffectiveBlock = _effectiveBlock != 0 ? _effectiveBlock : block.number;
  }

  function addNFTBonusContract(address _contract) public onlyRole(adminControl.SERVICE_ADMIN()) {
    strongNFTBonus = StrongNFTBonusInterface(_contract);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Preset {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;

    function getOwnerIdByIndex(address owner, uint256 index) external view returns (uint256);

    function getOwnerIdIndex(address owner, uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface StrongPoolInterface {
  function mineFor(address miner, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../interfaces/AdminControlInterface.sol";

abstract contract AdminAccessControl {

  AdminControlInterface public adminControl;

  modifier onlyRole(uint8 _role) {
    require(address(adminControl) == address(0) || adminControl.hasRole(_role, msg.sender), 'no access');
    _;
  }

  function addAdminControlContract(address _contract) public onlyRole(0) {
    adminControl = AdminControlInterface(_contract);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface StrongNFTBonusInterface {
  function getBonus(address _entity, uint128 _nodeId, uint256 _fromBlock, uint256 _toBlock) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

library rewards {

    using SafeMath for uint256;

    function blocks(uint256 lastClaimedOnBlock, uint256 newRewardBlock, uint256 blockNumber) internal pure returns (uint256[2] memory) {
        if (lastClaimedOnBlock >= blockNumber) return [uint256(0), uint256(0)];

        if (blockNumber <= newRewardBlock || newRewardBlock == 0) {
            return [blockNumber.sub(lastClaimedOnBlock), uint256(0)];
        }
        else if (lastClaimedOnBlock >= newRewardBlock) {
            return [uint256(0), blockNumber.sub(lastClaimedOnBlock)];
        }
        else {
            return [newRewardBlock.sub(lastClaimedOnBlock), blockNumber.sub(newRewardBlock)];
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface AdminControlInterface {

  function hasRole(uint8 _role, address _account) external view returns (bool);

  function SUPER_ADMIN() external view returns (uint8);
  function ADMIN() external view returns (uint8);
  function SERVICE_ADMIN() external view returns (uint8);

}