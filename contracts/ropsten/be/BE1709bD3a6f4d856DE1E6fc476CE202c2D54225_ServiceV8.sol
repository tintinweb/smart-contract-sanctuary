// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import './interfaces/StrongPoolInterface.sol';

contract ServiceV8 {
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
    require(!initDone, 'init done');
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

  // ADMIN
  // *************************************************************************************
  function updateServiceAdmin(address newServiceAdmin) public {
    require(msg.sender == superAdmin);
    serviceAdmin = newServiceAdmin;
  }

  function updateParameterAdmin(address newParameterAdmin) public {
    require(newParameterAdmin != address(0), 'zero');
    require(msg.sender == superAdmin);
    parameterAdmin = newParameterAdmin;
  }

  function updateFeeCollector(address payable newFeeCollector) public {
    require(newFeeCollector != address(0), 'zero');
    require(msg.sender == superAdmin);
    feeCollector = newFeeCollector;
  }

  function setPendingAdmin(address newPendingAdmin) public {
    require(msg.sender == admin, 'not admin');
    pendingAdmin = newPendingAdmin;
  }

  function acceptAdmin() public {
    require(msg.sender == pendingAdmin && msg.sender != address(0), 'not pendingAdmin');
    admin = pendingAdmin;
    pendingAdmin = address(0);
  }

  function setPendingSuperAdmin(address newPendingSuperAdmin) public {
    require(msg.sender == superAdmin, 'not superAdmin');
    pendingSuperAdmin = newPendingSuperAdmin;
  }

  function acceptSuperAdmin() public {
    require(msg.sender == pendingSuperAdmin && msg.sender != address(0), 'not pendingSuperAdmin');
    superAdmin = pendingSuperAdmin;
    pendingSuperAdmin = address(0);
  }

  // ENTITIES
  // *************************************************************************************
  function getEntities() public view returns (address[] memory) {
    return entities;
  }

  function isEntityActive(address entity) public view returns (bool) {
    return entityActive[entity];
  }

  // TRAUNCH
  // *************************************************************************************
  function updateCurrentTraunch(uint256 value) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
    currentTraunch = value;
  }

  function getTraunch(address entity) public view returns (uint256) {
    return traunch[entity];
  }

  // REWARD
  // *************************************************************************************
  function updateRewardPerBlock(uint256 numerator, uint256 denominator) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
    require(denominator != 0, 'invalid value');
    rewardPerBlockNumerator = numerator;
    rewardPerBlockDenominator = denominator;
  }

  function updateNaaSRewardPerBlock(uint256 numerator, uint256 denominator) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
    require(denominator != 0, 'invalid value');
    naasRewardPerBlockNumerator = numerator;
    naasRewardPerBlockDenominator = denominator;
  }

  function deposit(uint256 amount) public {
    require(msg.sender == superAdmin, 'not an admin');
    require(amount > 0, 'zero');
    strongToken.transferFrom(msg.sender, address(this), amount);
    rewardBalance = rewardBalance.add(amount);
  }

  function withdraw(address destination, uint256 amount) public {
    require(msg.sender == superAdmin, 'not an admin');
    require(amount > 0, 'zero');
    require(rewardBalance >= amount, 'not enough');
    strongToken.transfer(destination, amount);
    rewardBalance = rewardBalance.sub(amount);
  }

  function removeTokens() public {
    require(!removedTokens, 'already removed');
    require(msg.sender == superAdmin, 'not an admin');
    // removing 2500 STRONG tokens sent in this tx: 0xe27640beda32a5e49aad3b6692790b9d380ed25da0cf8dca7fd5f3258efa600a
    strongToken.transfer(superAdmin, 2500000000000000000000);
    removedTokens = true;
  }

  // FEES
  // *************************************************************************************
  function updateRequestingFee(uint256 feeInWei) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
    requestingFeeInWei = feeInWei;
  }

  function updateStrongFee(uint256 feeInWei) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
    strongFeeInWei = feeInWei;
  }

  function updateNaasRequestingFee(uint256 feeInWei) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
    naasRequestingFeeInWei = feeInWei;
  }

  function updateNaasStrongFee(uint256 feeInWei) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
    naasStrongFeeInWei = feeInWei;
  }

  function updateClaimingFee(uint256 numerator, uint256 denominator) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
    require(denominator != 0, 'invalid value');
    claimingFeeNumerator = numerator;
    claimingFeeDenominator = denominator;
  }

  function updateRecurringFee(uint256 feeInWei) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
    recurringFeeInWei = feeInWei;
  }

  function updateRecurringNaaSFee(uint256 feeInWei) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
    recurringNaaSFeeInWei = feeInWei;
  }

  function updateRecurringPaymentCycleInBlocks(uint256 blocks) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
    require(blocks > 0, 'zero');
    recurringPaymentCycleInBlocks = blocks;
  }

  // CORE
  // *************************************************************************************
  function requestAccess(bool isNaaS) public payable {
    require(!entityActive[msg.sender], 'active');
    uint256 rFee;
    uint256 sFee;
    if (isNaaS) {
      rFee = naasRequestingFeeInWei;
      sFee = naasStrongFeeInWei;
      uint256 len = entities.length;
      entityIndex[msg.sender] = len;
      entities.push(msg.sender);
      entityActive[msg.sender] = true;
      requestPending[msg.sender] = false;
      activeEntities = activeEntities.add(1);
      entityBlockLastClaimedOn[msg.sender] = block.number;
      paidOnBlock[msg.sender] = block.number;
    } else {
      rFee = requestingFeeInWei;
      sFee = strongFeeInWei;
      requestPending[msg.sender] = true;
    }
    entityIsNaaS[msg.sender] = isNaaS;
    require(msg.value == rFee, 'invalid fee');
    feeCollector.transfer(msg.value);
    strongToken.transferFrom(msg.sender, address(this), sFee);
    strongToken.transfer(feeCollector, sFee);
    traunch[msg.sender] = currentTraunch;
    emit Requested(msg.sender);
  }

  function grantAccess(
    address[] memory ents,
    bool[] memory entIsNaaS,
    bool useChecks
  ) public {
    require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin, 'not admin');
    require(ents.length > 0, 'zero');
    require(ents.length == entIsNaaS.length, 'lengths dont match');
    for (uint256 i = 0; i < ents.length; i++) {
      address entity = ents[i];
      bool naas = entIsNaaS[i];
      if (useChecks) {
        require(requestPending[entity], 'not pending');
        require(entityIsNaaS[entity] == naas, 'naas no match');
      }
      require(!entityActive[entity], 'exists');
      uint256 len = entities.length;
      entityIndex[entity] = len;
      entities.push(entity);
      entityActive[entity] = true;
      requestPending[entity] = false;
      entityIsNaaS[entity] = naas;
      activeEntities = activeEntities.add(1);
      entityBlockLastClaimedOn[entity] = block.number;
      paidOnBlock[entity] = block.number;
      traunch[entity] = currentTraunch;
    }
  }

  function setEntityActiveStatus(address entity, bool status) public {
    require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin, 'not admin');
    uint256 index = entityIndex[entity];
    require(entities[index] == entity, 'invalid entity');
    require(entityActive[entity] != status, 'already set');
    entityActive[entity] = status;
    if (status) {
      activeEntities = activeEntities.add(1);
      entityBlockLastClaimedOn[entity] = block.number;
    } else {
      if (block.number > entityBlockLastClaimedOn[entity]) {
        uint256 reward = getReward(entity);
        if (reward > 0) {
          rewardBalance = rewardBalance.sub(reward);
          strongToken.approve(address(strongPool), reward);
          strongPool.mineFor(entity, reward);
        }
      }
      activeEntities = activeEntities.sub(1);
      entityBlockLastClaimedOn[entity] = 0;
    }
  }

  function setEntityIsNaaS(address entity, bool isNaaS) public {
    require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin, 'not admin');
    uint256 index = entityIndex[entity];
    require(entities[index] == entity, 'invalid entity');

    entityIsNaaS[entity] = isNaaS;
  }

  function setTraunch(address entity, uint256 value) public {
    require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin, 'not admin');
    uint256 index = entityIndex[entity];
    require(entities[index] == entity, 'invalid entity');

    traunch[entity] = value;
  }

  function payFee() public payable {
    if (entityIsNaaS[msg.sender]) {
      require(msg.value == recurringNaaSFeeInWei, 'naas fee');
    } else {
      require(msg.value == recurringFeeInWei, 'basic fee');
    }
    feeCollector.transfer(msg.value);
    paidOnBlock[msg.sender] = paidOnBlock[msg.sender].add(recurringPaymentCycleInBlocks);
  }

  function getReward(address entity) public view returns (uint256) {
    if (activeEntities == 0) return 0;
    if (entityBlockLastClaimedOn[entity] == 0) return 0;
    uint256 blockResult = block.number.sub(entityBlockLastClaimedOn[entity]);
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
    return rewardPerBlockResult.div(activeEntities);
  }

  function getRewardByBlock(address entity, uint256 blockNumber) public view returns (uint256) {
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
    return rewardPerBlockResult.div(activeEntities);
  }

  function claim(uint256 blockNumber, bool toStrongPool) public payable {
    require(blockNumber <= block.number, 'invalid block number');
    require(entityBlockLastClaimedOn[msg.sender] != 0, 'error');
    require(blockNumber > entityBlockLastClaimedOn[msg.sender], 'too soon');
    require(entityActive[msg.sender], 'not active');
    require(paidOnBlock[msg.sender] != 0, 'zero');
    if (
      (entityIsNaaS[msg.sender] && recurringNaaSFeeInWei != 0) || (!entityIsNaaS[msg.sender] && recurringFeeInWei != 0)
    ) {
      require(blockNumber < paidOnBlock[msg.sender].add(recurringPaymentCycleInBlocks), 'pay fee');
    }

    uint256 reward = getRewardByBlock(msg.sender, blockNumber);
    require(reward > 0, 'no reward');
    uint256 fee = reward.mul(claimingFeeNumerator).div(claimingFeeDenominator);
    require(msg.value == fee, 'invalid fee');
    feeCollector.transfer(msg.value);
    if (toStrongPool) {
      strongToken.approve(address(strongPool), reward);
      strongPool.mineFor(msg.sender, reward);
    } else {
      strongToken.transfer(msg.sender, reward);
    }
    rewardBalance = rewardBalance.sub(reward);
    entityBlockLastClaimedOn[msg.sender] = blockNumber;
    emit Claimed(msg.sender, reward);
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface StrongPoolInterface {
  function mineFor(address miner, uint256 amount) external;
}