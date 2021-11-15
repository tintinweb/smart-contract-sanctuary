// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../tools/upgradeability/VersionedInitializable.sol';
import '../interfaces/IRewardController.sol';
import '../interfaces/IInitializableRewardPool.sol';
import './ReferralRewardPool.sol';

contract ReferralRewardPoolV1 is IInitializableRewardPool, ReferralRewardPool, VersionedInitializable {
  uint256 private constant POOL_REVISION = 1;

  function getRevision() internal pure virtual override returns (uint256) {
    return POOL_REVISION;
  }

  constructor() ReferralRewardPool(IRewardController(address(0)), 0, 0, 'RefPool') {}

  function initializeRewardPool(InitRewardPoolData memory data) public override initializer(POOL_REVISION) {
    super._initialize(data.controller, internalGetRate(), data.baselinePercentage, data.poolName);
    internalSetClaimLimit(type(uint256).max);
  }

  function initializedRewardPoolWith() external view override returns (InitRewardPoolData memory) {
    return InitRewardPoolData(IRewardController(getRewardController()), getPoolName(), internalGetBaselinePercentage());
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

import '../../access/interfaces/IMarketAccessController.sol';

enum AllocationMode {
  Push,
  SetPull,
  UnsetPull
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

import '../interfaces/IRewardController.sol';
import '../referral/BaseReferralRegistry.sol';
import '../calcs/CalcLinearRewardAccum.sol';
import './BasePermitRewardPool.sol';

contract ReferralRewardPool is BasePermitRewardPool, BaseReferralRegistry, CalcLinearRewardAccum {
  uint256 private _claimLimit;

  event RewardClaimedByPermit(address indexed provider, address indexed spender, uint256 value, uint256 since);
  event ClaimLimitUpdated(uint256 limit);

  constructor(
    IRewardController controller,
    uint256 initialRate,
    uint16 baselinePercentage,
    string memory rewardPoolName
  ) ControlledRewardPool(controller, initialRate, baselinePercentage) BasePermitRewardPool(rewardPoolName) {
    internalSetClaimLimit(type(uint256).max);
  }

  function getClaimTypeHash() internal pure override returns (bytes32) {
    return
      keccak256(
        'ClaimReward(address provider,address spender,uint256 value,uint256 nonce,uint256 issuedAt,uint256[] codes)'
      );
  }

  function claimRewardByPermit(
    address provider,
    address spender,
    uint256 value,
    uint256 issuedAt,
    uint256[] calldata codes,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external notPaused {
    uint256 currentValidNonce = _nonces[spender];
    require(issuedAt > currentValidNonce, 'EXPIRED_ISSUANCE');
    require(value <= _claimLimit, 'EXCESSIVE_VALUE');
    require(uint32(issuedAt) == issuedAt);

    bytes32 encodedHash = keccak256(
      abi.encode(CLAIM_TYPEHASH, provider, spender, value, currentValidNonce, issuedAt, codes)
    );

    doClaimRewardByPermit(provider, spender, spender, value, issuedAt, encodedHash, currentValidNonce, v, r, s);

    internalUpdateStrict(spender, codes, uint32(issuedAt));
    emit RewardClaimedByPermit(provider, spender, value, currentValidNonce);
  }

  function internalCheckNonce(uint256, uint256 issuedAt) internal pure override returns (uint256) {
    return issuedAt;
  }

  function internalUpdateFunds(uint256 value) internal override {
    doGetReward(value);
  }

  function availableReward() public view override returns (uint256) {
    return doCalcReward();
  }

  function claimLimit() public view returns (uint256) {
    return _claimLimit;
  }

  function setClaimLimit(uint256 value) external onlyRateAdmin {
    internalSetClaimLimit(value);
  }

  function internalSetClaimLimit(uint256 value) internal {
    _claimLimit = value;
    emit ClaimLimitUpdated(value);
  }

  function registerShortCode(uint32 shortRefCode, address to) external onlyRefAdmin {
    internalRegisterCode(shortRefCode, to);
  }

  function registerShortCodes(uint32[] calldata shortRefCode, address[] calldata to) external onlyRefAdmin {
    require(shortRefCode.length == to.length);
    for (uint256 i = 0; i < to.length; i++) {
      internalRegisterCode(shortRefCode[i], to[i]);
    }
  }

  function internalSetRate(uint256 rate) internal override {
    super.setLinearRate(rate);
  }

  function internalGetRate() internal view override returns (uint256) {
    return super.getLinearRate();
  }

  function getCurrentTick() internal view override returns (uint32) {
    return uint32(block.timestamp);
  }

  function internalGetReward(address, uint256) internal virtual override returns (uint256, uint32) {
    return (0, 0);
  }

  function internalCalcReward(address, uint32) internal view virtual override returns (uint256, uint32) {
    return (0, 0);
  }

  function _onlyRefAdmin() private view {
    AccessHelper.requireAnyOf(
      getAccessController(),
      msg.sender,
      AccessFlags.REFERRAL_ADMIN,
      Errors.CALLER_NOT_REF_ADMIN
    );
  }

  modifier onlyRefAdmin() {
    _onlyRefAdmin();
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

import '../../tools/Errors.sol';
import '../interfaces/IReferralRegistry.sol';

abstract contract BaseReferralRegistry is IReferralRegistry {
  mapping(uint256 => address) private _delegations;
  mapping(uint256 => uint32) private _timestamps;

  uint32 private constant RESERVED_CODE = type(uint32).max;

  function registerCustomCode(uint256 refCode, address to) public override {
    require(refCode > RESERVED_CODE, 'REF_CODE_RESERVED');
    internalRegisterCode(refCode, to);
  }

  function internalRegisterCode(uint256 refCode, address to) internal {
    if (refCode < RESERVED_CODE) {
      require(refCode != 0, 'ZERO_REF_CODE_RESERVED');
    } else {
      require(refCode & RESERVED_CODE != RESERVED_CODE, 'DEFAULT_REF_CODE_RESERVED');
    }

    require(to != address(0), 'OWNER_REQUIRED');
    require(_delegations[refCode] == address(0), 'REF_CODE_REGISTERED');

    _delegations[refCode] = to;
    emit RefCodeDelegated(refCode, address(0), to);
  }

  function defaultCode(address addr) public pure override returns (uint256) {
    if (addr == address(0)) {
      return 0;
    }
    return (uint256(keccak256(abi.encodePacked(addr))) << 32) | RESERVED_CODE;
  }

  function transferCodeTo(uint256 refCode, address to) public override {
    require(refCode != 0, 'REF_CODE_REQUIRED');
    require(to != address(0), 'OWNER_REQUIRED');

    if (_delegations[refCode] == address(0)) {
      require(refCode == defaultCode(msg.sender), 'REF_CODE_NOT_OWNED');
    } else {
      require(_delegations[refCode] == msg.sender, 'REF_CODE_WRONG_OWNER');
    }
    _delegations[refCode] = to;
    emit RefCodeDelegated(refCode, msg.sender, to);
  }

  function ownerOf(uint256 refCode) internal view returns (bool owned, address owner) {
    if (refCode == 0) {
      return (true, address(0));
    }
    owner = _delegations[refCode];
    if (owner != address(0)) {
      return (true, owner);
    }
    return (refCode & RESERVED_CODE == RESERVED_CODE, owner);
  }

  function timestampsOf(address owner, uint256[] calldata codes)
    external
    view
    override
    returns (uint32[] memory timestamps)
  {
    require(owner != address(0), 'OWNER_REQUIRED');

    timestamps = new uint32[](codes.length);
    for (uint256 i = 0; i < codes.length; i++) {
      if (_delegations[codes[i]] != owner) {
        timestamps[i] = type(uint32).max;
        continue;
      }

      timestamps[i] = _timestamps[codes[i]];
    }

    return timestamps;
  }

  function internalUpdateTimestamps(
    address owner,
    uint256[] calldata codes,
    uint32 current
  ) internal returns (uint32[] memory timestamps) {
    require(owner != address(0), 'OWNER_REQUIRED');

    timestamps = new uint32[](codes.length);
    for (uint256 i = 0; i < codes.length; i++) {
      if (_delegations[codes[i]] != owner) {
        timestamps[i] = type(uint32).max;
        continue;
      }

      timestamps[i] = _timestamps[codes[i]];

      if (_timestamps[codes[i]] < current) {
        _timestamps[codes[i]] = current;
      }
    }

    return timestamps;
  }

  function internalUpdateStrict(
    address owner,
    uint256[] calldata codes,
    uint32 current
  ) internal {
    require(owner != address(0), 'OWNER_REQUIRED');

    for (uint256 i = 0; i < codes.length; i++) {
      require(_delegations[codes[i]] == owner, 'INVALID_REF_CODE_OWNER');
      require(_timestamps[codes[i]] < current, 'INVALID_REF_CODE_TIMESTAMP');

      _timestamps[codes[i]] = current;
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../dependencies/openzeppelin/contracts/SafeMath.sol';
import '../../tools/Errors.sol';

abstract contract CalcLinearRewardAccum {
  uint256 private _rate;
  uint256 private _accumRate;
  uint256 private _consumed;
  uint32 private _rateUpdatedAt;

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
  ) internal {
    _accumRate += lastRate * (at - lastAt);
  }

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

  function doGetReward(uint256 amount) internal returns (uint256 available) {
    available = SafeMath.sub(doCalcReward(), amount, Errors.VL_INSUFFICIENT_REWARD_AVAILABLE);
    _consumed += amount;
  }

  function doGetAllReward(uint256 limit) internal returns (uint256 available) {
    available = doCalcReward();
    if (limit < available) {
      available = limit;
    }
    _consumed += available;
    return available;
  }

  function doCalcReward() internal view returns (uint256) {
    return doCalcRewardAt(getCurrentTick());
  }

  function doCalcRewardAt(uint32 at) internal view returns (uint256) {
    return (_accumRate + (_rate * (at - _rateUpdatedAt))) - _consumed;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../interfaces/IRewardController.sol';
import './ControlledRewardPool.sol';

abstract contract BasePermitRewardPool is ControlledRewardPool {
  bytes public constant EIP712_REVISION = bytes('1');
  // solhint-disable-next-line var-name-mixedcase
  bytes32 public DOMAIN_SEPARATOR;
  // solhint-disable-next-line var-name-mixedcase
  bytes32 public CLAIM_TYPEHASH;

  bytes32 internal constant EIP712_DOMAIN =
    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');

  /// @dev spender => next valid nonce to submit with permit()
  mapping(address => uint256) public _nonces;

  string private _rewardPoolName;

  mapping(address => bool) private _providers;

  constructor(string memory rewardPoolName) {
    _rewardPoolName = rewardPoolName;
    _initializeDomainSeparator();
  }

  function _initialize(
    IRewardController controller,
    uint256 initialRate,
    uint16 baselinePercentage,
    string memory rewardPoolName
  ) internal override {
    _rewardPoolName = rewardPoolName;
    _initializeDomainSeparator();
    super._initialize(controller, initialRate, baselinePercentage, rewardPoolName);
  }

  function _initializeDomainSeparator() internal {
    uint256 chainId;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(EIP712_DOMAIN, keccak256(bytes(_rewardPoolName)), keccak256(EIP712_REVISION), chainId, address(this))
    );
    CLAIM_TYPEHASH = getClaimTypeHash();
  }

  /// @dev returns nonce, to comply with eip-2612
  function nonces(address addr) external view returns (uint256) {
    return _nonces[addr];
  }

  function getPoolName() public view override returns (string memory) {
    return _rewardPoolName;
  }

  function availableReward() public view virtual returns (uint256);

  function getClaimTypeHash() internal pure virtual returns (bytes32);

  function addRewardProvider(address provider, address token) external override onlyConfigAdmin {
    require(provider != address(0), 'provider is required');
    require(token == address(0), 'token is unsupported');
    _providers[provider] = true;
    emit ProviderAdded(provider, token);
  }

  function removeRewardProvider(address provider) external override onlyConfigAdmin {
    delete (_providers[provider]);
    emit ProviderRemoved(provider);
  }

  function doClaimRewardByPermit(
    address provider,
    address spender,
    address to,
    uint256 value,
    uint256 at,
    bytes32 encodedHash,
    uint256 currentValidNonce,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal {
    require(provider != address(0) && _providers[provider], 'INVALID_PROVIDER');

    bytes32 digest = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, encodedHash));
    require(provider == ecrecover(digest, v, r, s), 'INVALID_SIGNATURE');

    _nonces[spender] = internalCheckNonce(currentValidNonce, at);

    if (value == 0) {
      return;
    }

    internalUpdateFunds(value);
    internalPushReward(to, value, uint32(block.timestamp));
  }

  function internalUpdateFunds(uint256 value) internal virtual;

  function internalCheckNonce(uint256 nonce, uint256 at) internal virtual returns (uint256);

  function internalPushReward(
    address holder,
    uint256 allocated,
    uint32 since
  ) internal virtual {
    internalAllocateReward(holder, allocated, since, AllocationMode.Push);
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

  string public constant CALLER_NOT_LENDING_POOL = '29'; // The caller of this function must be a lending pool

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
  string public constant STK_EXCESSIVE_COOLDOWN_PERIOD = '98';
  string public constant STK_WRONG_UNSTAKE_PERIOD = '99';

  string public constant TXT_OWNABLE_CALLER_NOT_OWNER = 'Ownable: caller is not the owner';
  string public constant TXT_CALLER_NOT_PROXY_OWNER = 'ProxyOwner: caller is not the owner';
  string public constant TXT_ACCESS_RESTRICTED = 'RESTRICTED';
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
  @dev Represents a registry for referral codes
  There are 3 categories of codes:
  - short codes (refCode <= type(uint32).max) - can only be registred by an admin
  - default codes (will all 32 lower bits set to 1) - each address has a pre-owned ref code
  - custom codes - anything else

  An owner of a ref code can transfer it to another owner.
 */
interface IReferralRegistry {
  /// @dev registers an un-owned custom `refCode` code for `owner`. Reverts on an owned or non-custom code.
  function registerCustomCode(uint256 refCode, address owner) external;

  /// @dev returns a default ref code for the given address. Result wont change if the code was given away.
  function defaultCode(address addr) external view returns (uint256 refCode);

  /// @dev transfers the ref code to a new owner. Reverts when the caller is not a current owner.
  function transferCodeTo(uint256 refCode, address to) external;

  /// @dev returns timestamps (e.g. of the last reward claim) for the given `codes`.
  /// When the `owner` doesn't own a code, value of type(uint32).max is returned for such code.
  function timestampsOf(address owner, uint256[] calldata codes)
    external
    view
    returns (uint32[] memory timestamps);

  event RefCodeDelegated(uint256 indexed refCode, address from, address indexed to);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/// @dev Replacement of SafeMath to use with solc 0.8
library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    return a + b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return a - b;
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    unchecked {
      return a - b;
    }
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    return a * b;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return a % b;
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

  uint16 internal constant NO_BASELINE = type(uint16).max;

  IRewardController private _controller;

  uint256 private _pausedRate;
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

    if (baselinePercentage == NO_BASELINE || (initialRate != 0 && baselinePercentage == 0)) {
      _baselinePercentage = NO_BASELINE;
      emit BaselineDisabled();
    } else if (baselinePercentage > 0) {
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
    if (_baselinePercentage == NO_BASELINE) {
      return (false, internalGetRate());
    }
    appliedRate = baseline.percentMul(_baselinePercentage);
    _setRate(appliedRate);
    return (true, appliedRate);
  }

  function disableBaseline() external onlyRateAdmin {
    _baselinePercentage = NO_BASELINE;
    emit BaselineDisabled();
  }

  function setBaselinePercentage(uint16 factor) external override onlyRateAdmin {
    _setBaselinePercentage(factor);
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

  function _setBaselinePercentage(uint16 factor) internal virtual {
    require(address(_controller) != address(0), 'controller is required');

    require(factor <= PercentageMath.ONE, 'illegal value');
    _baselinePercentage = factor;
    emit BaselineFactorUpdated(factor);
  }

  function _setRate(uint256 rate) internal {
    require(address(_controller) != address(0), 'controller is required');

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

  function claimRewardFor(address holder, uint256 limit) external override onlyController returns (uint256, uint32) {
    return internalGetReward(holder, limit);
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

  function internalGetReward(address holder, uint256 limit) internal virtual returns (uint256, uint32);

  function internalCalcReward(address holder, uint32 at) internal view virtual returns (uint256, uint32);

  function attachedToRewardController() external override onlyController {
    internalAttachedToRewardController();
  }

  function internalAttachedToRewardController() internal virtual {}

  function isController(address addr) internal view virtual returns (bool) {
    return address(_controller) == addr;
  }

  function getAccessController() internal view virtual returns (IMarketAccessController) {
    return _controller.getAccessController();
  }

  function _onlyController() private view {
    require(isController(msg.sender), Errors.CALLER_NOT_REWARD_CONTROLLER);
  }

  modifier onlyController() {
    _onlyController();
    _;
  }

  function _isConfigAdmin(address addr) internal view returns (bool) {
    return _controller.isConfigAdmin(addr);
  }

  function _onlyConfigAdmin() private view {
    require(_controller.isConfigAdmin(msg.sender), Errors.CALLER_NOT_REWARD_CONFIG_ADMIN);
  }

  modifier onlyConfigAdmin() {
    _onlyConfigAdmin();
    _;
  }

  function _onlyRateAdmin() private view {
    require(_controller.isRateAdmin(msg.sender), Errors.CALLER_NOT_REWARD_RATE_ADMIN);
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

import '../../interfaces/IEmergencyAccess.sol';

interface IManagedRewardPool is IEmergencyAccess {
  function updateBaseline(uint256) external returns (bool hasBaseline, uint256 appliedRate);

  function setBaselinePercentage(uint16) external;

  function getBaselinePercentage() external view returns (bool, uint16);

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

