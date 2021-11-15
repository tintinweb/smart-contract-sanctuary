// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../tools/math/PercentageMath.sol';
import '../../tools/Errors.sol';
import '../interfaces/IRewardController.sol';
import '../calcs/CalcLinearUnweightedReward.sol';
import './ControlledRewardPool.sol';

contract TeamRewardPool is ControlledRewardPool, CalcLinearUnweightedReward {
  using PercentageMath for uint256;

  address private _teamManager;
  address private _excessTarget;
  uint32 private _lockupTill;
  uint16 private _totalShare;

  mapping(address => uint256) private _delayed;

  constructor(
    IRewardController controller,
    uint256 initialRate,
    uint16 baselinePercentage,
    address teamManager
  ) ControlledRewardPool(controller, initialRate, baselinePercentage) {
    _teamManager = teamManager;
  }

  function _onlyTeamManagerOrConfigurator() private view {
    require(msg.sender == _teamManager || _isConfigAdmin(msg.sender), Errors.CALLER_NOT_TEAM_MANAGER);
  }

  modifier onlyTeamManagerOrConfigurator() {
    _onlyTeamManagerOrConfigurator();
    _;
  }

  function getPoolName() public pure override returns (string memory) {
    return 'TeamPool';
  }

  function getExcessTarget() external view returns (address) {
    return _excessTarget;
  }

  event ExcessTargetUpdated(address indexed target);

  function setExcessTarget(address target) external onlyTeamManagerOrConfigurator {
    require(target != address(this));
    _excessTarget = target;
    if (target != address(0)) {
      internalAllocateReward(target, 0, uint32(block.timestamp), AllocationMode.SetPull);
    }
    emit ExcessTargetUpdated(target);
  }

  function internalGetRate() internal view override returns (uint256) {
    return super.getLinearRate();
  }

  function internalSetRate(uint256 newRate) internal override {
    super.setLinearRate(newRate);
  }

  function internalCalcRateAndReward(
    RewardBalance memory entry,
    uint256 lastAccumRate,
    uint32 currentBlock
  )
    internal
    view
    override
    returns (
      uint256 rate,
      uint256 allocated,
      uint32 since
    )
  {
    (rate, allocated, since) = super.internalCalcRateAndReward(entry, lastAccumRate, currentBlock);
    allocated = (allocated + PercentageMath.HALF_ONE) / PercentageMath.ONE;
    return (rate, allocated, since);
  }

  function addRewardProvider(address, address) external view override onlyConfigAdmin {
    revert('UNSUPPORTED');
  }

  function removeRewardProvider(address) external override onlyConfigAdmin {}

  function getAllocatedShares() external view returns (uint16) {
    return _totalShare;
  }

  function isUnlocked(uint32 at) public view returns (bool) {
    return _lockupTill > 0 && _lockupTill < at;
  }

  function internalAttachedToRewardController() internal override {
    _updateTeamExcess();
  }

  function updateTeamMembers(address[] calldata members, uint16[] calldata memberSharePct)
    external
    onlyTeamManagerOrConfigurator
  {
    require(members.length == memberSharePct.length);
    for (uint256 i = 0; i < members.length; i++) {
      _updateTeamMember(members[i], memberSharePct[i]);
    }
    _updateTeamExcess();
  }

  function updateTeamMember(address member, uint16 memberSharePct) external onlyTeamManagerOrConfigurator {
    _updateTeamMember(member, memberSharePct);
    _updateTeamExcess();
  }

  event TeamMemberShareUpdated(address indexed member, uint16 memberSharePct);

  function _updateTeamMember(address member, uint16 memberSharePct) private {
    require(member != address(0), 'member is required');
    require(member != address(this), 'member is invalid');
    require(memberSharePct <= PercentageMath.ONE, 'invalid share percentage');

    uint256 newTotalShare = (uint256(_totalShare) + memberSharePct) - getRewardEntry(member).rewardBase;
    require(newTotalShare <= PercentageMath.ONE, 'team total share exceeds 100%');
    _totalShare = uint16(newTotalShare);
    emit TeamMemberShareUpdated(member, memberSharePct);

    (uint256 allocated, uint32 since, AllocationMode mode) = doUpdateRewardBalance(member, memberSharePct);

    if (isUnlocked(getCurrentTick())) {
      allocated = _popDelayed(member, allocated);
    } else if (allocated > 0) {
      _delayed[member] += allocated;
      if (mode == AllocationMode.Push) {
        return;
      }
      allocated = 0;
    }

    internalAllocateReward(member, allocated, since, mode);
  }

  function _popDelayed(address holder, uint256 amount) private returns (uint256) {
    uint256 d = _delayed[holder];
    if (d == 0) {
      return amount;
    }
    delete (_delayed[holder]);
    return amount + d;
  }

  function _updateTeamExcess() private {
    uint256 excess = PercentageMath.ONE - _totalShare;
    (uint256 allocated, , ) = doUpdateRewardBalance(address(this), excess);
    if (allocated > 0) {
      _delayed[address(this)] += allocated;
    }
    emit TeamMemberShareUpdated(address(0), uint16(excess));
  }

  event TeamManagerUpdated(address indexed manager);

  function setTeamManager(address manager) external onlyTeamManagerOrConfigurator {
    _teamManager = manager;
    emit TeamManagerUpdated(manager);
  }

  function getTeamManager() external view returns (address) {
    return _teamManager;
  }

  event UnlockedAtUpdated(uint32 at);

  function setUnlockedAt(uint32 at) external onlyConfigAdmin {
    require(at > 0, 'unlockAt is required');
    require(_lockupTill == 0 || _lockupTill >= getCurrentTick(), 'lockup is finished');
    _lockupTill = at;
    emit UnlockedAtUpdated(at);
  }

  function getUnlockedAt() external view returns (uint32) {
    return _lockupTill;
  }

  function getCurrentTick() internal view override returns (uint32) {
    return uint32(block.timestamp);
  }

  function internalGetReward(address holder)
    internal
    override
    returns (
      uint256 allocated,
      uint32 since,
      bool keep
    )
  {
    if (!isUnlocked(getCurrentTick())) {
      return (0, 0, true);
    }
    (allocated, since, keep) = doGetReward(holder);
    allocated = _popDelayed(holder, allocated);

    if (holder != _excessTarget) {
      return (allocated, since, keep);
    }

    (uint256 allocated2, uint32 since2, ) = doGetReward(address(this));
    allocated2 = _popDelayed(address(this), allocated2);

    return (allocated + allocated2, since2 > since ? since2 : since, true);
  }

  function internalCalcReward(address holder, uint32 at) internal view override returns (uint256, uint32) {
    (uint256 allocated, uint32 since) = doCalcRewardAt(holder, at);
    allocated += _delayed[holder];

    if (holder != _excessTarget) {
      return (allocated, since);
    }

    (uint256 allocated2, uint32 since2) = doCalcRewardAt(address(this), at);
    allocated2 += _delayed[address(this)];

    return (allocated + allocated2, since2 > since ? since2 : since);
  }

  function calcRewardFor(address holder, uint32 at)
    external
    view
    override
    returns (
      uint256 amount,
      uint256 delayedAmount,
      uint32 since
    )
  {
    (amount, since) = internalCalcReward(holder, at);
    if (!isUnlocked(at)) {
      (amount, delayedAmount) = (0, amount);
    }
    return (amount, delayedAmount, since);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../Errors.sol';

/// @dev Percentages are defined in basis points. The precision is indicated by ONE. Operations are rounded half up.
library PercentageMath {
  uint16 public constant BP = 1; // basis point
  uint16 public constant PCT = 100 * BP; // basis points per percentage point
  uint16 public constant ONE = 100 * PCT; // basis points per 1 (100%)
  uint16 public constant HALF_ONE = ONE / 2;
  // deprecated
  uint256 public constant PERCENTAGE_FACTOR = ONE; //percentage plus two decimals

  /**
   * @dev Executes a percentage multiplication
   * @param value The value of which the percentage needs to be calculated
   * @param factor Basis points of the value to be calculated
   * @return The percentage of value
   **/
  function percentMul(uint256 value, uint256 factor) internal pure returns (uint256) {
    if (value == 0 || factor == 0) {
      return 0;
    }

    require(value <= (type(uint256).max - HALF_ONE) / factor, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (value * factor + HALF_ONE) / ONE;
  }

  /**
   * @dev Executes a percentage division
   * @param value The value of which the percentage needs to be calculated
   * @param factor Basis points of the value to be calculated
   * @return The value divided the percentage
   **/
  function percentDiv(uint256 value, uint256 factor) internal pure returns (uint256) {
    require(factor != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfFactor = factor >> 1;

    require(value <= (type(uint256).max - halfFactor) / ONE, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (value * ONE + halfFactor) / factor;
  }

  function percentOf(uint256 value, uint256 base) internal pure returns (uint256) {
    require(base != 0, Errors.MATH_DIVISION_BY_ZERO);
    if (value == 0) {
      return 0;
    }

    require(value <= (type(uint256).max - HALF_ONE) / ONE, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (value * ONE + (base >> 1)) / base;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @title Errors library
 * @notice Defines the error messages emitted by the different contracts
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - MATH = Math libraries
 *  - CT = Common errors between tokens (DepositToken, VariableDebtToken and StableDebtToken)
 *  - AT = DepositToken
 *  - SDT = StableDebtToken
 *  - VDT = VariableDebtToken
 *  - LP = LendingPool
 *  - LPAPR = AddressesProviderRegistry
 *  - LPC = LendingPoolConfiguration
 *  - RL = ReserveLogic
 *  - LPCM = LendingPoolExtension
 *  - ST = Stake
 */
library Errors {
  //contract specific errors
  string public constant VL_INVALID_AMOUNT = '1'; // Amount must be greater than 0
  string public constant VL_NO_ACTIVE_RESERVE = '2'; // Action requires an active reserve
  string public constant VL_RESERVE_FROZEN = '3'; // Action cannot be performed because the reserve is frozen
  string public constant VL_UNKNOWN_RESERVE = '4'; // Action requires an active reserve
  string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = '5'; // User cannot withdraw more than the available balance (above min limit)
  string public constant VL_TRANSFER_NOT_ALLOWED = '6'; // Transfer cannot be allowed.
  string public constant VL_BORROWING_NOT_ENABLED = '7'; // Borrowing is not enabled
  string public constant VL_INVALID_INTEREST_RATE_MODE_SELECTED = '8'; // Invalid interest rate mode selected
  string public constant VL_COLLATERAL_BALANCE_IS_0 = '9'; // The collateral balance is 0
  string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = '10'; // Health factor is lesser than the liquidation threshold
  string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = '11'; // There is not enough collateral to cover a new borrow
  string public constant VL_STABLE_BORROWING_NOT_ENABLED = '12'; // stable borrowing not enabled
  string public constant VL_COLLATERAL_SAME_AS_BORROWING_CURRENCY = '13'; // collateral is (mostly) the same currency that is being borrowed
  string public constant VL_AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = '14'; // The requested amount is exceeds max size of a stable loan
  string public constant VL_NO_DEBT_OF_SELECTED_TYPE = '15'; // to repay a debt, user needs to specify a correct debt type (variable or stable)
  string public constant VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = '16'; // To repay on behalf of an user an explicit amount to repay is needed
  string public constant VL_NO_STABLE_RATE_LOAN_IN_RESERVE = '17'; // User does not have a stable rate loan in progress on this reserve
  string public constant VL_NO_VARIABLE_RATE_LOAN_IN_RESERVE = '18'; // User does not have a variable rate loan in progress on this reserve
  string public constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = '19'; // The collateral balance needs to be greater than 0
  string public constant VL_DEPOSIT_ALREADY_IN_USE = '20'; // User deposit is already being used as collateral
  string public constant VL_RESERVE_MUST_BE_COLLATERAL = '21'; // This reserve must be enabled as collateral
  string public constant LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '22'; // Interest rate rebalance conditions were not met
  string public constant AT_OVERDRAFT_DISABLED = '23'; // User doesn't accept allocation of overdraft
  string public constant VL_INVALID_SUB_BALANCE_ARGS = '24';
  string public constant AT_INVALID_SLASH_DESTINATION = '25';

  string public constant LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR = '27'; // The caller of the function is not the lending pool configurator

  string public constant LENDING_POOL_REQUIRED = '28'; // The caller of this function must be a lending pool
  string public constant CALLER_NOT_LENDING_POOL = '29'; // The caller of this function must be a lending pool
  string public constant AT_SUB_BALANCE_RESTIRCTED_FUNCTION = '30'; // The caller of this function must be a lending pool or a sub-balance operator

  string public constant RL_RESERVE_ALREADY_INITIALIZED = '32'; // Reserve has already been initialized
  string public constant CALLER_NOT_POOL_ADMIN = '33'; // The caller must be the pool admin
  string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = '34'; // The liquidity of the reserve needs to be 0

  string public constant LPAPR_PROVIDER_NOT_REGISTERED = '41'; // Provider is not registered
  string public constant LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '42'; // Health factor is not below the threshold
  string public constant LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED = '43'; // The collateral chosen cannot be liquidated
  string public constant LPCM_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = '44'; // User did not borrow the specified currency
  string public constant LPCM_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE = '45'; // There isn't enough liquidity available to liquidate

  string public constant MATH_MULTIPLICATION_OVERFLOW = '48';
  string public constant MATH_ADDITION_OVERFLOW = '49';
  string public constant MATH_DIVISION_BY_ZERO = '50';
  string public constant RL_LIQUIDITY_INDEX_OVERFLOW = '51'; //  Liquidity index overflows uint128
  string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = '52'; //  Variable borrow index overflows uint128
  string public constant RL_LIQUIDITY_RATE_OVERFLOW = '53'; //  Liquidity rate overflows uint128
  string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = '54'; //  Variable borrow rate overflows uint128
  string public constant RL_STABLE_BORROW_RATE_OVERFLOW = '55'; //  Stable borrow rate overflows uint128
  string public constant CT_INVALID_MINT_AMOUNT = '56'; //invalid amount to mint
  string public constant CALLER_NOT_STAKE_ADMIN = '57';
  string public constant CT_INVALID_BURN_AMOUNT = '58'; //invalid amount to burn
  string public constant BORROW_ALLOWANCE_NOT_ENOUGH = '59'; // User borrows on behalf, but allowance are too small
  string public constant CALLER_NOT_LIQUIDITY_CONTROLLER = '60';
  string public constant CALLER_NOT_REF_ADMIN = '61';
  string public constant VL_INSUFFICIENT_REWARD_AVAILABLE = '62';
  string public constant LP_CALLER_MUST_BE_DEPOSIT_TOKEN = '63';
  string public constant LP_IS_PAUSED = '64'; // Pool is paused
  string public constant LP_NO_MORE_RESERVES_ALLOWED = '65';
  string public constant LP_INVALID_FLASH_LOAN_EXECUTOR_RETURN = '66';
  string public constant RC_INVALID_LTV = '67';
  string public constant RC_INVALID_LIQ_THRESHOLD = '68';
  string public constant RC_INVALID_LIQ_BONUS = '69';
  string public constant RC_INVALID_DECIMALS = '70';
  string public constant RC_INVALID_RESERVE_FACTOR = '71';
  string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = '72';
  string public constant VL_INCONSISTENT_FLASHLOAN_PARAMS = '73';
  string public constant VL_TREASURY_REQUIRED = '74';
  string public constant LPC_INVALID_CONFIGURATION = '75'; // Invalid risk parameters for the reserve
  string public constant CALLER_NOT_EMERGENCY_ADMIN = '76'; // The caller must be the emergency admin
  string public constant UL_INVALID_INDEX = '77';
  string public constant VL_CONTRACT_REQUIRED = '78';
  string public constant SDT_STABLE_DEBT_OVERFLOW = '79';
  string public constant SDT_BURN_EXCEEDS_BALANCE = '80';
  string public constant CALLER_NOT_REWARD_CONFIG_ADMIN = '81'; // The caller of this function must be a reward admin
  string public constant LP_INVALID_PERCENTAGE = '82'; // Percentage can't be more than 100%
  string public constant LP_IS_NOT_TRUSTED_FLASHLOAN = '83';
  string public constant CALLER_NOT_SWEEP_ADMIN = '84';
  string public constant LP_TOO_MANY_NESTED_CALLS = '85';
  string public constant LP_RESTRICTED_FEATURE = '86';
  string public constant LP_TOO_MANY_FLASHLOAN_CALLS = '87';
  string public constant RW_BASELINE_EXCEEDED = '88';
  string public constant CALLER_NOT_REWARD_RATE_ADMIN = '89';
  string public constant CALLER_NOT_REWARD_CONTROLLER = '90';
  string public constant RW_REWARD_PAUSED = '91';
  string public constant CALLER_NOT_TEAM_MANAGER = '92';
  string public constant STK_REDEEM_PAUSED = '93';
  string public constant STK_INSUFFICIENT_COOLDOWN = '94';
  string public constant STK_UNSTAKE_WINDOW_FINISHED = '95';
  string public constant STK_INVALID_BALANCE_ON_COOLDOWN = '96';
  string public constant STK_EXCESSIVE_SLASH_PCT = '97';
  string public constant STK_WRONG_COOLDOWN_OR_UNSTAKE = '98';
  string public constant STK_PAUSED = '99';

  string public constant TXT_OWNABLE_CALLER_NOT_OWNER = 'Ownable: caller is not the owner';
  string public constant TXT_CALLER_NOT_PROXY_OWNER = 'ProxyOwner: caller is not the owner';
  string public constant TXT_ACCESS_RESTRICTED = 'RESTRICTED';
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../access/interfaces/IMarketAccessController.sol';

enum AllocationMode {
  Push,
  SetPull,
  SetPullSpecial
}

interface IRewardController {
  function allocatedByPool(
    address holder,
    uint256 allocated,
    uint32 since,
    AllocationMode mode
  ) external;

  function isRateAdmin(address) external view returns (bool);

  function isConfigAdmin(address) external view returns (bool);

  function getAccessController() external view returns (IMarketAccessController);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './CalcLinearRewardBalances.sol';

abstract contract CalcLinearUnweightedReward is CalcLinearRewardBalances {
  uint256 private _accumRate;

  function internalRateUpdated(
    uint256 lastRate,
    uint32 lastAt,
    uint32 at
  ) internal override {
    _accumRate += lastRate * (at - lastAt);
  }

  function internalCalcRateAndReward(
    RewardBalance memory entry,
    uint256 lastAccumRate,
    uint32 at
  )
    internal
    view
    virtual
    override
    returns (
      uint256 adjRate,
      uint256 allocated,
      uint32 since
    )
  {
    (uint256 rate, uint32 updatedAt) = getRateAndUpdatedAt();

    adjRate = _accumRate + (rate * (at - updatedAt));
    allocated = uint256(entry.rewardBase) * (adjRate - lastAccumRate);

    return (adjRate, allocated, entry.claimedAt);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../tools/math/PercentageMath.sol';
import '../interfaces/IRewardController.sol';
import '../interfaces/IManagedRewardPool.sol';
import '../../access/AccessFlags.sol';
import '../../access/AccessHelper.sol';
import '../../tools/Errors.sol';

abstract contract ControlledRewardPool is IManagedRewardPool {
  using PercentageMath for uint256;

  IRewardController private _controller;

  uint16 private _baselinePercentage;
  bool private _paused;

  constructor(
    IRewardController controller,
    uint256 initialRate,
    uint16 baselinePercentage
  ) {
    _initialize(controller, initialRate, baselinePercentage, '');
  }

  function _initialize(
    IRewardController controller,
    uint256 initialRate,
    uint16 baselinePercentage,
    string memory poolName
  ) internal virtual {
    poolName;
    _controller = controller;

    if (baselinePercentage > 0) {
      _setBaselinePercentage(baselinePercentage);
    }

    if (initialRate > 0) {
      _setRate(initialRate);
    }
  }

  function getPoolName() public view virtual override returns (string memory) {
    return '';
  }

  function updateBaseline(uint256 baseline)
    external
    virtual
    override
    onlyController
    returns (bool hasBaseline, uint256 appliedRate)
  {
    if (_baselinePercentage == 0) {
      return (false, internalGetRate());
    }
    appliedRate = baseline.percentMul(_baselinePercentage);
    _setRate(appliedRate);
    return (true, appliedRate);
  }

  function setBaselinePercentage(uint16 factor) external override onlyController {
    _setBaselinePercentage(factor);
  }

  function getBaselinePercentage() public view override returns (uint16) {
    return _baselinePercentage;
  }

  function _mustHaveController() private view {
    require(address(_controller) != address(0), 'controller is required');
  }

  function _setBaselinePercentage(uint16 factor) internal virtual {
    _mustHaveController();
    require(factor <= PercentageMath.ONE, 'illegal value');
    _baselinePercentage = factor;
    emit BaselinePercentageUpdated(factor);
  }

  function _setRate(uint256 rate) internal {
    _mustHaveController();
    internalSetRate(rate);
    emit RateUpdated(rate);
  }

  function getRate() external view override returns (uint256) {
    return internalGetRate();
  }

  function internalGetRate() internal view virtual returns (uint256);

  function internalSetRate(uint256 rate) internal virtual;

  function setPaused(bool paused) public override onlyEmergencyAdmin {
    if (_paused != paused) {
      _paused = paused;
      internalPause(paused);
    }
    emit EmergencyPaused(msg.sender, paused);
  }

  function isPaused() public view override returns (bool) {
    return _paused;
  }

  function internalPause(bool paused) internal virtual {}

  function getRewardController() public view override returns (address) {
    return address(_controller);
  }

  function claimRewardFor(address holder)
    external
    override
    onlyController
    returns (
      uint256,
      uint32,
      bool
    )
  {
    return internalGetReward(holder);
  }

  function claimRewardWithLimitFor(
    address holder,
    uint256 baseAmount,
    uint256 limit,
    uint16 minPct
  )
    external
    override
    onlyController
    returns (
      uint256 amount,
      uint32 since,
      bool keepPull,
      uint256 newLimit
    )
  {
    return internalGetRewardWithLimit(holder, baseAmount, limit, minPct);
  }

  function calcRewardFor(address holder, uint32 at)
    external
    view
    virtual
    override
    returns (
      uint256 amount,
      uint256,
      uint32 since
    )
  {
    require(at >= uint32(block.timestamp));
    (amount, since) = internalCalcReward(holder, at);
    return (amount, 0, since);
  }

  function internalAllocateReward(
    address holder,
    uint256 allocated,
    uint32 since,
    AllocationMode mode
  ) internal {
    _controller.allocatedByPool(holder, allocated, since, mode);
  }

  function internalGetRewardWithLimit(
    address holder,
    uint256 baseAmount,
    uint256 limit,
    uint16 minBoostPct
  )
    internal
    virtual
    returns (
      uint256 amount,
      uint32 since,
      bool keepPull,
      uint256
    )
  {
    (amount, since, keepPull) = internalGetReward(holder);
    amount += baseAmount;
    if (minBoostPct > 0) {
      limit += PercentageMath.percentMul(amount, minBoostPct);
    }
    return (amount, since, keepPull, limit);
  }

  function internalGetReward(address holder)
    internal
    virtual
    returns (
      uint256,
      uint32,
      bool
    );

  function internalCalcReward(address holder, uint32 at) internal view virtual returns (uint256, uint32);

  function attachedToRewardController() external override onlyController returns (uint256) {
    internalAttachedToRewardController();
    return internalGetPreAllocatedLimit();
  }

  function detachedFromRewardController() external override onlyController returns (uint256) {
    return internalGetPreAllocatedLimit();
  }

  function internalGetPreAllocatedLimit() internal virtual returns (uint256) {
    return 0;
  }

  function internalAttachedToRewardController() internal virtual {}

  function _isController(address addr) internal view virtual returns (bool) {
    return address(_controller) == addr;
  }

  function getAccessController() internal view virtual returns (IMarketAccessController) {
    return _controller.getAccessController();
  }

  function _onlyController() private view {
    require(_isController(msg.sender), Errors.CALLER_NOT_REWARD_CONTROLLER);
  }

  modifier onlyController() {
    _onlyController();
    _;
  }

  function _isConfigAdmin(address addr) internal view returns (bool) {
    return address(_controller) != address(0) && _controller.isConfigAdmin(addr);
  }

  function _onlyConfigAdmin() private view {
    require(_isConfigAdmin(msg.sender), Errors.CALLER_NOT_REWARD_CONFIG_ADMIN);
  }

  modifier onlyConfigAdmin() {
    _onlyConfigAdmin();
    _;
  }

  function _isRateAdmin(address addr) internal view returns (bool) {
    return address(_controller) != address(0) && _controller.isRateAdmin(addr);
  }

  function _onlyRateAdmin() private view {
    require(_isRateAdmin(msg.sender), Errors.CALLER_NOT_REWARD_RATE_ADMIN);
  }

  modifier onlyRateAdmin() {
    _onlyRateAdmin();
    _;
  }

  function _onlyEmergencyAdmin() private view {
    AccessHelper.requireAnyOf(
      getAccessController(),
      msg.sender,
      AccessFlags.EMERGENCY_ADMIN,
      Errors.CALLER_NOT_EMERGENCY_ADMIN
    );
  }

  modifier onlyEmergencyAdmin() {
    _onlyEmergencyAdmin();
    _;
  }

  function _notPaused() private view {
    require(!_paused, Errors.RW_REWARD_PAUSED);
  }

  modifier notPaused() {
    _notPaused();
    _;
  }

  modifier notPausedCustom(string memory err) {
    require(!_paused, err);
    _;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IAccessController.sol';

/// @dev Main registry of addresses part of or connected to the protocol, including permissioned roles. Also acts a proxy factory.
interface IMarketAccessController is IAccessController {
  function getMarketId() external view returns (string memory);

  function getLendingPool() external view returns (address);

  function getPriceOracle() external view returns (address);

  function getLendingRateOracle() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IRemoteAccessBitmask.sol';
import '../../tools/upgradeability/IProxy.sol';

/// @dev Main registry of permissions and addresses
interface IAccessController is IRemoteAccessBitmask {
  function getAddress(uint256 id) external view returns (address);

  function createProxy(
    address admin,
    address impl,
    bytes calldata params
  ) external returns (IProxy);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IRemoteAccessBitmask {
  /**
   * @dev Returns access flags granted to the given address and limited by the filterMask. filterMask == 0 has a special meaning.
   * @param addr an to get access perfmissions for
   * @param filterMask limits a subset of flags to be checked.
   * NB! When filterMask == 0 then zero is returned no flags granted, or an unspecified non-zero value otherwise.
   * @return Access flags currently granted
   */
  function queryAccessControlMask(address addr, uint256 filterMask) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IProxy {
  function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../interfaces/IRewardController.sol';

abstract contract CalcLinearRewardBalances {
  struct RewardBalance {
    uint192 rewardBase;
    uint32 custom;
    uint32 claimedAt;
  }
  mapping(address => RewardBalance) private _balances;
  mapping(address => uint256) private _accumRates;

  uint224 private _rate;
  uint32 private _rateUpdatedAt;

  function setLinearRate(uint256 rate) internal {
    setLinearRateAt(rate, getCurrentTick());
  }

  function setLinearRateAt(uint256 rate, uint32 at) internal {
    if (_rate == rate) {
      return;
    }
    require(rate <= type(uint224).max);

    uint32 prevTick = _rateUpdatedAt;
    if (at != prevTick) {
      uint224 prevRate = _rate;
      internalMarkRateUpdate(at);
      _rate = uint224(rate);
      internalRateUpdated(prevRate, prevTick, at);
    }
  }

  function doSyncRateAt(uint32 at) internal {
    uint32 prevTick = _rateUpdatedAt;
    if (at != prevTick) {
      internalMarkRateUpdate(at);
      internalRateUpdated(_rate, prevTick, at);
    }
  }

  function getCurrentTick() internal view virtual returns (uint32);

  function internalRateUpdated(
    uint256 lastRate,
    uint32 lastAt,
    uint32 at
  ) internal virtual;

  function internalMarkRateUpdate(uint32 currentTick) internal {
    require(currentTick >= _rateUpdatedAt, 'retroactive update');
    _rateUpdatedAt = currentTick;
  }

  function getLinearRate() internal view returns (uint256) {
    return _rate;
  }

  function getRateAndUpdatedAt() internal view returns (uint256, uint32) {
    return (_rate, _rateUpdatedAt);
  }

  function internalCalcRateAndReward(
    RewardBalance memory entry,
    uint256 lastAccumRate,
    uint32 currentTick
  )
    internal
    view
    virtual
    returns (
      uint256 rate,
      uint256 allocated,
      uint32 since
    );

  function getRewardEntry(address holder) internal view returns (RewardBalance memory) {
    return _balances[holder];
  }

  function internalSetRewardEntryCustom(address holder, uint32 custom) internal {
    _balances[holder].custom = custom;
  }

  function doIncrementRewardBalance(address holder, uint256 amount)
    internal
    returns (
      uint256,
      uint32,
      AllocationMode
    )
  {
    RewardBalance memory entry = _balances[holder];
    amount += entry.rewardBase;
    require(amount <= type(uint192).max, 'balance is too high');
    return _doUpdateRewardBalance(holder, entry, uint192(amount));
  }

  function doDecrementRewardBalance(
    address holder,
    uint256 amount,
    uint256 minBalance
  )
    internal
    returns (
      uint256,
      uint32,
      AllocationMode
    )
  {
    RewardBalance memory entry = _balances[holder];
    require(entry.rewardBase >= minBalance + amount, 'amount exceeds balance');
    unchecked {
      amount = entry.rewardBase - amount;
    }
    return _doUpdateRewardBalance(holder, entry, uint192(amount));
  }

  function doUpdateRewardBalance(address holder, uint256 newBalance)
    internal
    returns (
      uint256 allocated,
      uint32 since,
      AllocationMode mode
    )
  {
    require(newBalance <= type(uint192).max, 'balance is too high');
    return _doUpdateRewardBalance(holder, _balances[holder], uint192(newBalance));
  }

  function _doUpdateRewardBalance(
    address holder,
    RewardBalance memory entry,
    uint192 newBalance
  )
    private
    returns (
      uint256,
      uint32,
      AllocationMode mode
    )
  {
    if (entry.claimedAt == 0) {
      mode = AllocationMode.SetPull;
    } else {
      mode = AllocationMode.Push;
    }

    uint32 currentTick = getCurrentTick();
    (uint256 adjRate, uint256 allocated, uint32 since) = internalCalcRateAndReward(
      entry,
      _accumRates[holder],
      currentTick
    );

    _accumRates[holder] = adjRate;
    _balances[holder] = RewardBalance(newBalance, entry.custom, currentTick);
    return (allocated, since, mode);
  }

  function doRemoveRewardBalance(address holder) internal returns (uint256 rewardBase) {
    rewardBase = _balances[holder].rewardBase;
    if (rewardBase == 0 && _balances[holder].claimedAt == 0) {
      return 0;
    }
    delete (_balances[holder]);
    return rewardBase;
  }

  function doGetReward(address holder)
    internal
    returns (
      uint256,
      uint32,
      bool
    )
  {
    return doGetRewardAt(holder, getCurrentTick());
  }

  function doGetRewardAt(address holder, uint32 currentTick)
    internal
    returns (
      uint256,
      uint32,
      bool
    )
  {
    RewardBalance memory balance = _balances[holder];
    if (balance.rewardBase == 0) {
      return (0, 0, false);
    }

    (uint256 adjRate, uint256 allocated, uint32 since) = internalCalcRateAndReward(
      balance,
      _accumRates[holder],
      currentTick
    );

    _accumRates[holder] = adjRate;
    _balances[holder].claimedAt = currentTick;
    return (allocated, since, true);
  }

  function doCalcReward(address holder) internal view returns (uint256, uint32) {
    return doCalcRewardAt(holder, getCurrentTick());
  }

  function doCalcRewardAt(address holder, uint32 currentTick) internal view returns (uint256, uint32) {
    if (_balances[holder].rewardBase == 0) {
      return (0, 0);
    }

    (, uint256 allocated, uint32 since) = internalCalcRateAndReward(
      _balances[holder],
      _accumRates[holder],
      currentTick
    );
    return (allocated, since);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../interfaces/IEmergencyAccess.sol';

interface IManagedRewardPool is IEmergencyAccess {
  function updateBaseline(uint256) external returns (bool hasBaseline, uint256 appliedRate);

  function setBaselinePercentage(uint16) external;

  function getBaselinePercentage() external view returns (uint16);

  function getRate() external view returns (uint256);

  function getPoolName() external view returns (string memory);

  function claimRewardFor(address holder)
    external
    returns (
      uint256 amount,
      uint32 since,
      bool keepPull
    );

  function claimRewardWithLimitFor(
    address holder,
    uint256 baseAmount,
    uint256 limit,
    uint16 minPct
  )
    external
    returns (
      uint256 amount,
      uint32 since,
      bool keepPull,
      uint256 newLimit
    );

  function calcRewardFor(address holder, uint32 at)
    external
    view
    returns (
      uint256 amount,
      uint256 extra,
      uint32 since
    );

  function addRewardProvider(address provider, address token) external;

  function removeRewardProvider(address provider) external;

  function getRewardController() external view returns (address);

  function attachedToRewardController() external returns (uint256 allocateReward);

  function detachedFromRewardController() external returns (uint256 deallocateReward);

  event RateUpdated(uint256 rate);
  event BaselinePercentageUpdated(uint16);
  event ProviderAdded(address provider, address token);
  event ProviderRemoved(address provider);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

library AccessFlags {
  // roles that can be assigned to multiple addresses - use range [0..15]
  uint256 public constant EMERGENCY_ADMIN = 1 << 0;
  uint256 public constant POOL_ADMIN = 1 << 1;
  uint256 public constant TREASURY_ADMIN = 1 << 2;
  uint256 public constant REWARD_CONFIG_ADMIN = 1 << 3;
  uint256 public constant REWARD_RATE_ADMIN = 1 << 4;
  uint256 public constant STAKE_ADMIN = 1 << 5;
  uint256 public constant REFERRAL_ADMIN = 1 << 6;
  uint256 public constant LENDING_RATE_ADMIN = 1 << 7;
  uint256 public constant SWEEP_ADMIN = 1 << 8;
  uint256 public constant ORACLE_ADMIN = 1 << 9;

  uint256 public constant ROLES = (uint256(1) << 16) - 1;

  // singletons - use range [16..64] - can ONLY be assigned to a single address
  uint256 public constant SINGLETONS = ((uint256(1) << 64) - 1) & ~ROLES;

  // proxied singletons
  uint256 public constant LENDING_POOL = 1 << 16;
  uint256 public constant LENDING_POOL_CONFIGURATOR = 1 << 17;
  uint256 public constant LIQUIDITY_CONTROLLER = 1 << 18;
  uint256 public constant TREASURY = 1 << 19;
  uint256 public constant REWARD_TOKEN = 1 << 20;
  uint256 public constant REWARD_STAKE_TOKEN = 1 << 21;
  uint256 public constant REWARD_CONTROLLER = 1 << 22;
  uint256 public constant REWARD_CONFIGURATOR = 1 << 23;
  uint256 public constant STAKE_CONFIGURATOR = 1 << 24;
  uint256 public constant REFERRAL_REGISTRY = 1 << 25;

  uint256 public constant PROXIES = ((uint256(1) << 26) - 1) & ~ROLES;

  // non-proxied singletons, numbered down from 31 (as JS has problems with bitmasks over 31 bits)
  uint256 public constant WETH_GATEWAY = 1 << 27;
  uint256 public constant DATA_HELPER = 1 << 28;
  uint256 public constant PRICE_ORACLE = 1 << 29;
  uint256 public constant LENDING_RATE_ORACLE = 1 << 30;

  // any other roles - use range [64..]
  // these roles can be assigned to multiple addresses

  uint256 public constant TRUSTED_FLASHLOAN = 1 << 66;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './interfaces/IRemoteAccessBitmask.sol';

/// @dev Helper/wrapper around IRemoteAccessBitmask
library AccessHelper {
  function getAcl(IRemoteAccessBitmask remote, address subject) internal view returns (uint256) {
    return remote.queryAccessControlMask(subject, ~uint256(0));
  }

  function queryAcl(
    IRemoteAccessBitmask remote,
    address subject,
    uint256 filterMask
  ) internal view returns (uint256) {
    return remote.queryAccessControlMask(subject, filterMask);
  }

  function hasAnyOf(
    IRemoteAccessBitmask remote,
    address subject,
    uint256 flags
  ) internal view returns (bool) {
    uint256 found = queryAcl(remote, subject, flags);
    return found & flags != 0;
  }

  function hasAny(IRemoteAccessBitmask remote, address subject) internal view returns (bool) {
    return remote.queryAccessControlMask(subject, 0) != 0;
  }

  function hasNone(IRemoteAccessBitmask remote, address subject) internal view returns (bool) {
    return remote.queryAccessControlMask(subject, 0) == 0;
  }

  function requireAnyOf(
    IRemoteAccessBitmask remote,
    address subject,
    uint256 flags,
    string memory text
  ) internal view {
    require(hasAnyOf(remote, subject, flags), text);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IEmergencyAccess {
  function setPaused(bool paused) external;

  function isPaused() external view returns (bool);

  event EmergencyPaused(address indexed by, bool paused);
}

