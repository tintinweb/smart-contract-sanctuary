// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../access/interfaces/IMarketAccessController.sol';
import '../tools/upgradeability/VersionedInitializable.sol';
import '../interfaces/IRewardMinter.sol';
import './RewardBooster.sol';

contract RewardBoosterV1 is RewardBooster, VersionedInitializable {
  uint256 private constant CONTRACT_REVISION = 1;

  constructor() RewardBooster(IMarketAccessController(address(0)), IRewardMinter(address(0))) {}

  function getRevision() internal pure virtual override returns (uint256) {
    return CONTRACT_REVISION;
  }

  // This initializer is invoked by AccessController.setAddressAsImpl
  function initialize(IMarketAccessController ac) external virtual initializer(CONTRACT_REVISION) {
    address underlying = ac.getAddress(AccessFlags.REWARD_TOKEN);
    require(underlying != address(0));
    _initialize(ac, IRewardMinter(underlying));
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IRewardMinter {
  /// @dev mints a reward
  function mintReward(
    address holder,
    uint256 amount,
    bool serviceAccount
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/math/PercentageMath.sol';
import '../access/interfaces/IMarketAccessController.sol';
import '../interfaces/IRewardMinter.sol';
import './interfaces/IRewardPool.sol';
import './interfaces/IManagedRewardPool.sol';
import './interfaces/IRewardController.sol';
import './interfaces/IBoostExcessReceiver.sol';
import './interfaces/IBoostRate.sol';
import './interfaces/IRewardExplainer.sol';
import './autolock/AutolockBase.sol';
import './interfaces/IAutolocker.sol';
import './BaseRewardController.sol';

contract RewardBooster is IManagedRewardBooster, IRewardExplainer, BaseRewardController, AutolockBase {
  using PercentageMath for uint256;

  mapping(address => uint32) private _boostFactor;
  IManagedRewardPool private _boostPool;
  uint256 private _boostPoolMask;

  address private _boostExcessDelegate;
  bool private _mintExcess;
  bool private _updateBoostPool;

  mapping(address => uint256) private _boostRewards;

  struct WorkReward {
    // saves some of storage cost
    uint128 claimableReward;
    uint128 boostLimit;
  }
  mapping(address => WorkReward) private _workRewards;

  constructor(IMarketAccessController accessController, IRewardMinter rewardMinter)
    BaseRewardController(accessController, rewardMinter)
  {}

  function internalOnPoolRemoved(IManagedRewardPool pool) internal override {
    super.internalOnPoolRemoved(pool);
    if (_boostPool == pool) {
      _boostPool = IManagedRewardPool(address(0));
      _boostPoolMask = 0;
    } else {
      delete (_boostFactor[address(pool)]);
    }
  }

  function setBoostFactor(address pool, uint32 pctFactor) external override onlyConfigOrRateAdmin {
    require(getPoolMask(pool) != 0, 'unknown pool');
    require(pool != address(_boostPool), 'factor for the boost pool');
    _boostFactor[pool] = pctFactor;
  }

  function getBoostFactor(address pool) external view returns (uint32 pctFactor) {
    return uint32(_boostFactor[pool]);
  }

  function setUpdateBoostPoolRate(bool updateBoostPool) external override onlyConfigAdmin {
    _updateBoostPool = updateBoostPool;
  }

  function internalUpdateBaseline(uint256 baseline, uint256 baselineMask)
    internal
    override
    returns (uint256 totalRate, uint256)
  {
    if (_boostPoolMask == 0 || !_updateBoostPool) {
      return super.internalUpdateBaseline(baseline, baselineMask);
    }

    (totalRate, baselineMask) = super.internalUpdateBaseline(baseline, baselineMask & ~_boostPoolMask);
    if (totalRate < baseline) {
      IBoostRate(address(_boostPool)).setBoostRate(baseline - totalRate);
      totalRate = baseline;
    } else {
      IBoostRate(address(_boostPool)).setBoostRate(0);
    }

    return (totalRate, baselineMask);
  }

  function setBoostPool(address pool) external override onlyConfigAdmin {
    if (pool == address(0)) {
      _boostPoolMask = 0;
    } else {
      uint256 mask = getPoolMask(pool);
      require(mask != 0, 'unknown pool');
      _boostPoolMask = mask;

      delete (_boostFactor[pool]);
    }
    _boostPool = IManagedRewardPool(pool);
  }

  function getBoostPool() external view override returns (address pool, uint256 mask) {
    return (address(_boostPool), _boostPoolMask);
  }

  function setBoostExcessTarget(address target, bool mintExcess) external override onlyConfigAdmin {
    _boostExcessDelegate = target;
    _mintExcess = mintExcess && (target != address(0));
  }

  function getBoostExcessTarget() external view returns (address target, bool mintExcess) {
    return (_boostExcessDelegate, _mintExcess);
  }

  function getClaimMask(address holder, uint256 mask) internal view override returns (uint256) {
    mask = super.getClaimMask(holder, mask);
    mask &= ~_boostPoolMask;
    return mask;
  }

  function internalClaimAndMintReward(address holder, uint256 mask)
    internal
    override
    returns (uint256 claimableAmount, uint256)
  {
    uint256 boostLimit;
    (claimableAmount, boostLimit) = (_workRewards[holder].claimableReward, _workRewards[holder].boostLimit);

    if (boostLimit > 0 || claimableAmount > 0) {
      delete (_workRewards[holder]);
    }

    for (uint256 i = 0; mask != 0; (i, mask) = (i + 1, mask >> 1)) {
      if (mask & 1 == 0) {
        continue;
      }

      IManagedRewardPool pool = getPool(i);
      (uint256 amount_, ) = pool.claimRewardFor(holder, type(uint256).max);
      if (amount_ == 0) {
        continue;
      }

      claimableAmount += amount_;
      boostLimit += amount_.percentMul(_boostFactor[address(pool)]);
    }

    uint256 boostAmount = _boostRewards[holder];
    if (boostAmount > 0) {
      delete (_boostRewards[holder]);
    }

    uint32 boostSince;
    if (_boostPool != IManagedRewardPool(address(0))) {
      uint256 boost_;

      if (_mintExcess || _boostExcessDelegate != address(_boostPool)) {
        (boost_, boostSince) = _boostPool.claimRewardFor(holder, type(uint256).max);
      } else {
        uint256 boostLimit_;
        if (boostLimit > boostAmount) {
          boostLimit_ = boostLimit - boostAmount;
        }
        (boost_, boostSince) = _boostPool.claimRewardFor(holder, boostLimit_);
      }

      boostAmount += boost_;
    }

    if (boostAmount <= boostLimit) {
      claimableAmount += boostAmount;
    } else {
      claimableAmount += boostLimit;
      internalStoreBoostExcess(boostAmount - boostLimit, boostSince);
    }

    return (claimableAmount, 0);
  }

  function internalCalcClaimableReward(
    address holder,
    uint256 mask,
    uint32 at
  ) internal view override returns (uint256 claimableAmount, uint256 delayedAmount) {
    uint256 boostLimit;
    (claimableAmount, boostLimit) = (_workRewards[holder].claimableReward, _workRewards[holder].boostLimit);

    for (uint256 i = 0; mask != 0; (i, mask) = (i + 1, mask >> 1)) {
      if (mask & 1 == 0) {
        continue;
      }

      IManagedRewardPool pool = getPool(i);
      (uint256 amount_, uint256 extra_, ) = pool.calcRewardFor(holder, at);
      delayedAmount += extra_;
      if (amount_ == 0) {
        continue;
      }

      claimableAmount += amount_;
      boostLimit += amount_.percentMul(_boostFactor[address(pool)]);
    }

    uint256 boostAmount = _boostRewards[holder];

    if (_boostPool != IManagedRewardPool(address(0))) {
      (uint256 boost_, uint256 extra_, ) = _boostPool.calcRewardFor(holder, at);
      delayedAmount += extra_;
      boostAmount += boost_;
    }

    if (boostAmount <= boostLimit) {
      claimableAmount += boostAmount;
    } else {
      claimableAmount += boostLimit;
    }

    return (claimableAmount, delayedAmount);
  }

  function internalAllocatedByPool(
    address holder,
    uint256 allocated,
    address pool,
    uint32
  ) internal override {
    if (address(_boostPool) == pool) {
      if (allocated > 0) {
        _boostRewards[holder] += allocated;
      }
      return;
    }

    WorkReward memory workReward = _workRewards[holder];

    uint256 v = workReward.claimableReward + allocated;
    require(v <= type(uint128).max);
    workReward.claimableReward = uint128(v);

    uint32 factor = _boostFactor[pool];
    if (factor != 0) {
      v = workReward.boostLimit + allocated.percentMul(factor);
      require(v <= type(uint128).max);
      workReward.boostLimit = uint128(v);
    }

    _workRewards[holder] = workReward;
  }

  function internalStoreBoostExcess(uint256 boostExcess, uint32 since) private {
    if (_boostExcessDelegate == address(0)) {
      return;
    }

    if (_mintExcess) {
      internalMint(_boostExcessDelegate, boostExcess, true);
      return;
    }

    IBoostExcessReceiver(_boostExcessDelegate).receiveBoostExcess(boostExcess, since);
  }

  function disableAutolock() external onlyConfigAdmin {
    internalDisableAutolock();
  }

  function enableAutolockAndSetDefault(
    AutolockMode mode,
    uint32 lockDuration,
    uint224 param
  ) external onlyConfigAdmin {
    internalSetDefaultAutolock(mode, lockDuration, param);
  }

  function internalClaimed(
    address holder,
    address mintTo,
    uint256 amount
  ) internal override returns (uint256 lockAmount) {
    address lockReceiver;
    (lockAmount, lockReceiver) = internalApplyAutolock(address(_boostPool), holder, amount);
    if (lockAmount > 0) {
      amount -= lockAmount;
      internalMint(lockReceiver, lockAmount, true);
    }
    if (amount > 0) {
      internalMint(mintTo, amount, false);
    }
    return lockAmount;
  }

  function explainReward(address holder, uint32 at) external view override returns (RewardExplained memory) {
    require(at >= uint32(block.timestamp));
    return internalExplainReward(holder, ~uint256(0), at);
  }

  function internalExplainReward(
    address holder,
    uint256 mask,
    uint32 at
  ) internal view returns (RewardExplained memory r) {
    mask = getClaimMask(holder, mask) | _boostPoolMask;

    (r.amountClaimable, r.boostLimit) = (_workRewards[holder].claimableReward, _workRewards[holder].boostLimit);

    uint256 n;
    for (uint256 mask_ = mask; mask_ != 0; mask_ >>= 1) {
      if (mask_ & 1 != 0) {
        n++;
      }
    }
    r.allocations = new RewardExplainEntry[](n);

    n = 0;
    for (uint256 i = 0; mask != 0; (i, mask) = (i + 1, mask >> 1)) {
      if (mask & 1 == 0) {
        continue;
      }

      IManagedRewardPool pool = getPool(i);
      uint256 amount_;
      uint256 extra_;
      (amount_, extra_, r.allocations[n].since) = pool.calcRewardFor(holder, at);
      r.allocations[n].extra = extra_;
      r.amountExtra += extra_;

      r.allocations[n].pool = address(pool);
      r.allocations[n].amount = amount_;

      if (pool == _boostPool) {
        r.allocations[n].rewardType = RewardType.BoostReward;
        r.maxBoost = _boostRewards[holder] + amount_;
      } else {
        r.allocations[n].rewardType = RewardType.WorkReward;
        r.allocations[n].factor = _boostFactor[address(pool)];

        if (amount_ > 0) {
          r.amountClaimable += amount_;
          r.boostLimit += amount_.percentMul(r.allocations[n].factor);
        }
      }

      n++;
    }

    if (r.maxBoost <= r.boostLimit) {
      r.amountClaimable += r.maxBoost;
    } else {
      r.amountClaimable += r.boostLimit;
    }

    return r;
  }
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

import '../../interfaces/IBalanceHook.sol';

interface IRewardPool is IBalanceHook {}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../interfaces/IEmergencyAccess.sol';

interface IManagedRewardPool is IEmergencyAccess {
  function updateBaseline(uint256) external returns (bool hasBaseline, uint256 appliedRate);

  function setBaselinePercentage(uint16) external;

  function getBaselinePercentage() external view returns (bool, uint16);

  function disableBaseline() external;

  function disableRewardPool() external;

  function getRate() external view returns (uint256);

  function getPoolName() external view returns (string memory);

  function claimRewardFor(address holder, uint256 limit) external returns (uint256 amount, uint32 since);

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

  function attachedToRewardController() external;

  event RateUpdated(uint256 rate);
  event BaselineFactorUpdated(uint16);
  event BaselineDisabled();
  event ProviderAdded(address provider, address token);
  event ProviderRemoved(address provider);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../access/interfaces/IMarketAccessController.sol';

enum AllocationMode {Push, SetPull, UnsetPull}

interface IRewardController {
  function allocatedByPool(
    address holder,
    uint256 allocated,
    uint32 since,
    AllocationMode mode
  ) external;

  function isRateAdmin(address) external view returns (bool);

  function isConfigAdmin(address) external view returns (bool);

  function isEmergencyAdmin(address) external view returns (bool);

  function getAccessController() external view returns (IMarketAccessController);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IBoostExcessReceiver {
  function receiveBoostExcess(uint256 amount, uint32 since) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IBoostRate {
  function setBoostRate(uint256 rate) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IRewardExplainer {
  /// @dev provides in depth details about rewards of the holder. Accuracy of future projection is not guaranteed.
  /// @dev NB! explanation does not consider auto-locking
  /// @param at is a timestamp (current or future) to calculate rewards
  /// @return details of rewards, see RewardExplained
  function explainReward(address holder, uint32 at) external view returns (RewardExplained memory);
}

/// @dev details of rewards of a holder, please refer to tokenomics on reward calculations
struct RewardExplained {
  /// @dev total amount of rewards that will be claimed (including boost)
  uint256 amountClaimable;
  /// @dev total amount of rewards allocated to the holder but are frozen now
  uint256 amountExtra;
  /// @dev maximum possible amount of boost generated by xAGF
  uint256 maxBoost;
  /// @dev maximum allowed amount of boost based on work rewards (from deposits, debts, stakes etc)
  uint256 boostLimit;
  /// @dev a list of pools currently generating rewards to the holder
  RewardExplainEntry[] allocations;
}

/// @dev details of reward generation by a reward pool
struct RewardExplainEntry {
  /// @dev amount of rewards generated by the reward pool since last update (see `since`)
  uint256 amount;
  /// @dev amount of rewards frozen by the reward pool
  uint256 extra;
  /// @dev address of the reward pool
  address pool;
  /// @dev timestamp of a last update of the holder in the reward pool (e.g. claim or balance change)
  uint32 since;
  /// @dev multiplication factor in basis points (10000=100%) to calculate boost limit by outcome of the pool
  uint32 factor;
  /// @dev type of reward pool: boost (added to the max boost) or work (added to the claimable amount and to the boost limit)
  RewardType rewardType;
}

enum RewardType {
  WorkReward,
  BoostReward
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../interfaces/IAutolocker.sol';

abstract contract AutolockBase {
  struct AutolockEntry {
    uint224 param;
    AutolockMode mode;
    uint8 lockDuration;
  }

  mapping(address => AutolockEntry) private _autolocks;
  AutolockEntry private _defaultAutolock;

  function internalDisableAutolock() internal {
    _defaultAutolock = AutolockEntry(0, AutolockMode.Default, 0);
    emit RewardAutolockConfigured(address(this), AutolockMode.Default, 0, 0);
  }

  function isAutolockEnabled() public view returns (bool) {
    return _defaultAutolock.mode != AutolockMode.Default;
  }

  function internalSetDefaultAutolock(
    AutolockMode mode,
    uint32 lockDuration,
    uint224 param
  ) internal {
    require(mode > AutolockMode.Default);

    _defaultAutolock = AutolockEntry(param, mode, fromDuration(lockDuration));
    emit RewardAutolockConfigured(address(this), mode, lockDuration, param);
  }

  function fromDuration(uint32 lockDuration) private pure returns (uint8) {
    require(lockDuration % 1 weeks == 0, 'duration must be in weeks');
    uint256 v = lockDuration / 1 weeks;
    require(v <= 4 * 52, 'duration must be less than 209 weeks');
    return uint8(v);
  }

  event RewardAutolockConfigured(
    address indexed account,
    AutolockMode mode,
    uint32 lockDuration,
    uint224 param
  );

  function _setAutolock(
    address account,
    AutolockMode mode,
    uint32 lockDuration,
    uint224 param
  ) private {
    _autolocks[account] = AutolockEntry(param, mode, fromDuration(lockDuration));
    emit RewardAutolockConfigured(account, mode, lockDuration, param);
  }

  function autolockProlongate(uint32 minLockDuration) external {
    _setAutolock(msg.sender, AutolockMode.Prolongate, minLockDuration, 0);
  }

  function autolockAccumulateUnderlying(uint256 maxAmount, uint32 lockDuration) external {
    require(maxAmount > 0, 'max amount is required');
    if (maxAmount > type(uint224).max) {
      maxAmount = type(uint224).max;
    }

    _setAutolock(msg.sender, AutolockMode.AccumulateUnderlying, lockDuration, uint224(maxAmount));
  }

  function autolockAccumulateTill(uint256 timestamp, uint32 lockDuration) external {
    require(timestamp > block.timestamp, 'future timestamp is required');
    if (timestamp > type(uint224).max) {
      timestamp = type(uint224).max;
    }
    _setAutolock(msg.sender, AutolockMode.AccumulateTill, lockDuration, uint224(timestamp));
  }

  function autolockKeepUpBalance(uint256 minAmount, uint32 lockDuration) external {
    require(minAmount > 0, 'min amount is required');
    require(lockDuration > 0, 'lock duration is required');

    if (minAmount > type(uint224).max) {
      minAmount = type(uint224).max;
    }
    _setAutolock(msg.sender, AutolockMode.KeepUpBalance, lockDuration, uint224(minAmount));
  }

  function autolockDefault() external {
    _setAutolock(msg.sender, AutolockMode.Default, 0, 0);
  }

  function autolockStop() external {
    _setAutolock(msg.sender, AutolockMode.Stop, 0, 0);
  }

  function autolockOf(address account)
    public
    view
    returns (
      AutolockMode mode,
      uint32 lockDuration,
      uint256 param
    )
  {
    AutolockEntry memory entry = _autolocks[account];
    if (entry.mode == AutolockMode.Default) {
      entry = _defaultAutolock;
    }
    return (entry.mode, entry.lockDuration * 1 weeks, entry.param);
  }

  function internalApplyAutolock(
    address autolocker,
    address holder,
    uint256 amount
  ) internal returns (uint256 lockAmount, address lockReceiver) {
    if (autolocker == address(0)) {
      return (0, address(0));
    }

    AutolockEntry memory entry = _autolocks[holder];
    if (entry.mode == AutolockMode.Stop || _defaultAutolock.mode == AutolockMode.Default) {
      return (0, address(0));
    }

    if (entry.mode == AutolockMode.Default) {
      entry = _defaultAutolock;
      if (entry.mode == AutolockMode.Stop) {
        return (0, address(0));
      }
    }

    bool stop;
    (lockReceiver, lockAmount, stop) = IAutolocker(autolocker).applyAutolock(
      holder,
      amount,
      entry.mode,
      entry.lockDuration * 1 weeks,
      entry.param
    );

    if (stop) {
      _setAutolock(holder, AutolockMode.Stop, 0, 0);
    }

    if (lockAmount > 0) {
      require(lockReceiver != address(0));
      return (lockAmount, lockReceiver);
    }
    return (0, address(0));
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

enum AutolockMode {Default, Stop, Prolongate, AccumulateUnderlying, AccumulateTill, KeepUpBalance}

interface IAutolocker {
  function applyAutolock(
    address account,
    uint256 amount,
    AutolockMode mode,
    uint32 lockDuration,
    uint224 param
  )
    external
    returns (
      address receiver,
      uint256 lockAmount,
      bool completed
    );

  event RewardAutolocked(address indexed account, uint256 amount, AutolockMode mode);
  event RewardAutolockFailed(address indexed account, AutolockMode mode, uint256 error);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/math/BitUtils.sol';
import '../access/interfaces/IMarketAccessController.sol';
import '../access/MarketAccessBitmask.sol';
import '../access/AccessFlags.sol';
import './interfaces/IManagedRewardController.sol';
import './interfaces/IManagedRewardPool.sol';
import '../interfaces/IRewardMinter.sol';
import './interfaces/IRewardCollector.sol';
import '../tools/Errors.sol';

abstract contract BaseRewardController is IRewardCollector, MarketAccessBitmask, IManagedRewardController {
  IRewardMinter private _rewardMinter;

  IManagedRewardPool[] private _poolList;
  /* IManagedRewardPool => mask */
  mapping(address => uint256) private _poolMask;
  /* holder => masks of related pools */
  mapping(address => uint256) private _memberOf;

  uint256 private _ignoreMask;
  uint256 private _baselineMask;

  bool private _paused;

  constructor(IMarketAccessController accessController, IRewardMinter rewardMinter)
    MarketAccessBitmask(accessController)
  {
    _rewardMinter = rewardMinter;
  }

  function _initialize(IMarketAccessController ac, IRewardMinter rewardMinter) internal {
    _remoteAcl = ac;
    _rewardMinter = rewardMinter;
  }

  function getAccessController() public view override returns (IMarketAccessController) {
    return _remoteAcl;
  }

  function addRewardPool(IManagedRewardPool pool) external override onlyConfigAdmin {
    require(address(pool) != address(0), 'reward pool required');
    require(_poolMask[address(pool)] == 0, 'already registered');
    require(_poolList.length <= 255, 'too many pools');

    uint256 poolMask = 1 << _poolList.length;
    _poolMask[address(pool)] = poolMask;
    _baselineMask |= poolMask;
    _poolList.push(pool);

    pool.attachedToRewardController(); // access check

    emit RewardPoolAdded(address(pool), poolMask);
  }

  function removeRewardPool(IManagedRewardPool pool) external override onlyConfigAdmin {
    require(address(pool) != address(0), 'reward pool required');
    uint256 poolMask = _poolMask[address(pool)];
    if (poolMask == 0) {
      return;
    }
    uint256 idx = BitUtils.bitLength(poolMask);
    require(_poolList[idx] == pool, 'unexpected pool');

    _poolList[idx] = IManagedRewardPool(address(0));
    delete (_poolMask[address(pool)]);
    _ignoreMask |= poolMask;

    internalOnPoolRemoved(pool);

    emit RewardPoolRemoved(address(pool), poolMask);
  }

  function getPoolMask(address pool) public view returns (uint256 poolMask) {
    poolMask = _poolMask[pool];
    if (poolMask & _ignoreMask != 0) {
      return 0;
    }
    return poolMask;
  }

  function internalOnPoolRemoved(IManagedRewardPool) internal virtual {}

  function updateBaseline(uint256 baseline) external override onlyRateAdmin returns (uint256 totalRate) {
    (totalRate, _baselineMask) = internalUpdateBaseline(baseline, _baselineMask);
    require(totalRate <= baseline, Errors.RW_BASELINE_EXCEEDED);
    emit BaselineUpdated(baseline, totalRate, _baselineMask);
    return totalRate;
  }

  function internalUpdateBaseline(uint256 baseline, uint256 baselineMask)
    internal
    virtual
    returns (uint256 totalRate, uint256)
  {
    baselineMask &= ~_ignoreMask;

    for (uint8 i = 0; i <= 255; i++) {
      uint256 mask = uint256(1) << i;
      if (mask & baselineMask == 0) {
        if (mask > baselineMask) {
          break;
        }
        continue;
      }
      (bool hasBaseline, uint256 appliedRate) = _poolList[i].updateBaseline(baseline);
      if (appliedRate != 0 || hasBaseline) {
        totalRate += appliedRate;
        continue;
      }
      baselineMask &= ~mask;
    }
    return (totalRate, baselineMask);
  }

  function setRewardMinter(IRewardMinter minter) external override onlyConfigAdmin {
    _rewardMinter = minter;
    emit RewardMinterSet(address(minter));
  }

  function getPools() public view override returns (IManagedRewardPool[] memory, uint256 ignoreMask) {
    return (_poolList, _ignoreMask);
  }

  function getRewardMinter() external view returns (address) {
    return address(_rewardMinter);
  }

  function claimReward() external override notPaused returns (uint256 claimed, uint256 extra) {
    return _claimReward(msg.sender, ~uint256(0), msg.sender);
  }

  function claimRewardTo(address receiver) external override notPaused returns (uint256 claimed, uint256 extra) {
    require(receiver != address(0), 'receiver is required');
    return _claimReward(msg.sender, ~uint256(0), receiver);
  }

  // function claimRewardFor(address holder, uint256 mask)
  //   external
  //   notPaused
  //   returns (uint256 claimed, uint256 extra)
  // {
  //   require(holder != address(0), 'holder is required');
  //   return _claimReward(holder, mask, holder);
  // }

  function claimableReward(address holder) public view override returns (uint256 claimable, uint256 extra) {
    return _calcReward(holder, ~uint256(0), uint32(block.timestamp));
  }

  // function claimableRewardFor(
  //   address holder,
  //   uint256 mask,
  //   uint32 at
  // ) public view returns (uint256 claimable, uint256 extra) {
  //   require(holder != address(0), 'holder is required');
  //   return _calcReward(holder, mask, at);
  // }

  function balanceOf(address holder) external view override returns (uint256) {
    if (holder == address(0)) {
      return 0;
    }
    (uint256 claimable, uint256 extra) = _calcReward(holder, ~uint256(0), uint32(block.timestamp));
    return claimable + extra;
  }

  function claimablePools(address holder) external view returns (uint256) {
    return _memberOf[holder] & ~_ignoreMask;
  }

  function allocatedByPool(
    address holder,
    uint256 allocated,
    uint32 since,
    AllocationMode mode
  ) external override {
    uint256 poolMask = _poolMask[msg.sender];
    require(poolMask != 0, 'unknown pool');

    if (allocated > 0) {
      internalAllocatedByPool(holder, allocated, msg.sender, since);
      emit RewardsAllocated(holder, allocated, msg.sender);
    }

    if (mode == AllocationMode.Push) {
      return;
    }

    uint256 pullMask = _memberOf[holder];
    if (mode == AllocationMode.UnsetPull) {
      if (pullMask & poolMask != 0) {
        _memberOf[holder] = pullMask & ~poolMask;
      }
    } else {
      if (pullMask & poolMask != poolMask) {
        _memberOf[holder] = pullMask | poolMask;
      }
    }
  }

  function isRateAdmin(address addr) public view override returns (bool) {
    if (!hasRemoteAcl()) {
      return addr == address(this);
    }
    return acl_hasAnyOf(addr, AccessFlags.REWARD_RATE_ADMIN | AccessFlags.REWARD_CONFIGURATOR);
  }

  function _onlyRateAdmin() private view {
    require(isRateAdmin(msg.sender), Errors.CT_CALLER_MUST_BE_REWARD_RATE_ADMIN);
  }

  modifier onlyRateAdmin() {
    _onlyRateAdmin();
    _;
  }

  function isConfigAdmin(address addr) public view override returns (bool) {
    if (!hasRemoteAcl()) {
      return addr == address(this);
    }
    return acl_hasAnyOf(addr, AccessFlags.REWARD_CONFIGURATOR | AccessFlags.REWARD_CONFIG_ADMIN);
  }

  function _onlyConfigAdmin() private view {
    require(isConfigAdmin(msg.sender), Errors.CT_CALLER_MUST_BE_REWARD_ADMIN);
  }

  modifier onlyConfigAdmin() {
    _onlyConfigAdmin();
    _;
  }

  function _onlyConfigOrRateAdmin() private view {
    require(isConfigAdmin(msg.sender) || isRateAdmin(msg.sender), Errors.CT_CALLER_MUST_BE_REWARD_RATE_ADMIN);
  }

  modifier onlyConfigOrRateAdmin() {
    _onlyConfigOrRateAdmin();
    _;
  }

  function isEmergencyAdmin(address addr) public view override returns (bool) {
    if (!hasRemoteAcl()) {
      return addr == address(this);
    }
    return acl_hasAnyOf(addr, AccessFlags.EMERGENCY_ADMIN);
  }

  function getClaimMask(address holder, uint256 mask) internal view virtual returns (uint256) {
    mask &= ~_ignoreMask;
    mask &= _memberOf[holder];
    return mask;
  }

  function getPool(uint256 index) internal view returns (IManagedRewardPool) {
    return _poolList[index];
  }

  function _claimReward(
    address holder,
    uint256 mask,
    address receiver
  ) private returns (uint256 claimed, uint256 extra) {
    mask = getClaimMask(holder, mask);
    (claimed, extra) = internalClaimAndMintReward(holder, mask);

    if (claimed > 0) {
      extra += internalClaimed(holder, receiver, claimed);
      emit RewardsClaimed(holder, receiver, claimed);
    }
    return (claimed, extra);
  }

  function internalClaimed(
    address holder,
    address mintTo,
    uint256 amount
  ) internal virtual returns (uint256) {
    holder;
    internalMint(mintTo, amount, false);
    return 0;
  }

  function internalMint(
    address mintTo,
    uint256 amount,
    bool serviceAccount
  ) internal {
    _rewardMinter.mintReward(mintTo, amount, serviceAccount);
  }

  function internalClaimAndMintReward(address holder, uint256 mask)
    internal
    virtual
    returns (uint256 claimed, uint256 extra);

  function _calcReward(
    address holder,
    uint256 mask,
    uint32 at
  ) private view returns (uint256 claimableAmount, uint256 extraAmount) {
    mask = getClaimMask(holder, mask);
    return internalCalcClaimableReward(holder, mask, at);
  }

  function internalCalcClaimableReward(
    address holder,
    uint256 mask,
    uint32 at
  ) internal view virtual returns (uint256 claimableAmount, uint256 extraAmount);

  function internalAllocatedByPool(
    address holder,
    uint256 allocated,
    address pool,
    uint32 since
  ) internal virtual;

  function _notPaused() private view {
    require(!_paused, Errors.RW_REWARD_PAUSED);
  }

  modifier notPaused() {
    _notPaused();
    _;
  }

  function setPaused(bool paused) public override onlyEmergencyAdmin {
    _paused = paused;
    emit EmergencyPaused(msg.sender, paused);
  }

  function isPaused() public view override returns (bool) {
    return _paused;
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

  string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = '5'; // User cannot withdraw more than the available balance
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
  string public constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = '19'; // The underlying balance needs to be greater than 0
  string public constant VL_DEPOSIT_ALREADY_IN_USE = '20'; // User deposit is already being used as collateral
  string public constant VL_RESERVE_MUST_BE_COLLATERAL = '21';
  string public constant LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '22'; // Interest rate rebalance conditions were not met

  string public constant LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR = '27'; // The caller of the function is not the lending pool configurator

  string public constant CT_CALLER_MUST_BE_LENDING_POOL = '29'; // The caller of this function must be a lending pool

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

  string public constant CT_INVALID_BURN_AMOUNT = '58'; //invalid amount to burn
  string public constant BORROW_ALLOWANCE_NOT_ENOUGH = '59'; // User borrows on behalf, but allowance are too small

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
  string public constant CT_CALLER_MUST_BE_REWARD_ADMIN = '81'; // The caller of this function must be a reward admin
  string public constant LP_INVALID_PERCENTAGE = '82'; // Percentage can't be more than 100%
  string public constant LP_IS_NOT_TRUSTED_FLASHLOAN = '83';
  string public constant CT_CALLER_MUST_BE_SWEEP_ADMIN = '84';
  string public constant LP_TOO_MANY_NESTED_CALLS = '85';
  string public constant LP_RESTRICTED_FEATURE = '86';
  string public constant LP_TOO_MANY_FLASHLOAN_CALLS = '87';
  string public constant RW_BASELINE_EXCEEDED = '88';
  string public constant CT_CALLER_MUST_BE_REWARD_RATE_ADMIN = '89';
  string public constant CT_CALLER_MUST_BE_REWARD_CONTROLLER = '90';
  string public constant RW_REWARD_PAUSED = '91';
  string public constant CT_CALLER_MUST_BE_TEAM_MANAGER = '92';
  string public constant STK_REDEEM_PAUSED = '93';
  string public constant STK_INSUFFICIENT_COOLDOWN = '94';
  string public constant STK_UNSTAKE_WINDOW_FINISHED = '95';
  string public constant STK_INVALID_BALANCE_ON_COOLDOWN = '96';
  string public constant STK_EXCESSIVE_SLASH_PCT = '97';
  string public constant STK_EXCESSIVE_COOLDOWN_PERIOD = '98';
  string public constant STK_WRONG_UNSTAKE_PERIOD = '98';

  string public constant VL_INSUFFICIENT_REWARD_AVAILABLE = '99';

  string public constant TXT_OWNABLE_CALLER_NOT_OWNER = 'Ownable: caller is not the owner';
  string public constant TXT_CALLER_NOT_PROXY_OWNER = 'ProxyOwner: caller is not the owner';
  string public constant TXT_ACCESS_RESTRICTED = 'RESTRICTED';
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IBalanceHook {
  function handleBalanceUpdate(
    address token,
    address holder,
    uint256 oldBalance,
    uint256 newBalance,
    uint256 providerSupply
  ) external;

  function handleScaledBalanceUpdate(
    address token,
    address holder,
    uint256 oldBalance,
    uint256 newBalance,
    uint256 providerSupply,
    uint256 scaleRay
  ) external;

  function isScaledBalanceUpdateNeeded() external view returns (bool);
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

library BitUtils {
  function isBit(uint256 v, uint8 index) internal pure returns (bool) {
    return v & (uint256(1) << index) != 0;
  }

  function nextPowerOf2(uint256 v) internal pure returns (uint256) {
    if (v == 0) {
      return 1;
    }
    v--;
    v |= v >> 1;
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    v |= v >> 16;
    v |= v >> 32;
    v |= v >> 64;
    v |= v >> 128;
    return v + 1;
  }

  function isPowerOf2(uint256 v) internal pure returns (bool) {
    return (v & (v - 1)) == 0;
  }

  function isPowerOf2nz(uint256 v) internal pure returns (bool) {
    if (v == 0) {
      return false;
    }
    return (v & (v - 1)) == 0;
  }

  function bitLength(uint256 v) internal pure returns (uint256 len) {
    if (v == 0) {
      return 0;
    }
    if (v > type(uint128).max) {
      v >>= 128;
      len += 128;
    }
    if (v > type(uint64).max) {
      v >>= 64;
      len += 64;
    }
    if (v > type(uint32).max) {
      v >>= 32;
      len += 32;
    }
    if (v > type(uint16).max) {
      v >>= 16;
      len += 16;
    }
    if (v > type(uint8).max) {
      v >>= 8;
      len += 8;
    }
    if (v > 15) {
      v >>= 4;
      len += 4;
    }
    if (v > 3) {
      v >>= 2;
      len += 2;
    }
    if (v > 1) {
      len += 1;
    }
    return len;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/Errors.sol';
import './interfaces/IMarketAccessController.sol';
import './AccessHelper.sol';
import './AccessFlags.sol';

// solhint-disable func-name-mixedcase
abstract contract MarketAccessBitmask {
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

  modifier onlyEmergencyAdmin() {
    _remoteAcl.requireAnyOf(msg.sender, AccessFlags.EMERGENCY_ADMIN, Errors.CALLER_NOT_EMERGENCY_ADMIN);
    _;
  }

  modifier onlySweepAdmin() {
    _remoteAcl.requireAnyOf(msg.sender, AccessFlags.SWEEP_ADMIN, Errors.CT_CALLER_MUST_BE_SWEEP_ADMIN);
    _;
  }

  modifier onlyRewardAdmin() {
    _remoteAcl.requireAnyOf(msg.sender, AccessFlags.REWARD_CONFIG_ADMIN, Errors.CT_CALLER_MUST_BE_REWARD_ADMIN);
    _;
  }

  modifier onlyRewardConfiguratorOrAdmin() {
    _remoteAcl.requireAnyOf(
      msg.sender,
      AccessFlags.REWARD_CONFIG_ADMIN | AccessFlags.REWARD_CONFIGURATOR,
      Errors.CT_CALLER_MUST_BE_REWARD_ADMIN
    );
    _;
  }

  modifier onlyRewardRateAdmin() {
    _remoteAcl.requireAnyOf(msg.sender, AccessFlags.REWARD_RATE_ADMIN, Errors.CT_CALLER_MUST_BE_REWARD_RATE_ADMIN);
    _;
  }
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

import '../../interfaces/IRewardMinter.sol';
import '../../interfaces/IEmergencyAccess.sol';
import '../../access/interfaces/IMarketAccessController.sol';
import './IManagedRewardPool.sol';
import './IRewardController.sol';

interface IManagedRewardController is IEmergencyAccess, IRewardController {
  function updateBaseline(uint256 baseline) external returns (uint256 totalRate);

  function addRewardPool(IManagedRewardPool) external;

  function removeRewardPool(IManagedRewardPool) external;

  function setRewardMinter(IRewardMinter) external;

  function getPools() external view returns (IManagedRewardPool[] memory, uint256 ignoreMask);

  event RewardsAllocated(address indexed user, uint256 amount, address indexed fromPool);
  event RewardsClaimed(address indexed user, address indexed to, uint256 amount);

  event BaselineUpdated(uint256 baseline, uint256 totalRate, uint256 mask);
  event RewardPoolAdded(address indexed pool, uint256 mask);
  event RewardPoolRemoved(address indexed pool, uint256 mask);
  event RewardMinterSet(address minter);
}

interface IManagedRewardBooster is IManagedRewardController {
  function setBoostFactor(address pool, uint32 pctFactor) external;

  function setUpdateBoostPoolRate(bool) external;

  function setBoostPool(address) external;

  function getBoostPool() external view returns (address pool, uint256 mask);

  function setBoostExcessTarget(address target, bool mintExcess) external;

  event BoostFactorSet(address indexed pool, uint256 mask, uint32 pctFactor);
}

interface IUntypedRewardControllerPools {
  function getPools() external view returns (address[] memory, uint256 ignoreMask);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IRewardCollector {
  /// @dev claims rewards of the caller and transfers to the caller
  /// @return claimed amount of rewards
  /// @return locked amount is portion of rewards that was locked
  function claimReward() external returns (uint256 claimed, uint256 locked);

  /// @dev claims rewards of the caller and transfers to the receiver
  /// @return claimed amount of rewards
  /// @return locked amount is portion of rewards that was locked (on the receiver)
  function claimRewardTo(address receiver) external returns (uint256 claimed, uint256 locked);

  /// @dev calculates rewards of the caller
  /// @return claimable amount of rewards, it matches the claimed amount returned by claimReward()
  /// @return frozen amount rewards that was allocated, but will be released gradually (doesn't math the locked reward)
  function claimableReward(address holder) external view returns (uint256 claimable, uint256 frozen);

  /// @dev calculates rewards of the caller. Returns (claimable + frozen) amounts of claimableReward()
  function balanceOf(address holder) external view returns (uint256);
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

