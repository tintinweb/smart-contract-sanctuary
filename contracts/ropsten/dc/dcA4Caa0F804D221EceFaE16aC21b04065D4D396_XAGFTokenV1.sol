// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import '../access/AccessFlags.sol';
import '../access/interfaces/IMarketAccessController.sol';

import './locker/DecayingTokenLocker.sol';
import '../tools/upgradeability/VersionedInitializable.sol';
import './interfaces/IInitializableRewardToken.sol';
import '../access/interfaces/IRemoteAccessBitmask.sol';
import './interfaces/IRewardController.sol';
import '../tools/math/WadRayMath.sol';

contract XAGFTokenV1 is IInitializableRewardToken, DecayingTokenLocker, VersionedInitializable {
  string internal constant NAME = 'Augmented Finance Locked Reward Token';
  string internal constant SYMBOL = 'xAGF';
  uint8 internal constant DECIMALS = 18;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  uint256 private constant TOKEN_REVISION = 1;

  constructor() public DecayingTokenLocker(IRewardController(address(this)), 0, 0, address(0)) {
    _initializeERC20(NAME, SYMBOL, DECIMALS);
  }

  function _initializeERC20(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) internal {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function getRevision() internal pure virtual override returns (uint256) {
    return TOKEN_REVISION;
  }

  function getPoolName() public view override returns (string memory) {
    return _symbol;
  }

  // This initializer is invoked by AccessController.setAddressAsImpl
  function initialize(IMarketAccessController ac) external virtual initializer(TOKEN_REVISION) {
    address controller = ac.getAddress(AccessFlags.REWARD_CONTROLLER);
    address underlying = ac.getAddress(AccessFlags.REWARD_TOKEN);

    _initializeERC20(NAME, SYMBOL, DECIMALS);
    super._initialize(underlying);
    super._initialize(IRewardController(controller), 0, 0);
  }

  function initialize(InitData calldata data)
    external
    virtual
    override
    initializer(TOKEN_REVISION)
  {
    IMarketAccessController ac = IMarketAccessController(address(data.remoteAcl));
    address controller = ac.getAddress(AccessFlags.REWARD_CONTROLLER);
    address underlying = ac.getAddress(AccessFlags.REWARD_TOKEN);

    _initializeERC20(data.name, data.symbol, data.decimals);
    super._initialize(underlying);
    super._initialize(IRewardController(controller), 0, 0);
  }

  function initializeToken(
    IMarketAccessController remoteAcl,
    address underlying,
    string calldata name_,
    string calldata symbol_,
    uint8 decimals_
  ) public virtual initializer(TOKEN_REVISION) {
    address controller = remoteAcl.getAddress(AccessFlags.REWARD_CONTROLLER);

    _initializeERC20(name_, symbol_, decimals_);
    super._initialize(underlying);
    super._initialize(IRewardController(controller), 0, 0);
  }

  function initializePool(
    IRewardController controller,
    address underlying,
    uint256 initialRate,
    uint16 baselinePercentage
  ) public virtual initializer(TOKEN_REVISION) {
    _initializeERC20(NAME, SYMBOL, DECIMALS);
    super._initialize(underlying);
    super._initialize(controller, initialRate, baselinePercentage);
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

  uint256 public constant REWARD_MINT = 1 << 64;
  uint256 public constant REWARD_BURN = 1 << 65;

  uint256 public constant POOL_SPONSORED_LOAN_USER = 1 << 66;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IAccessController.sol';

/// @dev Main registry of addresses part of or connected to the protocol, including permissioned roles. Also acts a proxy factory.
interface IMarketAccessController is IAccessController {
  function getMarketId() external view returns (string memory);

  function getLendingPool() external view returns (address);

  function isPoolAdmin(address) external view returns (bool);

  function getPriceOracle() external view returns (address);

  function getLendingRateOracle() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import '../../dependencies/openzeppelin/contracts/SafeMath.sol';
import '../../tools/math/WadRayMath.sol';
import '../interfaces/IRewardController.sol';
import './RewardedTokenLocker.sol';

contract DecayingTokenLocker is RewardedTokenLocker {
  using SafeMath for uint256;
  using WadRayMath for uint256;
  
  constructor(
    IRewardController controller,
    uint256 initialRate,
    uint16 baselinePercentage,
    address underlying
  ) RewardedTokenLocker(controller, initialRate, baselinePercentage, underlying) {}

  function balanceOf(address account) public view virtual override returns (uint256) {
    (uint32 startTS, uint32 endTS) = expiryOf(account);
    uint32 current = getCurrentTick();
    if (current >= endTS) {
      return 0;
    }

    uint256 stakeAmount = getStakeBalance(account);
    uint256 stakeDecayed = stakeAmount.mul(endTS - current).div(endTS - startTS);

    if (stakeDecayed >= stakeAmount) {
      return stakeAmount;
    }
    return stakeDecayed;
  }

  function internalCalcReward(address holder, uint32 current)
    internal
    view
    override
    returns (uint256 amount, uint32 since)
  {
    (uint32 startTS, uint32 endTS) = expiryOf(holder);
    if (endTS == 0) {
      return (0, 0);
    }

    uint256 stakeAmount;
    if (current >= endTS) {
      // this is to emulate claimReward using calcCompensatedDecay when a balance has expired
      stakeAmount = getStakeBalance(holder);
      current = endTS;
    }

    (amount, since) = super.doCalcRewardAt(holder, current);
    if (amount == 0) {
      return (0, 0);
    }

    uint256 decayAmount = amount.rayMul(calcDecayForReward(startTS, endTS, since, current));

    amount =
      amount -
      calcCompensatedDecay(
        holder,
        decayAmount,
        stakeAmount,
        totalSupply(),
        calcDecayTimeCompensation(startTS, endTS, since, current)
      );

    if (amount == 0) {
      return (0, 0);
    }

    return (amount, since);
  }

  function internalGetReward(address holder, uint256 limit)
    internal
    virtual
    override
    returns (uint256 amount, uint32 since)
  {
    internalUpdate(true, 0);

    (uint32 startTS, uint32 endTS) = expiryOf(holder);
    if (endTS == 0) {
      return (0, 0);
    }

    uint256 stakeAmount; // cached value as it may not be available after removal

    uint256 maxAmount;
    uint32 current = getCurrentTick();
    if (current >= endTS) {
      current = endTS;
      (maxAmount, since) = super.doGetRewardAt(holder, current);
      stakeAmount = super.internalRemoveReward(holder);
    } else {
      (maxAmount, since) = super.doGetRewardAt(holder, current);
    }

    if (maxAmount == 0) {
      return (0, 0);
    }

    uint256 decayAmount = maxAmount.rayMul(calcDecayForReward(startTS, endTS, since, current));

    if (limit <= maxAmount && limit + decayAmount <= maxAmount) {
      amount = limit;
    } else {
      amount =
        maxAmount -
        calcCompensatedDecay(
          holder,
          decayAmount,
          stakeAmount,
          internalCurrentTotalSupply(),
          calcDecayTimeCompensation(startTS, endTS, since, current)
        );

      if (amount > limit) {
        amount = limit;
      }
    }

    if (maxAmount > amount) {
      internalAddExcess(maxAmount - amount, since);
    }

    if (amount == 0) {
      return (0, 0);
    }

    return (amount, since);
  }

  function setStakeBalance(address holder, uint224 stakeAmount) internal override {
    // NB! Actually, total and balance for decay compensation should be taken before the update.
    // Not doing it will give more to a user who increases balance - so it is better.

    (uint256 amount, uint32 since, AllocationMode mode) =
      doUpdateReward(
        holder,
        0, /* doesn't matter */
        stakeAmount
      );

    amount = rewardForBalance(holder, stakeAmount, amount, since, uint32(block.timestamp));
    internalAllocateReward(holder, amount, since, mode);
  }

  function unsetStakeBalance(
    address holder,
    uint32 at,
    bool interim
  ) internal override {
    (uint256 amount, uint32 since) = doGetRewardAt(holder, at);
    uint256 stakeAmount = internalRemoveReward(holder);
    AllocationMode mode = AllocationMode.Push;

    if (!interim) {
      mode = AllocationMode.UnsetPull;
    } else if (amount == 0) {
      return;
    }

    amount = rewardForBalance(holder, stakeAmount, amount, since, at);
    internalAllocateReward(holder, amount, since, mode);
  }

  function rewardForBalance(
    address holder,
    uint256 stakeAmount,
    uint256 amount,
    uint32 since,
    uint32 at
  ) private returns (uint256) {
    if (amount == 0) {
      return 0;
    }
    (uint32 startTS, uint32 endTS) = expiryOf(holder);

    uint256 maxAmount = amount;
    uint256 decayAmount = maxAmount.rayMul(calcDecayForReward(startTS, endTS, since, at));

    amount =
      maxAmount -
      calcCompensatedDecay(
        holder,
        decayAmount,
        stakeAmount,
        internalCurrentTotalSupply(),
        calcDecayTimeCompensation(startTS, endTS, since, at)
      );

    if (maxAmount > amount) {
      internalAddExcess(maxAmount - amount, since);
    }

    return amount;
  }

  /// @notice Calculates a range integral of the linear decay
  /// @param startTS start of the decay interval (beginning of a lock)
  /// @param endTS start of the decay interval (ending of a lock)
  /// @param since start of an integration range
  /// @param current end of an integration range
  /// @return Decayed portion [RAY..0] of reward, result = 0 means no decay
  function calcDecayForReward(
    uint32 startTS,
    uint32 endTS,
    uint32 since,
    uint32 current
  ) public pure returns (uint256) {
    require(startTS > 0);
    require(startTS < endTS);
    require(startTS <= since);
    require(current <= endTS);
    require(since <= current);
    return
      ((uint256(since - startTS) + (current - startTS)) * WadRayMath.halfRAY) / (endTS - startTS);
  }

  /// @notice Calculates an approximate decay compensation to equalize outcomes from multiple intermediate claims vs one final claim due to excess redistribution
  /// @dev There is no checks as it is invoked only after calcDecayForReward
  /// @param startTS start of the decay interval (beginning of a lock)
  /// @param endTS start of the decay interval (ending of a lock)
  /// @param since timestamp of a previous claim or start of the decay interval
  /// @param current timestamp of a new claim
  /// @return Compensation portion [RAY..0] of reward, result = 0 means no compensation
  function calcDecayTimeCompensation(
    uint32 startTS,
    uint32 endTS,
    uint32 since,
    uint32 current
  ) public pure returns (uint256) {
    // parabolic approximation
    return ((uint256(current - since)**2) * WadRayMath.RAY) / (uint256(endTS - startTS)**2);
  }

  function calcCompensatedDecay(
    address holder,
    uint256 decayAmount,
    uint256 stakeAmount,
    uint256 stakedTotal,
    uint256 compensationRatio
  ) public view returns (uint256) {
    if (decayAmount == 0 || compensationRatio == 0) {
      return decayAmount;
    }

    if (stakeAmount == 0) {
      // is included into the total
      stakeAmount = getStakeBalance(holder);
    } else {
      // is excluded from the total
      stakedTotal += stakeAmount;
    }

    if (stakedTotal > stakeAmount) {
      compensationRatio = (compensationRatio * stakeAmount) / stakedTotal;
    }

    if (compensationRatio >= WadRayMath.RAY) {
      return 0;
    }

    return decayAmount.rayMul(WadRayMath.RAY - compensationRatio);
  }
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
      require(
        initializing || isConstructor() || topRevision > lastInitializedRevision,
        'already initialized'
      );
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
    //solium-disable-next-line
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
pragma experimental ABIEncoderV2;

import '../../access/interfaces/IMarketAccessController.sol';

interface IInitializableRewardToken {
  struct InitData {
    IMarketAccessController remoteAcl;
    string name;
    string symbol;
    uint8 decimals;
  }

  function initialize(InitData memory) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IRemoteAccessBitmask {
  /**
   * @dev Returns access flags granted to the given address and limited by the filterMask. filterMask == 0 has a special meaning.
   * @param addr an to get access perfmissions for
   * @param filterMask limits a subset of flags to be checked. NB! When filterMask == 0 then zero is returned no flags granted, or an unspecified non-zero value otherwise.
   * @return Access flags currently granted
   */
  function queryAccessControlMask(address addr, uint256 filterMask) external view returns (uint256);
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
  function wadToRay(uint256 a) internal pure returns (uint256 result) {
    result = a * WAD_RAY_RATIO;
    require(result / WAD_RAY_RATIO == a, Errors.MATH_MULTIPLICATION_OVERFLOW);
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

interface IProxy {
  function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/// @dev Wrappers over Solidity's arithmetic operations with added overflow checks.
library SafeMath {
  /// @dev Returns the addition of two unsigned integers, reverting on overflow.
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a, 'SafeMath: addition overflow');
  }

  /// @dev Returns the subtraction of two unsigned integers, reverting on overflow (when the result is negative).
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  /// @dev Returns the subtraction of two unsigned integers, reverting with custom message on overflow (when the result is negative).
  function sub(
    uint256 a,
    uint256 b,
    string memory errMsg
  ) internal pure returns (uint256) {
    require(b <= a, errMsg);
    return a - b;
  }

  /// @dev Returns the multiplication of two unsigned integers, reverting on overflow.
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }
    c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');
  }

  /// @dev Returns the integer division of two unsigned integers. Reverts on division by zero. The result is rounded towards zero.
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  /// @dev Returns the integer division of two unsigned integers. Reverts with custom message on division by zero. The result is rounded towards zero.
  function div(
    uint256 a,
    uint256 b,
    string memory errMsg
  ) internal pure returns (uint256 c) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errMsg);
    c = a / b;
  }

  /// @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo), Reverts when dividing by zero.
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  /// @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo), Reverts with custom message when dividing by zero.
  function mod(
    uint256 a,
    uint256 b,
    string memory errMsg
  ) internal pure returns (uint256) {
    require(b != 0, errMsg);
    return a % b;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import '../interfaces/IBoostRate.sol';
import '../interfaces/IBoostExcessReceiver.sol';
import '../interfaces/IRewardController.sol';
import '../interfaces/IAutolocker.sol';
import '../pools/ControlledRewardPool.sol';
import '../calcs/CalcCheckpointWeightedReward.sol';
import './BaseTokenLocker.sol';

contract RewardedTokenLocker is
  BaseTokenLocker,
  ControlledRewardPool,
  CalcCheckpointWeightedReward,
  IBoostExcessReceiver,
  IBoostRate,
  IAutolocker
{
  constructor(
    IRewardController controller,
    uint256 initialRate,
    uint16 baselinePercentage,
    address underlying
  )
    CalcCheckpointWeightedReward()
    BaseTokenLocker(underlying)
    ControlledRewardPool(controller, initialRate, baselinePercentage)
  {}

  function redeem(address to) public override notPaused returns (uint256 underlyingAmount) {
    return super.redeem(to);
  }

  function isRedeemable() external view returns (bool) {
    return !isPaused();
  }

  function addRewardProvider(address, address) external override onlyConfigAdmin {
    revert('UNSUPPORTED');
  }

  function removeRewardProvider(address) external override onlyConfigAdmin {}

  function internalSyncRate(uint32 at) internal override {
    doSyncRateAt(at);
  }

  function internalCheckpoint(uint32 at) internal override {
    doCheckpoint(at);
  }

  function setStakeBalance(address holder, uint224 stakeAmount) internal virtual override {
    (uint256 amount, uint32 since, AllocationMode mode) =
      doUpdateReward(
        holder,
        0, /* doesn't matter */
        stakeAmount
      );
    internalAllocateReward(holder, amount, since, mode);
  }

  function unsetStakeBalance(
    address holder,
    uint32 at,
    bool interim
  ) internal virtual override {
    (uint256 amount, uint32 since) = doGetRewardAt(holder, at);
    internalRemoveReward(holder);
    AllocationMode mode = AllocationMode.Push;

    if (!interim) {
      mode = AllocationMode.UnsetPull;
    } else if (amount == 0) {
      return;
    }
    internalAllocateReward(holder, amount, since, mode);
  }

  function getStakeBalance(address holder) internal view override returns (uint224) {
    return getRewardEntry(holder).rewardBase;
  }

  function isHistory(uint32 at) internal view override returns (bool) {
    return isCompletedPast(at);
  }

  function internalExtraRate() internal view override returns (uint256) {
    return getExtraRate();
  }

  function internalTotalSupply() internal view override returns (uint256) {
    return getStakedTotal();
  }

  function balanceOf(address account) public view virtual override returns (uint256 stakeAmount) {
    (, uint32 expiry) = expiryOf(account);
    if (getCurrentTick() >= expiry) {
      return 0;
    }
    return getStakeBalance(account);
  }

  function internalCalcReward(address holder, uint32 current)
    internal
    view
    virtual
    override
    returns (uint256 amount, uint32 since)
  {
    (, uint32 expiry) = expiryOf(holder);
    if (expiry == 0) {
      return (0, 0);
    }
    if (current > expiry) {
      current = expiry;
    }
    return doCalcRewardAt(holder, current);
  }

  function internalGetReward(address holder, uint256 limit)
    internal
    virtual
    override
    returns (uint256 amount, uint32 since)
  {
    internalUpdate(true, 0);

    (, uint32 expiry) = expiryOf(holder);
    if (expiry == 0) {
      return (0, 0);
    }
    uint32 current = getCurrentTick();
    if (current < expiry) {
      (amount, since) = doGetRewardAt(holder, current);
    } else {
      (amount, since) = doGetRewardAt(holder, expiry);
      internalRemoveReward(holder);
    }

    if (amount > limit) {
      internalAddExcess(amount - limit, since);
      return (limit, since);
    }
    return (amount, since);
  }

  function internalGetRate() internal view override returns (uint256) {
    return getLinearRate();
  }

  function internalSetRate(uint256 rate) internal override {
    internalUpdate(false, 0);
    setLinearRate(rate);
  }

  function getCurrentTick() internal view override returns (uint32) {
    return uint32(block.timestamp);
  }

  function setBoostRate(uint256 rate) external override onlyController {
    _setRate(rate);
  }

  function receiveBoostExcess(uint256 amount, uint32 since) external override onlyController {
    internalUpdate(false, 0);
    internalAddExcess(amount, since);
  }

  function applyAutolock(
    address account,
    uint256 amount,
    AutolockMode mode,
    uint32 lockDuration,
    uint224 param
  )
    external
    override
    onlyController
    returns (
      address, /* receiver */
      uint256, /* lockAmount */
      bool stop
    )
  {
    uint256 recoverableError;
    if (mode == AutolockMode.Prolongate) {
      // full amount is locked
    } else if (mode == AutolockMode.AccumulateTill) {
      // full amount is locked
      if (block.timestamp >= param) {
        stop = true;
        amount = 0;
      }
    } else if (mode == AutolockMode.AccumulateUnderlying) {
      (amount, stop) = calcAutolockUnderlying(amount, balanceOfUnderlying(account), param);
    } else if (mode == AutolockMode.KeepUpBalance) {
      if (lockDuration == 0) {
        // shouldn't happen
        stop = true;
        amount = 0;
      } else {
        // it never stops unless the lock expires
        amount = calcAutolockKeepUp(amount, balanceOf(account), param, lockDuration);
      }
    } else {
      return (address(0), 0, false);
    }

    if (amount == 0) {
      return (address(0), 0, stop);
    }

    // NB! the tokens are NOT received here and must be minted to this locker directly
    (, recoverableError) = internalLock(address(this), account, amount, lockDuration, 0, false);

    if (recoverableError != 0) {
      emit RewardAutolockFailed(account, mode, recoverableError);
      return (address(0), 0, true);
    }

    return (address(this), amount, stop);
  }

  function calcAutolockUnderlying(
    uint256 amount,
    uint256 balance,
    uint256 limit
  ) private pure returns (uint256, bool) {
    if (balance >= limit) {
      return (0, true);
    }
    limit -= balance;

    if (amount > limit) {
      return (limit, true);
    }
    return (amount, amount == limit);
  }

  function calcAutolockKeepUp(
    uint256 amount,
    uint256 balance,
    uint256 limit,
    uint32 lockDuration
  ) private view returns (uint256) {
    this;
    if (balance >= limit) {
      return 0;
    }

    limit = convertLockedToUnderlying(limit - balance, lockDuration);

    if (amount > limit) {
      return limit;
    }
    return amount;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @title Errors library
 * @author Aave
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
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
  string public constant VL_CURRENT_AVAILABLE_LIQUIDITY_NOT_ENOUGH = '4'; // The current liquidity is not enough
  string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = '5'; // User cannot withdraw more than the available balance
  string public constant VL_TRANSFER_NOT_ALLOWED = '6'; // Transfer cannot be allowed.
  string public constant VL_BORROWING_NOT_ENABLED = '7'; // Borrowing is not enabled
  string public constant VL_INVALID_INTEREST_RATE_MODE_SELECTED = '8'; // Invalid interest rate mode selected
  string public constant VL_COLLATERAL_BALANCE_IS_0 = '9'; // The collateral balance is 0
  string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = '10'; // Health factor is lesser than the liquidation threshold
  string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = '11'; // There is not enough collateral to cover a new borrow
  string public constant VL_STABLE_BORROWING_NOT_ENABLED = '12'; // stable borrowing not enabled
  string public constant VL_COLLATERAL_SAME_AS_BORROWING_CURRENCY = '13'; // collateral is (mostly) the same currency that is being borrowed
  string public constant VL_AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = '14'; // The requested amount is greater than the max loan size in stable rate mode
  string public constant VL_NO_DEBT_OF_SELECTED_TYPE = '15'; // for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt
  string public constant VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = '16'; // To repay on behalf of an user an explicit amount to repay is needed
  string public constant VL_NO_STABLE_RATE_LOAN_IN_RESERVE = '17'; // User does not have a stable rate loan in progress on this reserve
  string public constant VL_NO_VARIABLE_RATE_LOAN_IN_RESERVE = '18'; // User does not have a variable rate loan in progress on this reserve
  string public constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = '19'; // The underlying balance needs to be greater than 0
  string public constant VL_DEPOSIT_ALREADY_IN_USE = '20'; // User deposit is already being used as collateral
  string public constant LP_NOT_ENOUGH_STABLE_BORROW_BALANCE = '21'; // User does not have any stable rate loan for this reserve
  string public constant LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '22'; // Interest rate rebalance conditions were not met
  //  string public constant LP_LIQUIDATION_CALL_FAILED = '23'; // Liquidation call failed
  string public constant LP_NOT_ENOUGH_LIQUIDITY_TO_BORROW = '24'; // There is not enough liquidity available to borrow
  string public constant LP_REQUESTED_AMOUNT_TOO_SMALL = '25'; // The requested amount is too small for a FlashLoan.
  string public constant LP_INCONSISTENT_PROTOCOL_ACTUAL_BALANCE = '26'; // The actual balance of the protocol is inconsistent
  string public constant LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR = '27'; // The caller of the function is not the lending pool configurator
  string public constant LP_INCONSISTENT_FLASHLOAN_PARAMS = '28';
  string public constant CT_CALLER_MUST_BE_LENDING_POOL = '29'; // The caller of this function must be a lending pool
  string public constant CT_CANNOT_GIVE_ALLOWANCE_TO_HIMSELF = '30'; // User cannot give allowance to himself
  string public constant CT_TRANSFER_AMOUNT_NOT_GT_0 = '31'; // Transferred amount needs to be greater than zero
  string public constant RL_RESERVE_ALREADY_INITIALIZED = '32'; // Reserve has already been initialized
  string public constant CALLER_NOT_POOL_ADMIN = '33'; // The caller must be the pool admin
  string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = '34'; // The liquidity of the reserve needs to be 0
  string public constant LPC_INVALID_ATOKEN_POOL_ADDRESS = '35'; // The liquidity of the reserve needs to be 0
  string public constant LPC_INVALID_STABLE_DEBT_TOKEN_POOL_ADDRESS = '36'; // The liquidity of the reserve needs to be 0
  string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_POOL_ADDRESS = '37'; // The liquidity of the reserve needs to be 0
  string public constant LPC_INVALID_STABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = '38'; // The liquidity of the reserve needs to be 0
  string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = '39'; // The liquidity of the reserve needs to be 0
  string public constant LPC_INVALID_ADDRESSES_PROVIDER_ID = '40'; // The liquidity of the reserve needs to be 0
  string public constant LPAPR_PROVIDER_NOT_REGISTERED = '41'; // Provider is not registered
  string public constant LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '42'; // Health factor is not below the threshold
  string public constant LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED = '43'; // The collateral chosen cannot be liquidated
  string public constant LPCM_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = '44'; // User did not borrow the specified currency
  string public constant LPCM_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE = '45'; // There isn't enough liquidity available to liquidate
  //  string public constant LPCM_NO_ERRORS = '46'; // No errors
  string public constant LP_INVALID_FLASHLOAN_MODE = '47'; //Invalid flashloan mode selected
  string public constant MATH_MULTIPLICATION_OVERFLOW = '48';
  string public constant MATH_ADDITION_OVERFLOW = '49';
  string public constant MATH_DIVISION_BY_ZERO = '50';
  string public constant RL_LIQUIDITY_INDEX_OVERFLOW = '51'; //  Liquidity index overflows uint128
  string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = '52'; //  Variable borrow index overflows uint128
  string public constant RL_LIQUIDITY_RATE_OVERFLOW = '53'; //  Liquidity rate overflows uint128
  string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = '54'; //  Variable borrow rate overflows uint128
  string public constant RL_STABLE_BORROW_RATE_OVERFLOW = '55'; //  Stable borrow rate overflows uint128
  string public constant CT_INVALID_MINT_AMOUNT = '56'; //invalid amount to mint
  string public constant LP_FAILED_REPAY_WITH_COLLATERAL = '57';
  string public constant CT_INVALID_BURN_AMOUNT = '58'; //invalid amount to burn
  string public constant BORROW_ALLOWANCE_NOT_ENOUGH = '59'; // User borrows on behalf, but allowance are too small
  string public constant LP_FAILED_COLLATERAL_SWAP = '60';
  string public constant LP_INVALID_EQUAL_ASSETS_TO_SWAP = '61';
  string public constant LP_REENTRANCY_NOT_ALLOWED = '62';
  string public constant LP_CALLER_MUST_BE_AN_ATOKEN = '63';
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
  string public constant LP_INCONSISTENT_PARAMS_LENGTH = '74';
  string public constant LPC_INVALID_CONFIGURATION = '75'; // Invalid risk parameters for the reserve
  string public constant CALLER_NOT_EMERGENCY_ADMIN = '76'; // The caller must be the emergency admin
  string public constant UL_INVALID_INDEX = '77';
  string public constant VL_CONTRACT_REQUIRED = '78';
  string public constant SDT_STABLE_DEBT_OVERFLOW = '79';
  string public constant SDT_BURN_EXCEEDS_BALANCE = '80';
  string public constant CT_CALLER_MUST_BE_REWARD_ADMIN = '81'; // The caller of this function must be a reward admin
  string public constant LP_INVALID_PERCENTAGE = '82'; // Percentage can't be more than 100%
  string public constant LP_IS_NOT_SPONSORED_LOAN = '83';
  string public constant CT_CALLER_MUST_BE_SWEEP_ADMIN = '84';
  string public constant LP_TOO_MANY_NESTED_CALLS = '85';
  string public constant LP_RESTRICTED_FEATURE = '86';

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

  string public constant TXT_OWNABLE_CALLER_NOT_OWNER = 'Ownable: caller is not the owner';
  string public constant TXT_CALLER_NOT_PROXY_OWNER = 'ProxyOwner: caller is not the owner';
  string public constant TXT_ACCESS_RESTRICTED = 'RESTRICTED';
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IBoostRate {
  function setBoostRate(uint256 rate) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IBoostExcessReceiver {
  function receiveBoostExcess(uint256 amount, uint32 since) external;
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

import '../../dependencies/openzeppelin/contracts/SafeMath.sol';
import '../../tools/math/WadRayMath.sol';
import '../../tools/math/PercentageMath.sol';
import '../interfaces/IRewardController.sol';
import '../interfaces/IManagedRewardPool.sol';
import '../../access/AccessFlags.sol';
import '../../access/AccessHelper.sol';
import '../../tools/Errors.sol';

abstract contract ControlledRewardPool is IManagedRewardPool {
  using SafeMath for uint256;
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  uint16 internal constant NO_BASELINE = type(uint16).max;

  IRewardController internal _controller;

  uint256 private _pausedRate;
  uint16 private _baselinePercentage;
  bool private _paused;

  constructor(
    IRewardController controller,
    uint256 initialRate,
    uint16 baselinePercentage
  ) {
    _initialize(controller, initialRate, baselinePercentage);
  }

  function _initialize(
    IRewardController controller,
    uint256 initialRate,
    uint16 baselinePercentage
  ) internal virtual {
    require(address(controller) != address(0), 'controller is required');
    _controller = controller;

    if (baselinePercentage == NO_BASELINE || (initialRate != 0 && baselinePercentage == 0)) {
      _baselinePercentage = NO_BASELINE;
      emit BaselineDisabled();
    } else if (baselinePercentage > 0) {
      internalSetBaselinePercentage(baselinePercentage);
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
    if (_baselinePercentage == NO_BASELINE) {
      return (false, internalGetRate());
    }
    appliedRate = baseline.percentMul(_baselinePercentage);
    _setRate(appliedRate);
    return (true, appliedRate);
  }

  function disableBaseline() external override onlyRateAdmin {
    _baselinePercentage = NO_BASELINE;
    emit BaselineDisabled();
  }

  function disableRewardPool() external override onlyRateAdmin {
    _baselinePercentage = NO_BASELINE;
    _pausedRate = 0;
    internalSetRate(0);
    emit BaselineDisabled();
    emit RateUpdated(0);
  }

  function setBaselinePercentage(uint16 factor) external override onlyRateAdmin {
    internalSetBaselinePercentage(factor);
  }

  function getBaselinePercentage() external view override returns (bool, uint16) {
    if (_baselinePercentage == NO_BASELINE) {
      return (false, 0);
    }
    return (true, _baselinePercentage);
  }

  function internalGetBaselinePercentage() internal view returns (uint16) {
    return _baselinePercentage;
  }

  function internalSetBaselinePercentage(uint16 factor) internal virtual {
    require(factor <= PercentageMath.ONE, 'illegal value');
    _baselinePercentage = factor;
    emit BaselineFactorUpdated(factor);
  }

  function setRate(uint256 rate) external override onlyRateAdmin {
    _setRate(rate);
  }

  function _setRate(uint256 rate) internal {
    if (isPaused()) {
      _pausedRate = rate;
      return;
    }
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

  function internalPause(bool paused) internal virtual {
    if (paused) {
      _pausedRate = internalGetRate();
      internalSetRate(0);
      return;
    }
    internalSetRate(_pausedRate);
  }

  function getRewardController() public view override returns (address) {
    return address(_controller);
  }

  function claimRewardFor(address holder, uint256 limit)
    external
    override
    onlyController
    returns (uint256, uint32)
  {
    return internalGetReward(holder, limit);
  }

  function calcRewardFor(address holder, uint32 at)
    external
    view
    override
    returns (uint256, uint32)
  {
    require(at >= uint32(block.timestamp));
    return internalCalcReward(holder, at);
  }

  function internalAllocateReward(
    address holder,
    uint256 allocated,
    uint32 since,
    AllocationMode mode
  ) internal {
    _controller.allocatedByPool(holder, allocated, since, mode);
  }

  function internalGetReward(address holder, uint256 limit)
    internal
    virtual
    returns (uint256, uint32);

  function internalCalcReward(address holder, uint32 at)
    internal
    view
    virtual
    returns (uint256, uint32);

  function attachedToRewardController() external override onlyController {
    internalAttachedToRewardController();
  }

  function internalAttachedToRewardController() internal virtual {}

  function isController(address addr) internal view virtual returns (bool) {
    return address(_controller) == addr;
  }

  function _onlyController() private view {
    require(isController(msg.sender), Errors.CT_CALLER_MUST_BE_REWARD_CONTROLLER);
  }

  modifier onlyController() {
    _onlyController();
    _;
  }

  function _onlyConfigAdmin() private view {
    require(_controller.isConfigAdmin(msg.sender), Errors.CT_CALLER_MUST_BE_REWARD_ADMIN);
  }

  modifier onlyConfigAdmin() {
    _onlyConfigAdmin();
    _;
  }

  function _onlyRateAdmin() private view {
    require(_controller.isRateAdmin(msg.sender), Errors.CT_CALLER_MUST_BE_REWARD_RATE_ADMIN);
  }

  modifier onlyRateAdmin() {
    _onlyRateAdmin();
    _;
  }

  function _onlyEmergencyAdmin() private view {
    require(_controller.isEmergencyAdmin(msg.sender), Errors.CALLER_NOT_EMERGENCY_ADMIN);
  }

  modifier onlyEmergencyAdmin() {
    _onlyEmergencyAdmin();
    _;
  }

  function _onlyRefAdmin() private view {
    require(
      AccessHelper.hasAnyOf(
        _controller.getAccessController(),
        msg.sender,
        AccessFlags.REFERRAL_ADMIN
      ),
      'only referral admin is allowed'
    );
  }

  modifier onlyRefAdmin() {
    _onlyRefAdmin();
    _;
  }

  function _notPaused() private view {
    require(!_paused, Errors.RW_REWARD_PAUSED);
  }

  modifier notPaused() {
    _notPaused();
    _;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './CalcLinearRateReward.sol';
import '../../dependencies/openzeppelin/contracts/SafeMath.sol';

abstract contract CalcCheckpointWeightedReward is CalcLinearRateReward {
  using SafeMath for uint256;
  uint256 private _accumRate;
  mapping(uint32 => uint256) private _accumHistory;

  uint256 private constant _maxWeightBase = 1e36;

  function internalTotalSupply() internal view virtual returns (uint256);

  function internalExtraRate() internal view virtual returns (uint256);

  function doCheckpoint(uint32 at) internal {
    (uint256 lastRate, uint32 lastAt) = getRateAndUpdatedAt();
    internalMarkRateUpdate(at);
    internalRateUpdated(lastRate, lastAt, at);

    _accumHistory[at] = _accumRate + 1;
  }

  function internalRateUpdated(
    uint256 lastRate,
    uint32 lastAt,
    uint32 at
  ) internal override {
    if (at == lastAt) {
      return;
    }

    uint256 totalSupply = internalTotalSupply();

    if (totalSupply == 0) {
      return;
    }

    lastRate = lastRate.add(internalExtraRate());
    // the rate stays in RAY, but is weighted now vs _maxWeightBase
    lastRate = lastRate.mul(_maxWeightBase.div(totalSupply));
    _accumRate = _accumRate.add(lastRate.mul(at - lastAt));
  }

  function isHistory(uint32 at) internal view virtual returns (bool);

  function internalCalcRateAndReward(
    RewardEntry memory entry,
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
    if (isHistory(at)) {
      adjRate = _accumHistory[at];
      require(adjRate > 0, 'unknown history point');
      adjRate--;
    } else {
      adjRate = _accumRate;
      uint256 totalSupply = internalTotalSupply();

      if (totalSupply > 0) {
        (uint256 rate, uint32 updatedAt) = getRateAndUpdatedAt();

        rate = rate.add(internalExtraRate());
        rate = rate.mul(_maxWeightBase.div(totalSupply));
        adjRate = adjRate.add(rate.mul(at - updatedAt));
      }
    }

    if (adjRate == lastAccumRate || entry.rewardBase == 0) {
      return (adjRate, 0, entry.claimedAt);
    }

    allocated = uint256(entry.rewardBase).mul(adjRate.sub(lastAccumRate)).div(_maxWeightBase);
    return (adjRate, allocated, entry.claimedAt);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import '../../dependencies/openzeppelin/contracts/IERC20.sol';
import '../../dependencies/openzeppelin/contracts/SafeERC20.sol';
import '../../dependencies/openzeppelin/contracts/SafeMath.sol';
import '../../interfaces/IDerivedToken.sol';

/**
  @dev Curve-like locker, that locks an underlying token for some period and mints non-transferrable tokens for that period. 
  Total amount of minted tokens = amount_of_locked_tokens * max_period / lock_period.
  End of lock period is aligned to week.

  Additionally, this contract recycles token excess of capped rewards by spreading the excess over some period. 
 */

abstract contract BaseTokenLocker is IERC20, IDerivedToken {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IERC20 private _underlyingToken;

  // Total amount of minted tokens. This number is increased in situ for new locks, and decreased at week edges, when locks expire.
  uint256 private _stakedTotal;
  // Current extra rate that distributes the recycled excess. This number is increased in situ for new excess added, and decreased at week edges.
  uint256 private _extraRate;
  // Accumulated _extraRate
  uint256 private _excessAccum;

  /**
    @dev A future point, contains deltas to be applied at the relevant time (period's edge):
    - stakeDelta is amount to be subtracted from _stakedTotal
    - rateDelta is amount to be subtracted from _extraRate
  */
  struct Point {
    uint128 stakeDelta;
    uint128 rateDelta;
  }
  // Future points, indexed by point number (week number).
  mapping(uint32 => Point) _pointTotal;

  // Absolute limit of future points - 255 periods (weeks).
  uint32 private constant _maxDurationPoints = 255;
  // Period (in seconds) which gives 100% of lock tokens, must be less than _maxDurationPoints. Default = 208 weeks; // 4 * 52
  uint32 private constant _maxValuePeriod = 4 * 52 weeks;
  // Duration of a single period. All points are aligned to it. Default = 1 week.
  uint32 private constant _pointPeriod = 1 weeks;
  // Next (nearest future) known point.
  uint32 private _nextKnownPoint;
  // Latest (farest future) known point.
  uint32 private _lastKnownPoint;
  // Timestamp when internalUpdate() was invoked.
  uint32 private _lastUpdateTS;
  // Re-entrance guard for some of internalUpdate() operations.
  bool private _updateEntered;

  /**
    @dev Details about user's lock
  */
  struct UserBalance {
    // Total amount of underlying token received from the user
    uint192 underlyingAmount;
    // Timestamp (not point) when the lock was created
    uint32 startTS;
    // Point number (week number), when the lock expired
    uint32 endPoint;
  }

  // Balances of users
  mapping(address => UserBalance) private _balances;
  // Addresses which are allowed to add to user's lock
  // map[user][delegate]
  mapping(address => mapping(address => bool)) private _allowAdd;

  event Locked(
    address from,
    address indexed to,
    uint256 underlyingAmountAdded,
    uint256 underlyingAmountTotal,
    uint256 amount,
    uint32 indexed expiry,
    uint256 indexed referral
  );
  event Redeemed(address indexed from, address indexed to, uint256 underlyingAmount);

  /// @param underlying ERC20 token to be locked
  constructor(address underlying) {
    _initialize(underlying);
  }

  /// @dev To be used for initializers only. Same as constructor.
  function _initialize(address underlying) internal {
    _underlyingToken = IERC20(underlying);
  }

  function UNDERLYING_ASSET_ADDRESS() external view override returns (address) {
    return address(_underlyingToken);
  }

  /** @dev Creates a new lock or adds more underlying to an existing lock of the caller:
      - with duration =0 this function adds to an existing unexpired lock without chaning lock's expiry, otherwise will fail (expired lock)
      - when a lock exists, the expiry (end) of the lock will be maximum of the current lock and of to-be-lock with the given duration.
      - when a lock has expired, but tokens were not redeemed these unredeemed tokens will also be added to the new locked.
      @param underlyingAmount amount of underlying (>0) to be added to the lock. Must be approved for transferFrom.
      @param duration in seconds of the lock. This duration will be rounded up to make sure that lock will end at a week's edge. 
      Zero value indicates addition to an existing lock without changing expiry.
      @param referral code to use for marketing campaings. Use 0 when not involved.      
      @return total amount of lock tokens of the user.
   */
  function lock(
    uint256 underlyingAmount,
    uint32 duration,
    uint256 referral
  ) external returns (uint256) {
    require(underlyingAmount > 0, 'ZERO_UNDERLYING');
    //    require(duration > 0, 'ZERO_DURATION');

    (uint256 stakeAmount, uint256 recoverableError) =
      internalLock(msg.sender, msg.sender, underlyingAmount, duration, referral, true);

    revertOnError(recoverableError);
    return stakeAmount;
  }

  /** @dev Extends an existing lock of the caller without adding more underlying. 
      @param duration in seconds (>0) of the lock. This duration will be rounded up to make sure that lock will end at a week's edge. 
      @return total amount of lock tokens of the user.
   */
  function lockExtend(uint32 duration) external returns (uint256) {
    require(duration > 0, 'ZERO_DURATION');

    (uint256 stakeAmount, uint256 recoverableError) =
      internalLock(msg.sender, msg.sender, 0, duration, 0, false);

    revertOnError(recoverableError);
    return stakeAmount;
  }

  /** @dev Allows/disallows another user/contract to use lockAdd() function for the caller's lock.
      @param to an address who will call lockAdd().
      @param allow indicates if calls are allowed (true) or disallowed (false).
   */
  function allowAdd(address to, bool allow) external {
    _allowAdd[msg.sender][to] = allow;
  }

  /** @dev A function to add funds to a lock of another user. Must be explicitly allowed with allowAdd().
      @param to an address to whose lock the given underlyingAmount shoud be added
      @param underlyingAmount amount of underlying (>0) to be added to the lock. Must be approved for transferFrom.
      @return total amount of lock tokens of the `to` address.
   */
  function lockAdd(address to, uint256 underlyingAmount) external returns (uint256) {
    require(underlyingAmount > 0, 'ZERO_UNDERLYING');
    require(_allowAdd[to][msg.sender], 'ADD_TO_LOCK_RESTRICTED');

    (uint256 stakeAmount, uint256 recoverableError) =
      internalLock(msg.sender, to, underlyingAmount, 0, 0, true);

    revertOnError(recoverableError);
    return stakeAmount;
  }

  // These constants are soft errors - such errors can be detected by the autolock function so it can stop automatically
  uint256 private constant LOCK_ERR_NOTHING_IS_LOCKED = 1;
  uint256 private constant LOCK_ERR_DURATION_IS_TOO_LARGE = 2;
  uint256 private constant LOCK_ERR_UNDERLYING_OVERFLOW = 3;
  uint256 private constant LOCK_ERR_LOCK_OVERFLOW = 4;

  /// @dev Converts soft errors into hard reverts
  function revertOnError(uint256 recoverableError) private pure {
    require(recoverableError != LOCK_ERR_LOCK_OVERFLOW, 'LOCK_ERR_LOCK_OVERFLOW');
    require(recoverableError != LOCK_ERR_UNDERLYING_OVERFLOW, 'LOCK_ERR_UNDERLYING_OVERFLOW');
    require(recoverableError != LOCK_ERR_DURATION_IS_TOO_LARGE, 'LOCK_ERR_DURATION_IS_TOO_LARGE');
    require(recoverableError != LOCK_ERR_NOTHING_IS_LOCKED, 'NOTHING_IS_LOCKED');
    require(recoverableError == 0, 'UNKNOWN_RECOVERABLE_ERROR');
  }

  /** @dev Creates a new lock or adds underlying to an existing lock or extends it.
      @param from whom the funds (underlying) will be taken
      @param to whom the funds will be locked
      @param underlyingTransfer amount of underlying (=>0) to be added to the lock.
      @param duration in seconds of the lock. This duration will be rounded up to make sure that lock will end at a week's edge. 
      Zero value indicates addition to an existing lock without changing expiry.
      @param transfer indicates when transferFrom should be called. E.g. autolock uses false, as tokens will be minted externally to this contract.
      @param referral code to use for marketing campaings. Use 0 when not involved.
      @return stakeAmount is total amount of lock tokens of the `to` address; recoverableError is the soft error code.
   */
  function internalLock(
    address from,
    address to,
    uint256 underlyingTransfer,
    uint32 duration,
    uint256 referral,
    bool transfer
  ) internal returns (uint256 stakeAmount, uint256 recoverableError) {
    require(from != address(0), 'ZERO_FROM');
    require(to != address(0), 'ZERO_TO');

    uint32 currentPoint = internalUpdate(true, 0);

    // this call ensures that time-based reward calculations are pulled up to this moment
    internalSyncRate(uint32(block.timestamp));

    UserBalance memory userBalance = _balances[to];

    uint256 prevStake;
    {
      // ======== ATTN! DO NOT APPLY STATE CHANGES STARTING FROM HERE ========
      {
        // ATTN! Should be no overflow checks here
        uint256 underlyingBalance = underlyingTransfer + userBalance.underlyingAmount;

        if (underlyingBalance < underlyingTransfer || underlyingBalance > type(uint192).max) {
          return (0, LOCK_ERR_UNDERLYING_OVERFLOW);
        } else if (underlyingBalance == 0) {
          return (0, LOCK_ERR_NOTHING_IS_LOCKED);
        }
        userBalance.underlyingAmount = uint192(underlyingBalance);
      }

      uint32 newEndPoint;
      if (duration < _pointPeriod) {
        // at least 1 full week is required
        newEndPoint = 1 + (uint32(block.timestamp + _pointPeriod - 1) / _pointPeriod);
      } else {
        newEndPoint = uint32(block.timestamp + duration + (_pointPeriod >> 1)) / _pointPeriod;
      }

      if (newEndPoint > currentPoint + _maxDurationPoints) {
        return (0, LOCK_ERR_DURATION_IS_TOO_LARGE);
      }

      if (userBalance.endPoint > currentPoint) {
        // lock is still valid - reuse it
        // so keep startTS and use the farest endTS
        require(userBalance.startTS > 0);

        prevStake = getStakeBalance(to);

        if (userBalance.endPoint > newEndPoint) {
          newEndPoint = userBalance.endPoint;
        }
      } else if (duration == 0) {
        // can't add to an expired lock
        return (0, LOCK_ERR_NOTHING_IS_LOCKED);
      } else {
        // new lock -> new start
        userBalance.startTS = uint32(block.timestamp);
      }

      {
        uint256 adjDuration = uint256(newEndPoint * _pointPeriod).sub(userBalance.startTS);
        if (adjDuration < _maxValuePeriod) {
          stakeAmount = uint256(userBalance.underlyingAmount).mul(adjDuration).div(_maxValuePeriod);
        } else {
          stakeAmount = userBalance.underlyingAmount;
        }
      }

      // ATTN! Should be no overflow checks here
      uint256 newStakeDelta = stakeAmount + _pointTotal[newEndPoint].stakeDelta;

      if (newStakeDelta < stakeAmount || newStakeDelta > type(uint128).max) {
        return (0, LOCK_ERR_LOCK_OVERFLOW);
      }

      // ======== ATTN! DO NOT APPLY STATE CHANGES ENDS HERE ========

      if (prevStake > 0) {
        if (userBalance.endPoint == newEndPoint) {
          newStakeDelta = newStakeDelta.sub(prevStake);
        } else {
          _pointTotal[userBalance.endPoint].stakeDelta = uint128(
            uint256(_pointTotal[userBalance.endPoint].stakeDelta).sub(prevStake)
          );
        }
        _stakedTotal = _stakedTotal.sub(prevStake);
      }

      if (userBalance.endPoint <= currentPoint) {
        // sum up rewards for the previous balance
        unsetStakeBalance(to, userBalance.endPoint * _pointPeriod, true);
        prevStake = 0;
      }

      userBalance.endPoint = newEndPoint;

      // range check is done above
      _pointTotal[newEndPoint].stakeDelta = uint128(newStakeDelta);
      _stakedTotal = _stakedTotal.add(stakeAmount);
    }

    if (_nextKnownPoint > userBalance.endPoint || _nextKnownPoint == 0) {
      _nextKnownPoint = userBalance.endPoint;
    }

    if (_lastKnownPoint < userBalance.endPoint || _lastKnownPoint == 0) {
      _lastKnownPoint = userBalance.endPoint;
    }

    if (prevStake != stakeAmount) {
      setStakeBalance(to, uint224(stakeAmount));
    }

    _balances[to] = userBalance;

    if (transfer) {
      _underlyingToken.safeTransferFrom(from, address(this), underlyingTransfer);
    }

    emit Locked(
      from,
      to,
      underlyingTransfer,
      userBalance.underlyingAmount,
      stakeAmount,
      userBalance.endPoint * _pointPeriod,
      referral
    );
    return (stakeAmount, 0);
  }

  /// @dev Returns amount of underlying for the given address
  function balanceOfUnderlying(address account) public view returns (uint256) {
    return _balances[account].underlyingAmount;
  }

  /// @dev Returns amount of underlying and a timestamp when the lock expires. Funds can be redeemed after the timestamp.
  function balanceOfUnderlyingAndExpiry(address account)
    external
    view
    returns (uint256 underlying, uint32 availableSince)
  {
    underlying = _balances[account].underlyingAmount;
    if (underlying == 0) {
      return (0, 0);
    }
    return (underlying, _balances[account].endPoint * _pointPeriod);
  }

  function expiryOf(address account)
    internal
    view
    returns (uint32 lockedSince, uint32 availableSince)
  {
    return (_balances[account].startTS, _balances[account].endPoint * _pointPeriod);
  }

  /**
   * @dev Attemps to redeem all underlying tokens of caller. Will not revert on zero or locked balance.
   * @param to address to which all redeemed tokens should be transferred.
   * @return underlyingAmount redeemed. Zero for an unexpired lock.
   **/
  function redeem(address to) public virtual returns (uint256 underlyingAmount) {
    return internalRedeem(msg.sender, to);
  }

  function internalRedeem(address from, address to) private returns (uint256 underlyingAmount) {
    uint32 currentPoint = internalUpdate(true, 0);
    UserBalance memory userBalance = _balances[from];

    if (userBalance.underlyingAmount == 0 || userBalance.endPoint > currentPoint) {
      // not yet
      return 0;
    }

    // pay off rewards and stop
    unsetStakeBalance(from, userBalance.endPoint * _pointPeriod, false);

    delete (_balances[from]);

    _underlyingToken.safeTransfer(to, userBalance.underlyingAmount);

    emit Redeemed(from, to, userBalance.underlyingAmount);
    return userBalance.underlyingAmount;
  }

  /// @dev Explicit call to applies all future-in-past points. Only useful to handle a situation when there were no state-changing calls for a long time.
  /// @param scanLimit defines a maximum number of points / updates to be processed at once.
  function update(uint256 scanLimit) public {
    internalUpdate(false, scanLimit);
  }

  function isCompletedPast(uint32 at) internal view returns (bool) {
    return at <= (_lastUpdateTS / _pointPeriod) * _pointPeriod;
  }

  function getScanRange(uint32 currentPoint, uint256 scanLimit)
    private
    view
    returns (
      uint32 fromPoint,
      uint32 tillPoint,
      uint32 maxPoint
    )
  {
    fromPoint = _nextKnownPoint;

    if (currentPoint < fromPoint || fromPoint == 0) {
      return (fromPoint, 0, 0);
    }

    maxPoint = _lastKnownPoint;
    if (maxPoint == 0) {
      // shouldn't happen, but as a precaution
      maxPoint = uint32(_lastUpdateTS / _pointPeriod) + _maxDurationPoints + 1;
    }

    if (scanLimit > 0 && scanLimit + fromPoint > scanLimit) {
      scanLimit += fromPoint;
      if (scanLimit < maxPoint) {
        maxPoint = uint32(scanLimit);
      }
    }

    if (maxPoint > currentPoint) {
      tillPoint = currentPoint;
    } else {
      tillPoint = maxPoint;
    }

    return (fromPoint, tillPoint, maxPoint);
  }

  /// @dev returns a total locked amount of underlying
  function totalOfUnderlying() external view returns (uint256) {
    return _underlyingToken.balanceOf(address(this));
  }

  function internalCurrentTotalSupply() internal view returns (uint256) {
    return _stakedTotal;
  }

  /// @dev returns a total amount of lock tokens
  function totalSupply() public view override returns (uint256 totalSupply_) {
    (uint32 fromPoint, uint32 tillPoint, ) =
      getScanRange(uint32(block.timestamp / _pointPeriod), 0);

    totalSupply_ = _stakedTotal;

    if (tillPoint == 0) {
      return totalSupply_;
    }

    for (; fromPoint <= tillPoint; fromPoint++) {
      uint256 stakeDelta = _pointTotal[fromPoint].stakeDelta;
      if (stakeDelta == 0) {
        continue;
      }
      if (totalSupply_ == stakeDelta) {
        return 0;
      }
      totalSupply_ = totalSupply_.sub(stakeDelta);
    }

    return totalSupply_;
  }

  /// @param preventReentry when true will revert the call on re-entry, otherwise will exit immediately
  /// @param scanLimit limits number of updates to be applied. Must be zero (=unlimited) for all internal oprations, otherwise the state will be inconsisten.
  /// @return currentPoint (week number)
  function internalUpdate(bool preventReentry, uint256 scanLimit)
    internal
    returns (uint32 currentPoint)
  {
    currentPoint = uint32(block.timestamp / _pointPeriod);

    if (_updateEntered) {
      require(!preventReentry, 're-entry to stake or to redeem');
      return currentPoint;
    }
    if (_lastUpdateTS == uint32(block.timestamp)) {
      return currentPoint;
    }

    (uint32 fromPoint, uint32 tillPoint, uint32 maxPoint) = getScanRange(currentPoint, scanLimit);
    if (tillPoint > 0) {
      _updateEntered = true;
      {
        walkPoints(fromPoint, tillPoint, maxPoint);
      }
      _updateEntered = false;
    }

    _lastUpdateTS = uint32(block.timestamp);
    return currentPoint;
  }

  /// @dev searches and processes updates for future-in-past points and update next/last known points accordingly
  /// @param nextPoint start of future-in-past points (inclusive)
  /// @param tillPoint end of future-in-past points (inclusive)
  /// @param maxPoint the farest future point till which the next known point will be searched for
  function walkPoints(
    uint32 nextPoint,
    uint32 tillPoint,
    uint32 maxPoint
  ) private {
    Point memory delta = _pointTotal[nextPoint];

    for (; nextPoint <= tillPoint; ) {
      internalCheckpoint(nextPoint * _pointPeriod);

      _extraRate = _extraRate.sub(delta.rateDelta);
      _stakedTotal = _stakedTotal.sub(delta.stakeDelta);

      bool found = false;
      // look for the next non-zero point
      for (nextPoint++; nextPoint <= maxPoint; nextPoint++) {
        delta = _pointTotal[nextPoint];
        if (delta.stakeDelta > 0 || delta.rateDelta > 0) {
          found = true;
          break;
        }
      }
      if (found) {
        continue;
      }

      // keep nextPoint to reduce gas for further calls
      if (nextPoint > _lastKnownPoint) {
        nextPoint = 0;
      }
      break;
    }

    _nextKnownPoint = nextPoint;
    if (nextPoint == 0 || nextPoint > _lastKnownPoint) {
      _lastKnownPoint = nextPoint;
    }
  }

  function getUnderlying() internal view returns (address) {
    return address(_underlyingToken);
  }

  function transfer(address, uint256) external override returns (bool) {
    notSupported();
  }

  function allowance(address, address) external pure override returns (uint256) {
    notSupported();
  }

  function approve(address, uint256) external override returns (bool) {
    notSupported();
  }

  function transferFrom(
    address,
    address,
    uint256
  ) external override returns (bool) {
    notSupported();
  }

  function notSupported() private pure {
    revert('NOT_SUPPORTED');
  }

  /// @dev internalAddExcess recycles reward excess by spreading the given amount.
  /// The given amount is distributed starting from now for the same period that has passed from (since) till now.
  /// @param amount of reward to be redistributed.
  /// @param since a timestamp (in the past) since which the given amount was accumulated.
  /// No restrictions on since value - zero, current or event future timestamps are handled.
  function internalAddExcess(uint256 amount, uint32 since) internal {
    uint32 at = uint32(block.timestamp);
    uint32 expiry;

    if (since == 0 || since >= at) {
      expiry = 1;
    } else {
      expiry = at - since;
      if (expiry > _maxValuePeriod) {
        expiry = _maxValuePeriod;
      }
    }

    uint32 expiryPt = 1 + uint32(expiry + at + _pointPeriod - 1) / _pointPeriod;
    expiry = expiryPt * _pointPeriod;

    expiry -= at;
    amount += _excessAccum;
    uint256 excessRateIncrement = amount / expiry;
    _excessAccum = amount - excessRateIncrement * expiry;

    if (excessRateIncrement == 0) {
      return;
    }

    internalSyncRate(at);

    _extraRate = _extraRate.add(excessRateIncrement);

    excessRateIncrement = excessRateIncrement.add(_pointTotal[expiryPt].rateDelta);
    require(excessRateIncrement <= type(uint128).max);
    _pointTotal[expiryPt].rateDelta = uint128(excessRateIncrement);

    if (_nextKnownPoint > expiryPt || _nextKnownPoint == 0) {
      _nextKnownPoint = expiryPt;
    }

    if (_lastKnownPoint < expiryPt || _lastKnownPoint == 0) {
      _lastKnownPoint = expiryPt;
    }
  }

  /// @dev is called to syncronize reward accumulators
  /// @param at timestamp till which accumulators should be updated
  function internalSyncRate(uint32 at) internal virtual;

  /// @dev is called to update rate history
  /// @param at timestamp for which the current state should be records as a history point
  function internalCheckpoint(uint32 at) internal virtual;

  /// @dev is called to sum up reward and to stop issuing it
  /// @param holder of reward
  /// @param at timestamp till which reward should be calculated
  /// @param interim is true when setStakeBalance will be called right after this one
  function unsetStakeBalance(
    address holder,
    uint32 at,
    bool interim
  ) internal virtual;

  /// @dev is called to sum up reward upto now and start calculation of the reward for the new stakeAmount
  /// @param holder of reward
  /// @param stakeAmount of lock tokens for reward calculation
  function setStakeBalance(address holder, uint224 stakeAmount) internal virtual;

  function getStakeBalance(address holder) internal view virtual returns (uint224 stakeAmount);

  function convertLockedToUnderlying(uint256 lockedAmount, uint32 lockDuration)
    public
    view
    returns (uint256)
  {
    this;
    if (lockDuration > _maxValuePeriod) {
      lockDuration = _maxValuePeriod;
    }

    lockDuration = (lockDuration + (_pointPeriod >> 1)) / _pointPeriod;
    lockDuration *= _pointPeriod;

    if (lockDuration < _maxValuePeriod) {
      return lockedAmount.mul(_maxValuePeriod).div(lockDuration);
    }
    return lockedAmount;
  }

  function convertUnderlyingToLocked(uint256 underlyingAmount, uint32 lockDuration)
    public
    view
    returns (uint256 lockedAmount)
  {
    this;
    if (lockDuration > _maxValuePeriod) {
      lockDuration = _maxValuePeriod;
    }

    lockDuration = (lockDuration + (_pointPeriod >> 1)) / _pointPeriod;
    lockDuration *= _pointPeriod;

    if (lockDuration < _maxValuePeriod) {
      return underlyingAmount.mul(lockDuration).div(_maxValuePeriod);
    }
    return underlyingAmount;
  }

  /// @dev returns current rate of reward excess / redistribution.
  /// This function is used by decsendants.
  function getExtraRate() internal view returns (uint256) {
    return _extraRate;
  }

  /// @dev returns unadjusted (current state) amount of lock tokens.
  /// This function is used by decsendants.
  function getStakedTotal() internal view returns (uint256) {
    return _stakedTotal;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../Errors.sol';

/// @dev Percentages are defined in basis points. The precision is indicated by ONE. Operations are rounded half up.
library PercentageMath {
  uint16 constant BP = 1; // basis point
  uint16 constant PCT = 100 * BP; // basis points per percentage point
  uint16 constant ONE = 100 * PCT; // basis points per 1 (100%)
  uint16 constant HALF_ONE = ONE / 2;
  // deprecated
  uint256 constant PERCENTAGE_FACTOR = ONE; //percentage plus two decimals

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

import '../../interfaces/IEmergencyAccess.sol';

interface IManagedRewardPool is IEmergencyAccess {
  function updateBaseline(uint256) external returns (bool hasBaseline, uint256 appliedRate);

  function setBaselinePercentage(uint16) external;

  function getBaselinePercentage() external view returns (bool, uint16);

  function disableBaseline() external;

  function disableRewardPool() external;

  function getRate() external view returns (uint256);

  function setRate(uint256) external;

  function getPoolName() external view returns (string memory);

  function claimRewardFor(address holder, uint256 limit)
    external
    returns (uint256 amount, uint32 since);

  function calcRewardFor(address holder, uint32 at)
    external
    view
    returns (uint256 amount, uint32 since);

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

import '../interfaces/IRewardController.sol';
import '../../dependencies/openzeppelin/contracts/SafeMath.sol';

abstract contract CalcLinearRateReward {
  using SafeMath for uint256;

  mapping(address => RewardEntry) private _rewards;
  uint256 private _rate;
  uint32 private _rateUpdatedAt;

  mapping(address => uint256) private _accumRates;

  struct RewardEntry {
    uint224 rewardBase;
    uint32 claimedAt;
  }

  function setLinearRate(uint256 rate) internal {
    setLinearRateAt(rate, getCurrentTick());
  }

  function setLinearRateAt(uint256 rate, uint32 at) internal {
    if (_rate == rate) {
      return;
    }

    uint32 prevTick = _rateUpdatedAt;
    if (at != prevTick) {
      uint256 prevRate = _rate;
      internalMarkRateUpdate(at);
      _rate = rate;
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

  function getLinearRate() internal view virtual returns (uint256) {
    return _rate;
  }

  function getRateAndUpdatedAt() internal view virtual returns (uint256, uint32) {
    return (_rate, _rateUpdatedAt);
  }

  function getRateUpdatedAt() internal view returns (uint32) {
    return _rateUpdatedAt;
  }

  function internalCalcRateAndReward(
    RewardEntry memory entry,
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

  function getRewardEntry(address holder) internal view returns (RewardEntry memory) {
    return _rewards[holder];
  }

  function doUpdateReward(
    address holder,
    uint256 oldBalance,
    uint256 newBalance
  )
    internal
    virtual
    returns (
      uint256 allocated,
      uint32 since,
      AllocationMode mode
    )
  {
    require(newBalance <= type(uint224).max, 'balance is too high');

    RewardEntry memory entry = _rewards[holder];

    if (newBalance == 0) {
      mode = AllocationMode.UnsetPull;
    } else if (entry.claimedAt == 0) {
      mode = AllocationMode.SetPull;
    } else {
      mode = AllocationMode.Push;
    }

    newBalance = internalCalcBalance(entry, oldBalance, newBalance);
    require(newBalance <= type(uint224).max, 'balance is too high');

    uint32 currentTick = getCurrentTick();

    uint256 adjRate;
    (adjRate, allocated, since) = internalCalcRateAndReward(
      entry,
      _accumRates[holder],
      currentTick
    );

    _accumRates[holder] = adjRate;
    _rewards[holder] = RewardEntry(uint224(newBalance), currentTick);
    return (allocated, since, mode);
  }

  function internalCalcBalance(
    RewardEntry memory entry,
    uint256 oldBalance,
    uint256 newBalance
  ) internal pure virtual returns (uint256) {
    entry;
    oldBalance;
    return newBalance;
  }

  function internalRemoveReward(address holder) internal virtual returns (uint256 rewardBase) {
    rewardBase = _rewards[holder].rewardBase;
    if (rewardBase == 0 && _rewards[holder].claimedAt == 0) {
      return 0;
    }
    delete (_rewards[holder]);
    return rewardBase;
  }

  function doGetReward(address holder) internal virtual returns (uint256, uint32) {
    return doGetRewardAt(holder, getCurrentTick());
  }

  function doGetRewardAt(address holder, uint32 currentTick)
    internal
    virtual
    returns (uint256, uint32)
  {
    if (_rewards[holder].rewardBase == 0) {
      return (0, 0);
    }

    (uint256 adjRate, uint256 allocated, uint32 since) =
      internalCalcRateAndReward(_rewards[holder], _accumRates[holder], currentTick);

    _accumRates[holder] = adjRate;
    _rewards[holder].claimedAt = currentTick;
    return (allocated, since);
  }

  function doCalcReward(address holder) internal view virtual returns (uint256, uint32) {
    return doCalcRewardAt(holder, getCurrentTick());
  }

  function doCalcRewardAt(address holder, uint32 currentTick)
    internal
    view
    virtual
    returns (uint256, uint32)
  {
    if (_rewards[holder].rewardBase == 0) {
      return (0, 0);
    }

    (, uint256 allocated, uint32 since) =
      internalCalcRateAndReward(_rewards[holder], _accumRates[holder], currentTick);
    return (allocated, since);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/// @dev Interface of the ERC20 standard as defined in the EIP excluding events to avoid linearization issues.
interface IERC20 {
  /// @dev Returns the amount of tokens in existence.
  function totalSupply() external view returns (uint256);

  /// @dev Returns the amount of tokens owned by `account`.
  function balanceOf(address account) external view returns (uint256);

  /// @dev Moves `amount` tokens from the caller's account to `recipient`.
  function transfer(address recipient, uint256 amount) external returns (bool);

  /// @dev Returns the remaining number of tokens that `spender` will be allowed to spend.
  function allowance(address owner, address spender) external view returns (uint256);

  /// @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
  function approve(address spender, uint256 amount) external returns (bool);

  /// @dev Moves `amount` tokens from `sender` to `recipient`
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './IERC20.sol';
import './SafeMath.sol';
import './Addr.sol';

/// @dev Wrappers around ERC20 operations that throw on failure (when the token contract returns false).
library SafeERC20 {
  using SafeMath for uint256;

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
    require(Addr.isContract(address(token)), 'SafeERC20: call to non-contract');

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

interface IDerivedToken {
  /**
   * @dev Returns the address of the underlying asset of this token (E.g. WETH for agWETH)
   **/
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev Extracted from Address.sol to fit into the verification limit
library Addr {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}