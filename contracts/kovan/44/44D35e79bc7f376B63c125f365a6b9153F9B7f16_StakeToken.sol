// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './RewardedStakeBase.sol';
import './interfaces/StakeTokenConfig.sol';
import '../../tools/upgradeability/VersionedInitializable.sol';

contract StakeToken is RewardedStakeBase, VersionedInitializable {
  uint256 private constant TOKEN_REVISION = 2;

  constructor()
    ERC20DetailsBase('', '', 0)
    MarketAccessBitmaskMin(IMarketAccessController(address(0)))
    SlashableBase(0)
    ControlledRewardPool(IRewardController(address(0)), 0, 0)
  {}

  function initializeStakeToken(
    StakeTokenConfig calldata params,
    string calldata name,
    string calldata symbol
  ) external virtual override initializerRunAlways(TOKEN_REVISION) {
    if (isRevisionInitialized(TOKEN_REVISION)) {
      super._initializeERC20(name, symbol, decimals());
    } else {
      super._initializeERC20(name, symbol, params.stakedTokenDecimals);
      super._initializeToken(params);
      super._initializeDomainSeparator();
    }
    emit Initialized(params, name, symbol);
  }

  function getRevision() internal pure virtual override returns (uint256) {
    return TOKEN_REVISION;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../dependencies/openzeppelin/contracts/SafeERC20.sol';
import '../../reward/interfaces/IInitializableRewardPool.sol';
import '../../reward/calcs/CalcLinearWeightedReward.sol';
import '../../reward/pools/ControlledRewardPool.sol';
import '../../tools/tokens/ERC20DetailsBase.sol';
import '../../tools/tokens/ERC20AllowanceBase.sol';
import '../../tools/tokens/ERC20TransferBase.sol';
import '../../tools/tokens/ERC20PermitBase.sol';
import '../../tools/math/WadRayMath.sol';
import '../../tools/math/PercentageMath.sol';
import '../../tools/Errors.sol';
import '../libraries/helpers/UnderlyingHelper.sol';
import './interfaces/StakeTokenConfig.sol';
import './interfaces/IInitializableStakeToken.sol';
import './CooldownBase.sol';
import './SlashableBase.sol';

abstract contract RewardedStakeBase is
  SlashableBase,
  CooldownBase,
  CalcLinearWeightedReward,
  ControlledRewardPool,
  IInitializableStakeToken,
  ERC20DetailsBase,
  ERC20AllowanceBase,
  ERC20TransferBase,
  ERC20PermitBase,
  IInitializableRewardPool
{
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeERC20 for IERC20;

  bool private _notRedeemable;
  IERC20 private _stakedToken;
  IUnderlyingStrategy private _strategy;

  function _approveTransferFrom(address owner, uint256 amount)
    internal
    override(ERC20AllowanceBase, ERC20TransferBase)
  {
    ERC20AllowanceBase._approveTransferFrom(owner, amount);
  }

  function _approveByPermit(
    address owner,
    address spender,
    uint256 amount
  ) internal override {
    _approve(owner, spender, amount);
  }

  function _getPermitDomainName() internal view override returns (bytes memory) {
    return bytes(super.name());
  }

  function getAccessController() internal view override returns (IMarketAccessController) {
    return _remoteAcl;
  }

  function _notSupported() private pure {
    revert('UNSUPPORTED');
  }

  function addRewardProvider(address, address) external view override onlyConfigAdmin {
    _notSupported();
  }

  function removeRewardProvider(address provider) external override onlyConfigAdmin {}

  function internalGetRate() internal view override returns (uint256) {
    return super.getLinearRate();
  }

  function internalSetRate(uint256 rate) internal override {
    super.setLinearRate(rate);
  }

  function internalTotalSupply() internal view override returns (uint256) {
    return super.internalGetTotalSupply();
  }

  function getIncentivesController() public view override returns (address) {
    return address(this);
  }

  function setIncentivesController(address) external view override onlyRewardConfiguratorOrAdmin {
    _notSupported();
  }

  function getCurrentTick() internal view override returns (uint32) {
    return uint32(block.timestamp);
  }

  function internalGetReward(address holder)
    internal
    override
    returns (
      uint256,
      uint32,
      bool
    )
  {
    return doGetReward(holder);
  }

  function internalCalcReward(address holder, uint32 at) internal view override returns (uint256, uint32) {
    return doCalcRewardAt(holder, at);
  }

  function getPoolName() public view virtual override returns (string memory) {
    return super.symbol();
  }

  function initializeRewardPool(InitRewardPoolData calldata config) external override onlyRewardConfiguratorOrAdmin {
    require(address(config.controller) != address(0));
    require(address(getRewardController()) == address(0));
    _initialize(IRewardController(config.controller), 0, config.baselinePercentage, config.poolName);
  }

  function initializedRewardPoolWith() external view override returns (InitRewardPoolData memory) {
    return InitRewardPoolData(IRewardController(getRewardController()), getPoolName(), getBaselinePercentage());
  }

  function _initializeToken(StakeTokenConfig memory params) internal virtual {
    _remoteAcl = params.stakeController;
    _stakedToken = params.stakedToken;
    _strategy = params.strategy;
    _initializeSlashable(params.maxSlashable);

    if (params.unstakePeriod == 0) {
      params.unstakePeriod = MIN_UNSTAKE_PERIOD;
    }
    internalSetCooldown(params.cooldownPeriod, params.unstakePeriod);
  }

  // solhint-disable-next-line func-name-mixedcase
  function UNDERLYING_ASSET_ADDRESS() external view override returns (address) {
    return address(_stakedToken);
  }

  function stake(
    address to,
    uint256 underlyingAmount,
    uint256 referral
  ) external override returns (uint256) {
    return internalStake(msg.sender, to, underlyingAmount, referral);
  }

  function internalStake(
    address from,
    address to,
    uint256 underlyingAmount,
    uint256 referral
  ) internal notPausedCustom(Errors.STK_PAUSED) returns (uint256 stakeAmount) {
    require(underlyingAmount > 0, Errors.VL_INVALID_AMOUNT);

    (uint256 exchangeRate, uint256 index) = internalExchangeRate();
    stakeAmount = underlyingAmount.rayDiv(exchangeRate);
    (uint256 toBalance, uint32 toCooldown) = internalBalanceAndCooldownOf(to);

    toCooldown = getNextCooldown(0, stakeAmount, toBalance, toCooldown);

    internalTransferUnderlyingFrom(from, underlyingAmount, index);

    {
      (uint256 rewardAmount, uint32 since, AllocationMode mode) = super.doIncrementRewardBalance(to, stakeAmount);
      super.doIncrementTotalSupply(stakeAmount);
      super.internalSetRewardEntryCustom(to, toCooldown);

      _applyAllocatedReward(to, rewardAmount, since, mode);
    }

    emit Staked(from, to, underlyingAmount, referral);
    emit Transfer(address(0), to, stakeAmount);
    return stakeAmount;
  }

  function _applyAllocatedReward(
    address holder,
    uint256 amount,
    uint32 since,
    AllocationMode mode
  ) private {
    if ((amount > 0 || mode != AllocationMode.Push) && getRewardController() != address(0)) {
      super.internalAllocateReward(holder, amount, since, mode);
    }
  }

  function internalBalanceAndCooldownOf(address holder) internal view returns (uint256, uint32) {
    RewardBalance memory balance = super.getRewardEntry(holder);
    return (balance.rewardBase, balance.custom);
  }

  function redeem(address to, uint256 stakeAmount) external override returns (uint256 stakeAmount_) {
    require(stakeAmount > 0, Errors.VL_INVALID_AMOUNT);
    (stakeAmount_, ) = internalRedeem(msg.sender, to, stakeAmount, 0);
    return stakeAmount_;
  }

  function redeemUnderlying(address to, uint256 underlyingAmount)
    external
    override
    returns (uint256 underlyingAmount_)
  {
    require(underlyingAmount > 0, Errors.VL_INVALID_AMOUNT);
    if (underlyingAmount == type(uint256).max) {
      (, underlyingAmount_) = internalRedeem(msg.sender, to, type(uint256).max, 0);
    } else {
      (, underlyingAmount_) = internalRedeem(msg.sender, to, 0, underlyingAmount);
    }
    return underlyingAmount_;
  }

  function internalRedeem(
    address from,
    address receiver,
    uint256 stakeAmount,
    uint256 underlyingAmount
  ) internal notPausedCustom(Errors.STK_PAUSED) returns (uint256, uint256) {
    require(!_notRedeemable, Errors.STK_REDEEM_PAUSED);
    _ensureCooldown(from);

    (uint256 exchangeRate, uint256 index) = internalExchangeRate();

    (uint256 oldBalance, uint32 cooldownFrom) = internalBalanceAndCooldownOf(from);
    if (stakeAmount == 0) {
      stakeAmount = underlyingAmount.rayDiv(exchangeRate);
    } else {
      if (stakeAmount == type(uint256).max) {
        stakeAmount = oldBalance;
      }
      underlyingAmount = stakeAmount.rayMul(exchangeRate);
      if (underlyingAmount == 0) {
        // protect the user - don't waste balance without an outcome
        return (0, 0);
      }
    }

    {
      (uint256 rewardAmount, uint32 since, AllocationMode mode) = super.doDecrementRewardBalance(from, stakeAmount, 0);
      super.doDecrementTotalSupply(stakeAmount);

      if (oldBalance == stakeAmount && cooldownFrom != 0) {
        super.internalSetRewardEntryCustom(from, 0);
      }

      _applyAllocatedReward(from, rewardAmount, since, mode);
    }

    internalTransferUnderlyingTo(from, receiver, underlyingAmount, index);

    emit Redeemed(from, receiver, stakeAmount, underlyingAmount);
    emit Transfer(from, address(0), stakeAmount);
    return (stakeAmount, underlyingAmount);
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
    return super.getRewardEntry(account).rewardBase;
  }

  function rewardedBalanceOf(address account) external view override returns (uint256) {
    return super.getRewardEntry(account).rewardBase;
  }

  function balanceOfUnderlying(address account) public view virtual override returns (uint256) {
    return uint256(super.getRewardEntry(account).rewardBase).rayMul(exchangeRate());
  }

  function totalSupply() public view override returns (uint256) {
    return super.internalGetTotalSupply();
  }

  /// @dev Activates the cooldown period to unstake. Reverts if the user has no stake.
  function cooldown() external override {
    require(balanceOf(msg.sender) != 0, Errors.STK_INVALID_BALANCE_ON_COOLDOWN);

    super.internalSetRewardEntryCustom(msg.sender, uint32(block.timestamp));
    emit CooldownStarted(msg.sender, uint32(block.timestamp));
  }

  function getCooldown(address holder) public view override(CooldownBase, IStakeToken) returns (uint32) {
    return super.getRewardEntry(holder).custom;
  }

  function balanceAndCooldownOf(address holder)
    external
    view
    override
    returns (
      uint256,
      uint32 windowStart,
      uint32 windowEnd
    )
  {
    windowStart = getCooldown(holder);
    if (windowStart != 0) {
      windowStart += uint32(COOLDOWN_PERIOD());
      unchecked {
        windowEnd = windowStart + uint32(UNSTAKE_PERIOD());
      }
      if (windowEnd < windowStart) {
        windowEnd = type(uint32).max;
      }
    }
    return (balanceOf(holder), windowStart, windowEnd);
  }

  function internalTransferUnderlyingFrom(
    address from,
    uint256 underlyingAmount,
    uint256 index
  ) internal virtual {
    index;
    _stakedToken.safeTransferFrom(from, address(this), underlyingAmount);
  }

  function internalTransferUnderlyingTo(
    address from,
    address to,
    uint256 underlyingAmount,
    uint256 index
  ) internal virtual {
    from;
    index;
    _stakedToken.safeTransfer(to, underlyingAmount);
  }

  function internalTransferSlashedUnderlying(address destination, uint256 amount)
    internal
    virtual
    override
    returns (bool erc20Transfer)
  {
    if (address(_strategy) == address(0)) {
      _stakedToken.safeTransfer(destination, amount);
    } else {
      amount = UnderlyingHelper.delegateWithdrawUnderlying(_strategy, address(_stakedToken), amount, destination);
    }
    return true;
  }

  function setCooldown(uint32 cooldownPeriod, uint32 unstakePeriod) external override onlyStakeAdminOrConfigurator {
    super.internalSetCooldown(cooldownPeriod, unstakePeriod);
  }

  function isRedeemable() external view override returns (bool) {
    return !(super.isPaused() || _notRedeemable);
  }

  function setRedeemable(bool redeemable) external override onlyLiquidityController {
    _notRedeemable = !redeemable;
    emit RedeemableUpdated(redeemable);
  }

  function getUnderlying() internal view returns (address) {
    return address(_stakedToken);
  }

  function transferBalance(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    (uint256 balanceFrom, uint32 cooldownFrom) = internalBalanceAndCooldownOf(from);

    {
      (uint256 rewardAmount, uint32 since, AllocationMode mode) = super.doDecrementRewardBalance(from, amount, 0);

      // if cooldown was set and whole balance of sender was transferred - clear cooldown
      if (balanceFrom == amount && cooldownFrom != 0) {
        super.internalSetRewardEntryCustom(from, 0);
      }

      _applyAllocatedReward(from, rewardAmount, since, mode);
    }

    (uint256 balanceTo, uint32 cooldownTo) = internalBalanceAndCooldownOf(to);
    uint32 newCooldownTo = getNextCooldown(cooldownFrom, amount, balanceTo, cooldownTo);

    {
      (uint256 rewardAmount, uint32 since, AllocationMode mode) = super.doIncrementRewardBalance(to, amount);
      if (newCooldownTo != cooldownTo) {
        super.internalSetRewardEntryCustom(to, newCooldownTo);
      }
      _applyAllocatedReward(to, rewardAmount, since, mode);
    }
  }

  function initializedStakeTokenWith()
    external
    view
    override
    returns (
      StakeTokenConfig memory params,
      string memory name_,
      string memory symbol_
    )
  {
    params.stakeController = _remoteAcl;
    params.stakedToken = _stakedToken;
    params.cooldownPeriod = uint32(super.COOLDOWN_PERIOD());
    params.unstakePeriod = uint32(super.UNSTAKE_PERIOD());
    params.maxSlashable = super.getMaxSlashablePercentage();
    params.stakedTokenDecimals = super.decimals();
    return (params, super.name(), super.symbol());
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import '../../../access/interfaces/IMarketAccessController.sol';
import '../../../interfaces/IUnderlyingStrategy.sol';

struct StakeTokenConfig {
  IMarketAccessController stakeController;
  IERC20 stakedToken;
  IUnderlyingStrategy strategy;
  uint32 cooldownPeriod;
  uint32 unstakePeriod;
  uint16 maxSlashable;
  uint8 stakedTokenDecimals;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to implement versioned initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` or `initializerRunAlways` modifier.
 * The revision number should be defined as a private constant, returned by getRevision() and used by initializer() modifier.
 *
 * ATTN: There is a built-in protection from implementation self-destruct exploits. This protection
 * prevents initializers from being called on an implementation inself, but only on proxied contracts.
 * To override this protection, call _unsafeResetVersionedInitializers() from a constructor.
 *
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an initializable contract, as well
 * as extending an initializable contract via inheritance.
 *
 * ATTN: When used with inheritance, parent initializers with `initializer` modifier are prevented by calling twice,
 * but can only be called in child-to-parent sequence.
 *
 * WARNING: When used with inheritance, parent initializers with `initializerRunAlways` modifier
 * are NOT protected from multiple calls by another initializer.
 */
abstract contract VersionedInitializable {
  uint256 private constant BLOCK_REVISION = type(uint256).max;
  // This revision number is applied to implementations
  uint256 private constant IMPL_REVISION = BLOCK_REVISION - 1;

  /// @dev Indicates that the contract has been initialized. The default value blocks initializers from being called on an implementation.
  uint256 private lastInitializedRevision = IMPL_REVISION;

  /// @dev Indicates that the contract is in the process of being initialized.
  uint256 private lastInitializingRevision = 0;

  /**
   * @dev There is a built-in protection from self-destruct of implementation exploits. This protection
   * prevents initializers from being called on an implementation inself, but only on proxied contracts.
   * Function _unsafeResetVersionedInitializers() can be called from a constructor to disable this protection.
   * It must be called before any initializers, otherwise it will fail.
   */
  function _unsafeResetVersionedInitializers() internal {
    require(isConstructor(), 'only for constructor');

    if (lastInitializedRevision == IMPL_REVISION) {
      lastInitializedRevision = 0;
    } else {
      require(lastInitializedRevision == 0, 'can only be called before initializer(s)');
    }
  }

  /// @dev Modifier to use in the initializer function of a contract.
  modifier initializer(uint256 localRevision) {
    (uint256 topRevision, bool initializing, bool skip) = _preInitializer(localRevision);

    if (!skip) {
      lastInitializingRevision = localRevision;
      _;
      lastInitializedRevision = localRevision;
    }

    if (!initializing) {
      lastInitializedRevision = topRevision;
      lastInitializingRevision = 0;
    }
  }

  modifier initializerRunAlways(uint256 localRevision) {
    (uint256 topRevision, bool initializing, bool skip) = _preInitializer(localRevision);

    if (!skip) {
      lastInitializingRevision = localRevision;
    }
    _;
    if (!skip) {
      lastInitializedRevision = localRevision;
    }

    if (!initializing) {
      lastInitializedRevision = topRevision;
      lastInitializingRevision = 0;
    }
  }

  function _preInitializer(uint256 localRevision)
    private
    returns (
      uint256 topRevision,
      bool initializing,
      bool skip
    )
  {
    topRevision = getRevision();
    require(topRevision < IMPL_REVISION, 'invalid contract revision');

    require(localRevision > 0, 'incorrect initializer revision');
    require(localRevision <= topRevision, 'inconsistent contract revision');

    if (lastInitializedRevision < IMPL_REVISION) {
      // normal initialization
      initializing = lastInitializingRevision > 0 && lastInitializedRevision < topRevision;
      require(initializing || isConstructor() || topRevision > lastInitializedRevision, 'already initialized');
    } else {
      // by default, initialization of implementation is only allowed inside a constructor
      require(lastInitializedRevision == IMPL_REVISION && isConstructor(), 'initializer blocked');

      // enable normal use of initializers inside a constructor
      lastInitializedRevision = 0;
      // but make sure to block initializers afterwards
      topRevision = BLOCK_REVISION;

      initializing = lastInitializingRevision > 0;
    }

    if (initializing) {
      require(lastInitializingRevision > localRevision, 'incorrect order of initializers');
    }

    if (localRevision <= lastInitializedRevision) {
      // prevent calling of parent's initializer when it was called before
      if (initializing) {
        // Can't set zero yet, as it is not a top-level call, otherwise `initializing` will become false.
        // Further calls will fail with the `incorrect order` assertion above.
        lastInitializingRevision = 1;
      }
      return (topRevision, initializing, true);
    }
    return (topRevision, initializing, false);
  }

  function isRevisionInitialized(uint256 localRevision) internal view returns (bool) {
    return lastInitializedRevision >= localRevision;
  }

  // solhint-disable-next-line func-name-mixedcase
  function REVISION() public pure returns (uint256) {
    return getRevision();
  }

  /**
   * @dev returns the revision number (< type(uint256).max - 1) of the contract.
   * The number should be defined as a private constant.
   **/
  function getRevision() internal pure virtual returns (uint256);

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    uint256 cs;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      cs := extcodesize(address())
    }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[4] private ______gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './IERC20.sol';
import './Address.sol';

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function callOptionalReturn(IERC20 token, bytes memory data) private {
    require(address(token).isContract(), 'SafeERC20: call to non-contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = address(token).call(data);
    require(success, 'SafeERC20: low-level call failed');

    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IRewardController.sol';

interface IInitializableRewardPool {
  struct InitRewardPoolData {
    IRewardController controller;
    string poolName;
    uint16 baselinePercentage;
  }

  function initializeRewardPool(InitRewardPoolData calldata) external;

  function initializedRewardPoolWith() external view returns (InitRewardPoolData memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './CalcLinearRewardBalances.sol';

abstract contract CalcLinearWeightedReward is CalcLinearRewardBalances {
  uint256 private _accumRate;
  uint256 private _totalSupply;

  uint256 private constant _maxWeightBase = 1e36;

  function internalGetTotalSupply() internal view returns (uint256) {
    return _totalSupply;
  }

  function internalRateUpdated(
    uint256 lastRate,
    uint32 lastAt,
    uint32 at
  ) internal override {
    if (_totalSupply == 0) {
      return;
    }

    // the rate is weighted now vs _maxWeightBase
    if (at != lastAt) {
      lastRate *= _maxWeightBase / _totalSupply;
      _accumRate += lastRate * (at - lastAt);
    }
  }

  function doUpdateTotalSupply(uint256 newSupply) internal returns (bool) {
    if (newSupply == _totalSupply) {
      return false;
    }
    return internalSetTotalSupply(newSupply, getCurrentTick());
  }

  function doIncrementTotalSupply(uint256 amount) internal {
    doUpdateTotalSupply(_totalSupply + amount);
  }

  function doDecrementTotalSupply(uint256 amount) internal {
    doUpdateTotalSupply(_totalSupply - amount);
  }

  function internalSetTotalSupply(uint256 totalSupply, uint32 at) internal returns (bool rateUpdated) {
    (uint256 lastRate, uint32 lastAt) = getRateAndUpdatedAt();
    internalMarkRateUpdate(at);

    if (lastRate > 0) {
      internalRateUpdated(lastRate, lastAt, at);
      rateUpdated = lastAt != at;
    }

    _totalSupply = totalSupply;
    return rateUpdated;
  }

  function internalGetLastAccumRate() internal view returns (uint256) {
    return _accumRate;
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
      uint32 /* since */
    )
  {
    adjRate = _accumRate;

    if (_totalSupply > 0) {
      (uint256 rate, uint32 updatedAt) = getRateAndUpdatedAt();

      rate *= _maxWeightBase / _totalSupply;
      adjRate += rate * (at - updatedAt);
    }

    if (adjRate == lastAccumRate || entry.rewardBase == 0) {
      return (adjRate, 0, entry.claimedAt);
    }

    allocated = (uint256(entry.rewardBase) * (adjRate - lastAccumRate)) / _maxWeightBase;
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
    if (factor == 0) {
      // ATTN! This line was added after mainnet deploy and is NOT present in the original pools
      _setRate(0);
    } else {
      require(factor <= PercentageMath.ONE, 'illegal value');
    }
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

import './IERC20Details.sol';

abstract contract ERC20DetailsBase is IERC20Details {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
  }

  function _initializeERC20(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) internal {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
  }

  function name() public view override returns (string memory) {
    return _name;
  }

  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  function decimals() public view override returns (uint8) {
    return _decimals;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../dependencies/openzeppelin/contracts/IERC20.sol';

abstract contract ERC20AllowanceBase is IERC20 {
  mapping(address => mapping(address => uint256)) private _allowances;

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _decAllowance(msg.sender, spender, subtractedValue, 'ERC20: decreased allowance below zero');
    return true;
  }

  function useAllowance(address owner, uint256 subtractedValue) public virtual returns (bool) {
    _decAllowance(owner, msg.sender, subtractedValue, 'ERC20: decreased allowance below zero');
    return true;
  }

  function _decAllowance(
    address owner,
    address spender,
    uint256 subtractedValue,
    string memory errMsg
  ) private {
    uint256 limit = _allowances[owner][spender];
    require(limit >= subtractedValue, errMsg);
    unchecked {
      _approve(owner, spender, limit - subtractedValue);
    }
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  event Approval(address indexed owner, address indexed spender, uint256 value);

  function _approveTransferFrom(address owner, uint256 amount) internal virtual {
    _decAllowance(owner, msg.sender, amount, 'ERC20: transfer amount exceeds allowance');
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../dependencies/openzeppelin/contracts/IERC20.sol';

abstract contract ERC20TransferBase is IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approveTransferFrom(sender, amount);
    return true;
  }

  function _approveTransferFrom(address owner, uint256 amount) internal virtual;

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    _beforeTokenTransfer(sender, recipient, amount);
    if (sender != recipient) {
      transferBalance(sender, recipient, amount);
    }

    emit Transfer(sender, recipient, amount);
  }

  function transferBalance(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual;

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be to transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IERC20WithPermit.sol';

abstract contract ERC20PermitBase is IERC20WithPermit {
  // solhint-disable-next-line var-name-mixedcase
  bytes32 public DOMAIN_SEPARATOR;
  bytes public constant EIP712_REVISION = bytes('1');
  bytes32 internal constant EIP712_DOMAIN =
    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');
  bytes32 public constant PERMIT_TYPEHASH =
    keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');

  /// @dev owner => next valid nonce to submit with permit()
  /// keep public for backward compatibility
  mapping(address => uint256) public _nonces;

  constructor() {
    _initializeDomainSeparator();
  }

  /// @dev returns nonce, to comply with eip-2612
  function nonces(address addr) external view returns (uint256) {
    return _nonces[addr];
  }

  function _initializeDomainSeparator() internal {
    uint256 chainId;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(EIP712_DOMAIN, keccak256(_getPermitDomainName()), keccak256(EIP712_REVISION), chainId, address(this))
    );
  }

  /**
   * @dev implements the permit function as for https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param owner the owner of the funds
   * @param spender the spender
   * @param value the amount
   * @param deadline the deadline timestamp, type(uint256).max for no deadline
   * @param v signature param
   * @param s signature param
   * @param r signature param
   */

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override {
    require(owner != address(0), 'INVALID_OWNER');
    require(block.timestamp <= deadline, 'INVALID_EXPIRATION');
    uint256 currentValidNonce = _nonces[owner];
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentValidNonce, deadline))
      )
    );

    require(owner == ecrecover(digest, v, r, s), 'INVALID_SIGNATURE');
    _nonces[owner] = currentValidNonce + 1;
    _approveByPermit(owner, spender, value);
  }

  function _approveByPermit(
    address owner,
    address spender,
    uint256 value
  ) internal virtual;

  function _getPermitDomainName() internal view virtual returns (bytes memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../Errors.sol';

/// @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
library WadRayMath {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant halfWAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /// @return One ray, 1e27
  function ray() internal pure returns (uint256) {
    return RAY;
  }

  /// @return One wad, 1e18
  function wad() internal pure returns (uint256) {
    return WAD;
  }

  /// @return Half ray, 1e27/2
  function halfRay() internal pure returns (uint256) {
    return halfRAY;
  }

  /// @return Half ray, 1e18/2
  function halfWad() internal pure returns (uint256) {
    return halfWAD;
  }

  /// @dev Multiplies two wad, rounding half up to the nearest wad
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    require(a <= (type(uint256).max - halfWAD) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * b + halfWAD) / WAD;
  }

  /// @dev Divides two wad, rounding half up to the nearest wad
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / WAD, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * WAD + halfB) / b;
  }

  /// @dev Multiplies two ray, rounding half up to the nearest ray
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    require(a <= (type(uint256).max - halfRAY) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * b + halfRAY) / RAY;
  }

  /// @dev Divides two ray, rounding half up to the nearest ray
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / RAY, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * RAY + halfB) / b;
  }

  /// @dev Casts ray down to wad
  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = WAD_RAY_RATIO / 2;
    uint256 result = halfRatio + a;

    require(result >= halfRatio, Errors.MATH_ADDITION_OVERFLOW);

    return result / WAD_RAY_RATIO;
  }

  /// @dev Converts wad up to ray
  function wadToRay(uint256 a) internal pure returns (uint256) {
    uint256 result = a * WAD_RAY_RATIO;

    require(result / WAD_RAY_RATIO == a, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return result;
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

import '../../../dependencies/openzeppelin/contracts/Address.sol';
import '../../../interfaces/IUnderlyingStrategy.sol';

library UnderlyingHelper {
  function delegateWithdrawUnderlying(
    IUnderlyingStrategy strategy,
    address asset,
    uint256 amount,
    address to
  ) internal returns (uint256) {
    bytes memory result = Address.functionDelegateCall(
      address(strategy),
      abi.encodeWithSelector(IUnderlyingStrategy.delegatedWithdrawUnderlying.selector, asset, amount, to)
    );
    return abi.decode(result, (uint256));
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './StakeTokenConfig.sol';

/// @dev Interface for the initialize function on StakeToken
interface IInitializableStakeToken {
  event Initialized(StakeTokenConfig params, string tokenName, string tokenSymbol);

  function initializeStakeToken(
    StakeTokenConfig calldata params,
    string calldata name,
    string calldata symbol
  ) external;

  function initializedStakeTokenWith()
    external
    view
    returns (
      StakeTokenConfig memory params,
      string memory name,
      string memory symbol
    );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../tools/Errors.sol';
import './interfaces/IStakeToken.sol';
import './interfaces/IManagedStakeToken.sol';

abstract contract CooldownBase is IStakeToken, IManagedStakeToken {
  uint32 internal constant MIN_UNSTAKE_PERIOD = 2 minutes;

  uint32 private _cooldownPeriod;
  uint32 private _unstakePeriod = MIN_UNSTAKE_PERIOD;

  function _ensureCooldown(address user) internal view returns (uint32 cooldownStartedAt) {
    cooldownStartedAt = uint32(getCooldown(user));
    require(
      cooldownStartedAt != 0 && block.timestamp > cooldownStartedAt + _cooldownPeriod,
      Errors.STK_INSUFFICIENT_COOLDOWN
    );
    require(
      block.timestamp <= (cooldownStartedAt + _cooldownPeriod) + _unstakePeriod,
      Errors.STK_UNSTAKE_WINDOW_FINISHED
    );
  }

  function getCooldown(address holder) public view virtual override returns (uint32);

  function internalSetCooldown(uint32 cooldownPeriod, uint32 unstakePeriod) internal {
    require(cooldownPeriod <= 52 weeks, Errors.STK_WRONG_COOLDOWN_OR_UNSTAKE);
    require(unstakePeriod >= MIN_UNSTAKE_PERIOD && unstakePeriod <= 52 weeks, Errors.STK_WRONG_COOLDOWN_OR_UNSTAKE);
    _cooldownPeriod = cooldownPeriod;
    _unstakePeriod = unstakePeriod;
    emit CooldownUpdated(cooldownPeriod, unstakePeriod);
  }

  /**
   * @dev Calculates the how is gonna be a new cooldown time depending on the sender/receiver situation
   *  - If the time of the sender is better or the time of the recipient is 0, we take the one of the recipient
   *  - Weighted average of from/to cooldown time if:
   *    # The sender doesn't have the cooldown activated (time 0).
   *    # The sender time is passed
   *    # The sender has a worse time
   *  - If the receiver's cooldown time passed (too old), the next is 0
   * @param fromCooldownStart Cooldown time of the sender
   * @param amountToReceive Amount
   * @param toBalance Current balance of the receiver
   * @param toCooldownStart Cooldown of the recipient
   * @return The new cooldown time of the recipient
   **/
  function getNextCooldown(
    uint32 fromCooldownStart,
    uint256 amountToReceive,
    uint256 toBalance,
    uint32 toCooldownStart
  ) internal view returns (uint32) {
    if (toCooldownStart == 0) {
      return 0;
    }

    uint256 minimalValidCooldown = (block.timestamp - _cooldownPeriod) - _unstakePeriod;
    if (minimalValidCooldown > toCooldownStart) {
      return 0;
    }
    if (minimalValidCooldown > fromCooldownStart) {
      fromCooldownStart = uint32(block.timestamp);
    }
    if (fromCooldownStart < toCooldownStart) {
      return toCooldownStart;
    }

    return uint32((amountToReceive * fromCooldownStart + toBalance * toCooldownStart) / (amountToReceive + toBalance));
  }

  // solhint-disable-next-line func-name-mixedcase
  function COOLDOWN_PERIOD() public view returns (uint256) {
    return _cooldownPeriod;
  }

  /// @notice Seconds available to redeem once the cooldown period is fullfilled
  // solhint-disable-next-line func-name-mixedcase
  function UNSTAKE_PERIOD() public view returns (uint256) {
    return _unstakePeriod;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../dependencies/openzeppelin/contracts/IERC20.sol';
import '../../tools/math/WadRayMath.sol';
import '../../tools/math/PercentageMath.sol';
import '../../access/AccessFlags.sol';
import '../../access/MarketAccessBitmask.sol';
import './interfaces/IStakeToken.sol';
import './interfaces/IManagedStakeToken.sol';

abstract contract SlashableBase is IERC20, IStakeToken, IManagedStakeToken, MarketAccessBitmaskMin {
  using AccessHelper for IMarketAccessController;
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  uint96 private _exchangeRate = uint96(WadRayMath.RAY); // RAY >= _exchangeRate > 0
  uint16 private _maxSlashablePercentage;

  constructor(uint16 maxSlashablePercentage) {
    _initializeSlashable(maxSlashablePercentage);
  }

  function _initializeSlashable(uint16 maxSlashablePercentage) internal {
    _exchangeRate = uint96(WadRayMath.RAY);

    if (maxSlashablePercentage >= PercentageMath.HALF_ONE) {
      _maxSlashablePercentage = PercentageMath.HALF_ONE;
    } else {
      _maxSlashablePercentage = maxSlashablePercentage;
    }
  }

  function exchangeRate() public view virtual override returns (uint256) {
    return _exchangeRate;
  }

  function internalExchangeRate() internal view virtual returns (uint256, uint256) {
    return (_exchangeRate, WadRayMath.RAY);
  }

  function internalTotalSupply() internal view virtual returns (uint256);

  function slashUnderlying(
    address destination,
    uint256 minAmount,
    uint256 maxAmount
  ) external virtual override onlyLiquidityController returns (uint256 amount, bool erc20Transfer) {
    uint256 totalSupply;
    (amount, totalSupply) = internalSlash(minAmount, maxAmount);
    if (amount > 0) {
      erc20Transfer = internalTransferSlashedUnderlying(destination, amount);
      emit Slashed(destination, amount, totalSupply);
    }
    return (amount, erc20Transfer);
  }

  function internalSlash(uint256 minAmount, uint256 maxAmount) internal returns (uint256 amount, uint256 totalSupply) {
    totalSupply = internalTotalSupply();
    uint256 scaledSupply = totalSupply.rayMul(_exchangeRate);
    uint256 maxSlashable = scaledSupply.percentMul(_maxSlashablePercentage);

    if (maxAmount >= maxSlashable) {
      amount = maxSlashable;
    } else {
      amount = maxAmount;
    }
    if (amount < minAmount) {
      return (0, totalSupply);
    }

    uint96 newExchangeRate;
    unchecked {
      newExchangeRate = uint96(((scaledSupply - amount) * WadRayMath.RAY) / totalSupply);
      totalSupply = totalSupply.rayMul(newExchangeRate);
      amount = scaledSupply - totalSupply;
    }
    _exchangeRate = newExchangeRate;

    return (amount, totalSupply);
  }

  function internalTransferSlashedUnderlying(address destination, uint256 amount)
    internal
    virtual
    returns (bool erc20Transfer);

  function getMaxSlashablePercentage() public view override returns (uint16) {
    return _maxSlashablePercentage;
  }

  modifier onlyStakeAdminOrConfigurator() {
    _remoteAcl.requireAnyOf(
      msg.sender,
      AccessFlags.STAKE_ADMIN | AccessFlags.STAKE_CONFIGURATOR,
      Errors.CALLER_NOT_STAKE_ADMIN
    );
    _;
  }

  modifier onlyLiquidityController() {
    _remoteAcl.requireAnyOf(msg.sender, AccessFlags.LIQUIDITY_CONTROLLER, Errors.CALLER_NOT_LIQUIDITY_CONTROLLER);
    _;
  }

  function setMaxSlashablePercentage(uint16 slashPct) external override onlyStakeAdminOrConfigurator {
    require(slashPct <= PercentageMath.HALF_ONE, Errors.STK_EXCESSIVE_SLASH_PCT);
    _maxSlashablePercentage = slashPct;
    emit MaxSlashUpdated(slashPct);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP excluding events to avoid linearization issues.
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
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// solhint-disable no-inline-assembly, avoid-low-level-calls

/**
 * @dev Collection of functions related to the address type
 */
library Address {
  /**
   * @dev Returns true if `account` is a contract.
   *
   * [IMPORTANT]
   * ====
   * It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   *
   * Among others, `isContract` will return false for the following
   * types of addresses:
   *
   *  - an externally-owned account
   *  - a contract in construction
   *  - an address where a contract will be created
   *  - an address where a contract lived, but was destroyed
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  bytes32 private constant accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

  function isExternallyOwned(address account) internal view returns (bool) {
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    uint256 size;
    assembly {
      codehash := extcodehash(account)
      size := extcodesize(account)
    }
    return codehash == accountHash && size == 0;
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
   * `recipient`, forwarding all available gas and reverting on errors.
   *
   * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
   * of certain opcodes, possibly making contracts go over the 2300 gas limit
   * imposed by `transfer`, making them unable to receive funds via
   * `transfer`. {sendValue} removes this limitation.
   *
   * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using {ReentrancyGuard}.
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, 'Address: insufficient balance');

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain `call` is an unsafe replacement for a function call: use this
   * function instead.
   *
   * If `target` reverts with a revert reason, it is bubbled up by this
   * function (like regular Solidity function calls).
   *
   * Returns the raw returned data.
   *
   * Requirements:
   *
   * - `target` must be a contract.
   * - calling `target` with `data` must not revert.
   *
   * _Available since v3.1._
   */
  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, 'Address: low-level call failed');
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
   * `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but also transferring `value` wei to `target`.
   *
   * Requirements:
   *
   * - the calling contract must have an ETH balance of at least `value`.
   * - the called Solidity function must be `payable`.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, 'Address: insufficient balance for call');
    require(isContract(target), 'Address: call to non-contract');

    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, 'Address: low-level static call failed');
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), 'Address: static call to non-contract');

    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), 'Address: delegate call to non-contract');

    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
   * revert reason using the provided one.
   *
   * _Available since v4.3._
   */
  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IERC20Details {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../dependencies/openzeppelin/contracts/IERC20.sol';

interface IERC20WithPermit is IERC20 {
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IUnderlyingStrategy {
  function getUnderlying(address asset) external view returns (address);

  function delegatedWithdrawUnderlying(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../../interfaces/IDerivedToken.sol';
import '../../../interfaces/IRewardedToken.sol';
import '../../../interfaces/IUnderlyingBalance.sol';

interface IStakeToken is IDerivedToken, IRewardedToken, IUnderlyingBalance {
  event Staked(address indexed from, address indexed to, uint256 amount, uint256 indexed referal);
  event Redeemed(address indexed from, address indexed to, uint256 amount, uint256 underlyingAmount);
  event CooldownStarted(address indexed account, uint32 at);

  function stake(
    address to,
    uint256 underlyingAmount,
    uint256 referral
  ) external returns (uint256 stakeAmount);

  /**
   * @dev Redeems staked tokens, and stop earning rewards. Reverts if cooldown is not finished or is outside of the unstake window.
   * @param to Address to redeem to
   * @param stakeAmount Amount of stake to redeem
   **/
  function redeem(address to, uint256 maxStakeAmount) external returns (uint256 stakeAmount);

  /**
   * @dev Redeems staked tokens, and stop earning rewards. Reverts if cooldown is not finished or is outside of the unstake window.
   * @param to Address to redeem to
   * @param underlyingAmount Amount of underlying to redeem
   **/
  function redeemUnderlying(address to, uint256 maxUnderlyingAmount) external returns (uint256 underlyingAmount);

  /// @dev Activates the cooldown period to unstake. Reverts if the user has no stake.
  function cooldown() external;

  /// @dev Returns beginning of the current cooldown period or zero when cooldown was not triggered.
  function getCooldown(address) external view returns (uint32);

  function exchangeRate() external view returns (uint256);

  function isRedeemable() external view returns (bool);

  function getMaxSlashablePercentage() external view returns (uint16);

  function balanceAndCooldownOf(address holder)
    external
    view
    returns (
      uint256 balance,
      uint32 windowStart,
      uint32 windowEnd
    );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../../interfaces/IEmergencyAccess.sol';

interface IManagedStakeToken is IEmergencyAccess {
  event Slashed(address to, uint256 amount, uint256 totalBeforeSlash);

  event MaxSlashUpdated(uint16 maxSlash);
  event CooldownUpdated(uint32 cooldownPeriod, uint32 unstakePeriod);

  event RedeemableUpdated(bool redeemable);

  function setRedeemable(bool redeemable) external;

  function setMaxSlashablePercentage(uint16 percentage) external;

  function setCooldown(uint32 cooldownPeriod, uint32 unstakePeriod) external;

  function slashUnderlying(
    address destination,
    uint256 minAmount,
    uint256 maxAmount
  ) external returns (uint256 amount, bool erc20Transfer);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

// solhint-disable func-name-mixedcase
interface IDerivedToken {
  /**
   * @dev Returns the address of the underlying asset of this token (E.g. WETH for agWETH)
   **/
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IRewardedToken {
  function setIncentivesController(address) external;

  function getIncentivesController() external view returns (address);

  function rewardedBalanceOf(address) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IUnderlyingBalance {
  /// @dev Returns amount of underlying for the given address
  function balanceOfUnderlying(address account) external view returns (uint256);
}

interface ILockedUnderlyingBalance is IUnderlyingBalance {
  /// @dev Returns amount of underlying and a timestamp when the lock expires. Funds can be redeemed after the timestamp.
  function balanceOfUnderlyingAndExpiry(address account)
    external
    view
    returns (uint256 underlying, uint32 availableSince);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/Errors.sol';
import './interfaces/IMarketAccessController.sol';
import './AccessHelper.sol';
import './AccessFlags.sol';

// solhint-disable func-name-mixedcase
abstract contract MarketAccessBitmaskMin {
  using AccessHelper for IMarketAccessController;
  IMarketAccessController internal _remoteAcl;

  constructor(IMarketAccessController remoteAcl) {
    _remoteAcl = remoteAcl;
  }

  function _getRemoteAcl(address addr) internal view returns (uint256) {
    return _remoteAcl.getAcl(addr);
  }

  function hasRemoteAcl() internal view returns (bool) {
    return _remoteAcl != IMarketAccessController(address(0));
  }

  function acl_hasAnyOf(address subject, uint256 flags) internal view returns (bool) {
    return _remoteAcl.hasAnyOf(subject, flags);
  }

  modifier aclHas(uint256 flags) virtual {
    _remoteAcl.requireAnyOf(msg.sender, flags, Errors.TXT_ACCESS_RESTRICTED);
    _;
  }

  modifier aclAnyOf(uint256 flags) {
    _remoteAcl.requireAnyOf(msg.sender, flags, Errors.TXT_ACCESS_RESTRICTED);
    _;
  }

  modifier onlyPoolAdmin() {
    _remoteAcl.requireAnyOf(msg.sender, AccessFlags.POOL_ADMIN, Errors.CALLER_NOT_POOL_ADMIN);
    _;
  }

  modifier onlyRewardAdmin() {
    _remoteAcl.requireAnyOf(msg.sender, AccessFlags.REWARD_CONFIG_ADMIN, Errors.CALLER_NOT_REWARD_CONFIG_ADMIN);
    _;
  }

  modifier onlyRewardConfiguratorOrAdmin() {
    _remoteAcl.requireAnyOf(
      msg.sender,
      AccessFlags.REWARD_CONFIG_ADMIN | AccessFlags.REWARD_CONFIGURATOR,
      Errors.CALLER_NOT_REWARD_CONFIG_ADMIN
    );
    _;
  }
}

abstract contract MarketAccessBitmask is MarketAccessBitmaskMin {
  using AccessHelper for IMarketAccessController;

  constructor(IMarketAccessController remoteAcl) MarketAccessBitmaskMin(remoteAcl) {}

  modifier onlyEmergencyAdmin() {
    _remoteAcl.requireAnyOf(msg.sender, AccessFlags.EMERGENCY_ADMIN, Errors.CALLER_NOT_EMERGENCY_ADMIN);
    _;
  }

  function _onlySweepAdmin() internal view virtual {
    _remoteAcl.requireAnyOf(msg.sender, AccessFlags.SWEEP_ADMIN, Errors.CALLER_NOT_SWEEP_ADMIN);
  }

  modifier onlySweepAdmin() {
    _onlySweepAdmin();
    _;
  }
}