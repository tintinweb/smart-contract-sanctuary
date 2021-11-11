// SPDX-License-Identifier: MIT

/*

Coded for The Keep3r Network with ♥ by

██████╗░███████╗███████╗██╗  ░██╗░░░░░░░██╗░█████╗░███╗░░██╗██████╗░███████╗██████╗░██╗░░░░░░█████╗░███╗░░██╗██████╗░
██╔══██╗██╔════╝██╔════╝██║  ░██║░░██╗░░██║██╔══██╗████╗░██║██╔══██╗██╔════╝██╔══██╗██║░░░░░██╔══██╗████╗░██║██╔══██╗
██║░░██║█████╗░░█████╗░░██║  ░╚██╗████╗██╔╝██║░░██║██╔██╗██║██║░░██║█████╗░░██████╔╝██║░░░░░███████║██╔██╗██║██║░░██║
██║░░██║██╔══╝░░██╔══╝░░██║  ░░████╔═████║░██║░░██║██║╚████║██║░░██║██╔══╝░░██╔══██╗██║░░░░░██╔══██║██║╚████║██║░░██║
██████╔╝███████╗██║░░░░░██║  ░░╚██╔╝░╚██╔╝░╚█████╔╝██║░╚███║██████╔╝███████╗██║░░██║███████╗██║░░██║██║░╚███║██████╔╝
╚═════╝░╚══════╝╚═╝░░░░░╚═╝  ░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚══╝╚═════╝░╚══════╝╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

https://defi.sucks

*/

pragma solidity >=0.8.4 <0.9.0;

import './peripherals/jobs/Keep3rJobs.sol';
import './peripherals/keepers/Keep3rKeepers.sol';
import './peripherals/Keep3rAccountance.sol';
import './peripherals/Keep3rRoles.sol';
import './peripherals/Keep3rParameters.sol';
import './peripherals/DustCollector.sol';

contract Keep3r is DustCollector, Keep3rJobs, Keep3rKeepers {
  constructor(
    address _governance,
    address _keep3rHelper,
    address _keep3rV1,
    address _keep3rV1Proxy,
    address _kp3rWethPool
  ) Keep3rParameters(_keep3rHelper, _keep3rV1, _keep3rV1Proxy, _kp3rWethPool) Keep3rRoles(_governance) DustCollector() {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './Keep3rJobDisputable.sol';
import './Keep3rJobWorkable.sol';
import './Keep3rJobManager.sol';

abstract contract Keep3rJobs is Keep3rJobDisputable, Keep3rJobManager, Keep3rJobWorkable {}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './Keep3rKeeperDisputable.sol';

abstract contract Keep3rKeepers is Keep3rKeeperDisputable {}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '../../interfaces/peripherals/IKeep3rAccountance.sol';

abstract contract Keep3rAccountance is IKeep3rAccountance {
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @notice List of all enabled keepers
  EnumerableSet.AddressSet internal _keepers;

  /// @inheritdoc IKeep3rAccountance
  mapping(address => uint256) public override workCompleted;

  /// @inheritdoc IKeep3rAccountance
  mapping(address => uint256) public override firstSeen;

  /// @inheritdoc IKeep3rAccountance
  mapping(address => bool) public override disputes;

  /// @inheritdoc IKeep3rAccountance
  /// @notice Mapping (job => bonding => amount)
  mapping(address => mapping(address => uint256)) public override bonds;

  /// @inheritdoc IKeep3rAccountance
  mapping(address => mapping(address => uint256)) public override jobTokenCredits;

  /// @notice The current liquidity credits available for a job
  mapping(address => uint256) internal _jobLiquidityCredits;

  /// @notice Map the address of a job to its correspondent periodCredits
  mapping(address => uint256) internal _jobPeriodCredits;

  /// @notice Enumerable array of Job Tokens for Credits
  mapping(address => EnumerableSet.AddressSet) internal _jobTokens;

  /// @notice List of liquidities that a job has (job => liquidities)
  mapping(address => EnumerableSet.AddressSet) internal _jobLiquidities;

  /// @notice Liquidity pool to observe
  mapping(address => address) internal _liquidityPool;

  /// @notice Tracks if a pool has KP3R as token0
  mapping(address => bool) internal _isKP3RToken0;

  /// @inheritdoc IKeep3rAccountance
  mapping(address => mapping(address => uint256)) public override pendingBonds;

  /// @inheritdoc IKeep3rAccountance
  mapping(address => mapping(address => uint256)) public override canActivateAfter;

  /// @inheritdoc IKeep3rAccountance
  mapping(address => mapping(address => uint256)) public override canWithdrawAfter;

  /// @inheritdoc IKeep3rAccountance
  mapping(address => mapping(address => uint256)) public override pendingUnbonds;

  /// @inheritdoc IKeep3rAccountance
  mapping(address => bool) public override hasBonded;

  /// @notice List of all enabled jobs
  EnumerableSet.AddressSet internal _jobs;

  /// @inheritdoc IKeep3rAccountance
  function jobs() external view override returns (address[] memory _list) {
    _list = _jobs.values();
  }

  /// @inheritdoc IKeep3rAccountance
  function keepers() external view override returns (address[] memory _list) {
    _list = _keepers.values();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '../../interfaces/peripherals/IKeep3rRoles.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import './Governable.sol';

contract Keep3rRoles is IKeep3rRoles, Governable {
  /// @inheritdoc IKeep3rRoles
  mapping(address => bool) public override slashers;

  /// @inheritdoc IKeep3rRoles
  mapping(address => bool) public override disputers;

  constructor(address _governance) Governable(_governance) {}

  /// @inheritdoc IKeep3rRoles
  function addSlasher(address _slasher) external override onlyGovernance {
    if (slashers[_slasher]) revert SlasherExistent();
    slashers[_slasher] = true;
    emit SlasherAdded(_slasher);
  }

  /// @inheritdoc IKeep3rRoles
  function removeSlasher(address _slasher) external override onlyGovernance {
    if (!slashers[_slasher]) revert SlasherUnexistent();
    delete slashers[_slasher];
    emit SlasherRemoved(_slasher);
  }

  /// @inheritdoc IKeep3rRoles
  function addDisputer(address _disputer) external override onlyGovernance {
    if (disputers[_disputer]) revert DisputerExistent();
    disputers[_disputer] = true;
    emit DisputerAdded(_disputer);
  }

  /// @inheritdoc IKeep3rRoles
  function removeDisputer(address _disputer) external override onlyGovernance {
    if (!disputers[_disputer]) revert DisputerUnexistent();
    delete disputers[_disputer];
    emit DisputerRemoved(_disputer);
  }

  /// @notice Functions with this modifier can only be called by either a slasher or governance
  modifier onlySlasher {
    if (!slashers[msg.sender]) revert OnlySlasher();
    _;
  }

  /// @notice Functions with this modifier can only be called by either a disputer or governance
  modifier onlyDisputer {
    if (!disputers[msg.sender]) revert OnlyDisputer();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '../../interfaces/IKeep3rHelper.sol';
import '../../interfaces/peripherals/IKeep3rParameters.sol';
import './Keep3rAccountance.sol';
import './Keep3rRoles.sol';

abstract contract Keep3rParameters is IKeep3rParameters, Keep3rAccountance, Keep3rRoles {
  /// @inheritdoc IKeep3rParameters
  address public override keep3rV1;

  /// @inheritdoc IKeep3rParameters
  address public override keep3rV1Proxy;

  /// @inheritdoc IKeep3rParameters
  address public override keep3rHelper;

  /// @inheritdoc IKeep3rParameters
  address public override kp3rWethPool;

  /// @inheritdoc IKeep3rParameters
  uint256 public override bondTime = 3 days;

  /// @inheritdoc IKeep3rParameters
  uint256 public override unbondTime = 14 days;

  /// @inheritdoc IKeep3rParameters
  uint256 public override liquidityMinimum = 3 ether;

  /// @inheritdoc IKeep3rParameters
  uint256 public override rewardPeriodTime = 5 days;

  /// @inheritdoc IKeep3rParameters
  uint256 public override inflationPeriod = 34 days;

  /// @inheritdoc IKeep3rParameters
  uint256 public override fee = 30;

  /// @inheritdoc IKeep3rParameters
  uint256 public constant override BASE = 10000;

  /// @inheritdoc IKeep3rParameters
  uint256 public constant override MIN_REWARD_PERIOD_TIME = 1 days;

  constructor(
    address _keep3rHelper,
    address _keep3rV1,
    address _keep3rV1Proxy,
    address _kp3rWethPool
  ) {
    keep3rHelper = _keep3rHelper;
    keep3rV1 = _keep3rV1;
    keep3rV1Proxy = _keep3rV1Proxy;
    kp3rWethPool = _kp3rWethPool;
    _liquidityPool[kp3rWethPool] = kp3rWethPool;
    _isKP3RToken0[_kp3rWethPool] = IKeep3rHelper(keep3rHelper).isKP3RToken0(kp3rWethPool);
  }

  /// @inheritdoc IKeep3rParameters
  function setKeep3rHelper(address _keep3rHelper) external override onlyGovernance {
    if (_keep3rHelper == address(0)) revert ZeroAddress();
    keep3rHelper = _keep3rHelper;
    emit Keep3rHelperChange(_keep3rHelper);
  }

  /// @inheritdoc IKeep3rParameters
  function setKeep3rV1(address _keep3rV1) external override onlyGovernance {
    if (_keep3rV1 == address(0)) revert ZeroAddress();
    keep3rV1 = _keep3rV1;
    emit Keep3rV1Change(_keep3rV1);
  }

  /// @inheritdoc IKeep3rParameters
  function setKeep3rV1Proxy(address _keep3rV1Proxy) external override onlyGovernance {
    if (_keep3rV1Proxy == address(0)) revert ZeroAddress();
    keep3rV1Proxy = _keep3rV1Proxy;
    emit Keep3rV1ProxyChange(_keep3rV1Proxy);
  }

  /// @inheritdoc IKeep3rParameters
  function setKp3rWethPool(address _kp3rWethPool) external override onlyGovernance {
    if (_kp3rWethPool == address(0)) revert ZeroAddress();
    kp3rWethPool = _kp3rWethPool;
    _liquidityPool[kp3rWethPool] = kp3rWethPool;
    _isKP3RToken0[_kp3rWethPool] = IKeep3rHelper(keep3rHelper).isKP3RToken0(_kp3rWethPool);
    emit Kp3rWethPoolChange(_kp3rWethPool);
  }

  /// @inheritdoc IKeep3rParameters
  function setBondTime(uint256 _bondTime) external override onlyGovernance {
    bondTime = _bondTime;
    emit BondTimeChange(_bondTime);
  }

  /// @inheritdoc IKeep3rParameters
  function setUnbondTime(uint256 _unbondTime) external override onlyGovernance {
    unbondTime = _unbondTime;
    emit UnbondTimeChange(_unbondTime);
  }

  /// @inheritdoc IKeep3rParameters
  function setLiquidityMinimum(uint256 _liquidityMinimum) external override onlyGovernance {
    liquidityMinimum = _liquidityMinimum;
    emit LiquidityMinimumChange(_liquidityMinimum);
  }

  /// @inheritdoc IKeep3rParameters
  function setRewardPeriodTime(uint256 _rewardPeriodTime) external override onlyGovernance {
    if (_rewardPeriodTime < MIN_REWARD_PERIOD_TIME) revert MinRewardPeriod();
    rewardPeriodTime = _rewardPeriodTime;
    emit RewardPeriodTimeChange(_rewardPeriodTime);
  }

  /// @inheritdoc IKeep3rParameters
  function setInflationPeriod(uint256 _inflationPeriod) external override onlyGovernance {
    inflationPeriod = _inflationPeriod;
    emit InflationPeriodChange(_inflationPeriod);
  }

  /// @inheritdoc IKeep3rParameters
  function setFee(uint256 _fee) external override onlyGovernance {
    fee = _fee;
    emit FeeChange(_fee);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../../contracts/peripherals/Governable.sol';
import '../../interfaces/peripherals/IDustCollector.sol';

abstract contract DustCollector is IDustCollector, Governable {
  using SafeERC20 for IERC20;

  address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  function sendDust(
    address _token,
    uint256 _amount,
    address _to
  ) external override onlyGovernance {
    if (_to == address(0)) revert ZeroAddress();
    if (_token == ETH_ADDRESS) {
      payable(_to).transfer(_amount);
    } else {
      IERC20(_token).safeTransfer(_to, _amount);
    }
    emit DustSent(_token, _amount, _to);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './Keep3rJobFundableCredits.sol';
import './Keep3rJobFundableLiquidity.sol';
import '../Keep3rDisputable.sol';

abstract contract Keep3rJobDisputable is IKeep3rJobDisputable, Keep3rDisputable, Keep3rJobFundableCredits, Keep3rJobFundableLiquidity {
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  /// @inheritdoc IKeep3rJobDisputable
  function slashTokenFromJob(
    address _job,
    address _token,
    uint256 _amount
  ) external override onlySlasher {
    if (!disputes[_job]) revert NotDisputed();
    if (!_jobTokens[_job].contains(_token)) revert JobTokenUnexistent();
    if (jobTokenCredits[_job][_token] < _amount) revert JobTokenInsufficient();

    try IERC20(_token).transfer(governance, _amount) {} catch {}
    jobTokenCredits[_job][_token] -= _amount;
    if (jobTokenCredits[_job][_token] == 0) {
      _jobTokens[_job].remove(_token);
    }

    // emit event
    emit JobSlashToken(_job, _token, msg.sender, _amount);
  }

  /// @inheritdoc IKeep3rJobDisputable
  function slashLiquidityFromJob(
    address _job,
    address _liquidity,
    uint256 _amount
  ) external override onlySlasher {
    if (!disputes[_job]) revert NotDisputed();

    _unbondLiquidityFromJob(_job, _liquidity, _amount);
    try IERC20(_liquidity).transfer(governance, _amount) {} catch {}
    emit JobSlashLiquidity(_job, _liquidity, msg.sender, _amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './Keep3rJobMigration.sol';
import '../../../interfaces/IKeep3rHelper.sol';
import '../../../interfaces/peripherals/IKeep3rJobs.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

abstract contract Keep3rJobWorkable is IKeep3rJobWorkable, Keep3rJobMigration {
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  uint256 internal _initialGas;

  /// @inheritdoc IKeep3rJobWorkable
  function isKeeper(address _keeper) external override returns (bool _isKeeper) {
    _initialGas = gasleft();
    if (_keepers.contains(_keeper)) {
      emit KeeperValidation(gasleft());
      return true;
    }
  }

  /// @inheritdoc IKeep3rJobWorkable
  function isBondedKeeper(
    address _keeper,
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age
  ) public override returns (bool _isBondedKeeper) {
    _initialGas = gasleft();
    if (
      _keepers.contains(_keeper) &&
      bonds[_keeper][_bond] >= _minBond &&
      workCompleted[_keeper] >= _earned &&
      block.timestamp - firstSeen[_keeper] >= _age
    ) {
      emit KeeperValidation(gasleft());
      return true;
    }
  }

  /// @inheritdoc IKeep3rJobWorkable
  function worked(address _keeper) external override {
    address _job = msg.sender;
    if (disputes[_job]) revert JobDisputed();
    if (!_jobs.contains(_job)) revert JobUnapproved();

    if (_updateJobCreditsIfNeeded(_job)) {
      emit LiquidityCreditsReward(_job, rewardedAt[_job], _jobLiquidityCredits[_job], _jobPeriodCredits[_job]);
    }

    uint256 _gasRecord = gasleft();
    uint256 _boost = IKeep3rHelper(keep3rHelper).getRewardBoostFor(bonds[_keeper][keep3rV1]);

    uint256 _payment = (_quoteLiquidity(_initialGas - _gasRecord, kp3rWethPool) * _boost) / BASE;

    if (_payment > _jobLiquidityCredits[_job]) {
      _rewardJobCredits(_job);
      emit LiquidityCreditsReward(_job, rewardedAt[_job], _jobLiquidityCredits[_job], _jobPeriodCredits[_job]);
    }

    uint256 _gasUsed = _initialGas - gasleft();
    _payment = (_gasUsed * _payment) / (_initialGas - _gasRecord);

    _bondedPayment(_job, _keeper, _payment);
    emit KeeperWork(keep3rV1, _job, _keeper, _payment, gasleft());
  }

  /// @inheritdoc IKeep3rJobWorkable
  function bondedPayment(address _keeper, uint256 _payment) public override {
    address _job = msg.sender;

    if (disputes[_job]) revert JobDisputed();
    if (!_jobs.contains(_job)) revert JobUnapproved();

    if (_updateJobCreditsIfNeeded(_job)) {
      emit LiquidityCreditsReward(_job, rewardedAt[_job], _jobLiquidityCredits[_job], _jobPeriodCredits[_job]);
    }

    if (_payment > _jobLiquidityCredits[_job]) {
      _rewardJobCredits(_job);
      emit LiquidityCreditsReward(_job, rewardedAt[_job], _jobLiquidityCredits[_job], _jobPeriodCredits[_job]);
    }

    _bondedPayment(_job, _keeper, _payment);
    emit KeeperWork(keep3rV1, _job, _keeper, _payment, gasleft());
  }

  function _bondedPayment(
    address _job,
    address _keeper,
    uint256 _payment
  ) internal {
    if (_payment > _jobLiquidityCredits[_job]) revert InsufficientFunds();

    workedAt[_job] = block.timestamp;
    _jobLiquidityCredits[_job] -= _payment;
    bonds[_keeper][keep3rV1] += _payment;
    workCompleted[_keeper] += _payment;
  }

  /// @inheritdoc IKeep3rJobWorkable
  function directTokenPayment(
    address _token,
    address _keeper,
    uint256 _amount
  ) external override {
    address _job = msg.sender;

    if (disputes[_job]) revert JobDisputed();
    if (disputes[_keeper]) revert Disputed();
    if (!_jobs.contains(_job)) revert JobUnapproved();
    if (jobTokenCredits[_job][_token] < _amount) revert InsufficientFunds();
    jobTokenCredits[_job][_token] -= _amount;
    IERC20(_token).safeTransfer(_keeper, _amount);
    emit KeeperWork(_token, _job, _keeper, _amount, gasleft());
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './Keep3rJobOwnership.sol';
import '../Keep3rRoles.sol';
import '../Keep3rParameters.sol';
import '../../../interfaces/peripherals/IKeep3rJobs.sol';

abstract contract Keep3rJobManager is IKeep3rJobManager, Keep3rJobOwnership, Keep3rRoles, Keep3rParameters {
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @inheritdoc IKeep3rJobManager
  function addJob(address _job) external override {
    if (_jobs.contains(_job)) revert JobAlreadyAdded();
    if (hasBonded[_job]) revert AlreadyAKeeper();
    _jobs.add(_job);
    jobOwner[_job] = msg.sender;
    emit JobAddition(msg.sender, _job);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './Keep3rJobOwnership.sol';
import '../Keep3rAccountance.sol';
import '../Keep3rParameters.sol';
import '../../../interfaces/peripherals/IKeep3rJobs.sol';

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

abstract contract Keep3rJobFundableCredits is IKeep3rJobFundableCredits, ReentrancyGuard, Keep3rJobOwnership, Keep3rParameters {
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  /// @notice Cooldown between withdrawals
  uint256 internal constant _WITHDRAW_TOKENS_COOLDOWN = 1 minutes;

  /// @inheritdoc IKeep3rJobFundableCredits
  mapping(address => mapping(address => uint256)) public override jobTokenCreditsAddedAt;

  /// @inheritdoc IKeep3rJobFundableCredits
  function addTokenCreditsToJob(
    address _job,
    address _token,
    uint256 _amount
  ) external override nonReentrant {
    if (!_jobs.contains(_job)) revert JobUnavailable();
    // KP3R shouldn't be used for direct token payments
    if (_token == keep3rV1) revert TokenUnallowed();
    uint256 _before = IERC20(_token).balanceOf(address(this));
    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    uint256 _received = IERC20(_token).balanceOf(address(this)) - _before;
    uint256 _tokenFee = (_received * fee) / BASE;
    jobTokenCredits[_job][_token] += _received - _tokenFee;
    jobTokenCreditsAddedAt[_job][_token] = block.timestamp;
    IERC20(_token).safeTransfer(governance, _tokenFee);
    _jobTokens[_job].add(_token);

    emit TokenCreditAddition(_job, _token, msg.sender, _received);
  }

  /// @inheritdoc IKeep3rJobFundableCredits
  function withdrawTokenCreditsFromJob(
    address _job,
    address _token,
    uint256 _amount,
    address _receiver
  ) external override nonReentrant onlyJobOwner(_job) {
    if (block.timestamp <= jobTokenCreditsAddedAt[_job][_token] + _WITHDRAW_TOKENS_COOLDOWN) revert JobTokenCreditsLocked();
    if (jobTokenCredits[_job][_token] < _amount) revert InsufficientJobTokenCredits();
    if (disputes[_job]) revert JobDisputed();

    jobTokenCredits[_job][_token] -= _amount;
    IERC20(_token).safeTransfer(_receiver, _amount);

    if (jobTokenCredits[_job][_token] == 0) {
      _jobTokens[_job].remove(_token);
    }

    emit TokenCreditWithdrawal(_job, _token, _receiver, _amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './Keep3rJobOwnership.sol';
import '../Keep3rAccountance.sol';
import '../Keep3rParameters.sol';
import '../../../interfaces/IPairManager.sol';
import '../../../interfaces/peripherals/IKeep3rJobs.sol';

import '../../libraries/FullMath.sol';

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

abstract contract Keep3rJobFundableLiquidity is IKeep3rJobFundableLiquidity, ReentrancyGuard, Keep3rJobOwnership, Keep3rParameters {
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  /// @notice List of liquidities that are accepted in the system
  EnumerableSet.AddressSet internal _approvedLiquidities;

  /// @inheritdoc IKeep3rJobFundableLiquidity
  mapping(address => mapping(address => uint256)) public override liquidityAmount;

  /// @inheritdoc IKeep3rJobFundableLiquidity
  mapping(address => uint256) public override rewardedAt;

  /// @inheritdoc IKeep3rJobFundableLiquidity
  mapping(address => uint256) public override workedAt;

  /// @notice Tracks an address and returns its TickCache
  mapping(address => TickCache) internal _tick;

  // Views

  /// @inheritdoc IKeep3rJobFundableLiquidity
  function approvedLiquidities() external view override returns (address[] memory _list) {
    _list = _approvedLiquidities.values();
  }

  /// @inheritdoc IKeep3rJobFundableLiquidity
  function jobPeriodCredits(address _job) public view override returns (uint256 _periodCredits) {
    for (uint256 i; i < _jobLiquidities[_job].length(); i++) {
      address _liquidity = _jobLiquidities[_job].at(i);
      if (_approvedLiquidities.contains(_liquidity)) {
        TickCache memory _tickCache = observeLiquidity(_liquidity);
        if (_tickCache.period != 0) {
          int56 _tickDifference = _isKP3RToken0[_liquidity] ? _tickCache.difference : -_tickCache.difference;
          _periodCredits += _getReward(
            IKeep3rHelper(keep3rHelper).getKP3RsAtTick(liquidityAmount[_job][_liquidity], _tickDifference, rewardPeriodTime)
          );
        }
      }
    }
  }

  /// @inheritdoc IKeep3rJobFundableLiquidity
  function jobLiquidityCredits(address _job) public view override returns (uint256 _liquidityCredits) {
    uint256 _periodCredits = jobPeriodCredits(_job);

    // A job can have liquidityCredits without periodCredits (forced by Governance)
    if (rewardedAt[_job] > _period(block.timestamp - rewardPeriodTime)) {
      // Will calculate job credits only if it was rewarded later than last period
      if ((block.timestamp - rewardedAt[_job]) >= rewardPeriodTime) {
        // Will return a full period if job was rewarded more than a period ago
        _liquidityCredits = _periodCredits;
      } else {
        // Will update minted job credits (not forced) to new twaps if credits are outdated
        _liquidityCredits = _periodCredits > 0
          ? (_jobLiquidityCredits[_job] * _periodCredits) / _jobPeriodCredits[_job]
          : _jobLiquidityCredits[_job];
      }
    } else {
      // Will return a full period if job credits are expired
      _liquidityCredits = _periodCredits;
    }
  }

  /// @inheritdoc IKeep3rJobFundableLiquidity
  function totalJobCredits(address _job) external view override returns (uint256 _credits) {
    uint256 _periodCredits = jobPeriodCredits(_job);
    uint256 _cooldown;

    if ((rewardedAt[_job] > _period(block.timestamp - rewardPeriodTime))) {
      // Will calculate cooldown if it outdated
      if ((block.timestamp - rewardedAt[_job]) >= rewardPeriodTime) {
        // Will calculate cooldown from last reward reference in this period
        _cooldown = block.timestamp - (rewardedAt[_job] + rewardPeriodTime);
      } else {
        // Will calculate cooldown from last reward timestamp
        _cooldown = block.timestamp - rewardedAt[_job];
      }
    } else {
      // Will calculate cooldown from period start if expired
      _cooldown = block.timestamp - _period(block.timestamp);
    }
    _credits = jobLiquidityCredits(_job) + _phase(_cooldown, _periodCredits);
  }

  /// @inheritdoc IKeep3rJobFundableLiquidity
  function quoteLiquidity(address _liquidity, uint256 _amount) external view override returns (uint256 _periodCredits) {
    if (_approvedLiquidities.contains(_liquidity)) {
      TickCache memory _tickCache = observeLiquidity(_liquidity);
      if (_tickCache.period != 0) {
        int56 _tickDifference = _isKP3RToken0[_liquidity] ? _tickCache.difference : -_tickCache.difference;
        return _getReward(IKeep3rHelper(keep3rHelper).getKP3RsAtTick(_amount, _tickDifference, rewardPeriodTime));
      }
    }
  }

  /// @inheritdoc IKeep3rJobFundableLiquidity
  function observeLiquidity(address _liquidity) public view override returns (TickCache memory _tickCache) {
    if (_tick[_liquidity].period == _period(block.timestamp)) {
      // Will return cached twaps if liquidity is updated
      _tickCache = _tick[_liquidity];
    } else {
      bool success;
      uint256 lastPeriod = _period(block.timestamp - rewardPeriodTime);

      if (_tick[_liquidity].period == lastPeriod) {
        // Will only ask for current period accumulator if liquidity is outdated
        uint32[] memory _secondsAgo = new uint32[](1);
        int56 previousTick = _tick[_liquidity].current;

        _secondsAgo[0] = uint32(block.timestamp - _period(block.timestamp));

        (_tickCache.current, , success) = IKeep3rHelper(keep3rHelper).observe(_liquidityPool[_liquidity], _secondsAgo);

        _tickCache.difference = _tickCache.current - previousTick;
      } else if (_tick[_liquidity].period < lastPeriod) {
        // Will ask for 2 accumulators if liquidity is expired
        uint32[] memory _secondsAgo = new uint32[](2);

        _secondsAgo[0] = uint32(block.timestamp - _period(block.timestamp));
        _secondsAgo[1] = uint32(block.timestamp - _period(block.timestamp) + rewardPeriodTime);

        int56 _tickCumulative2;
        (_tickCache.current, _tickCumulative2, success) = IKeep3rHelper(keep3rHelper).observe(_liquidityPool[_liquidity], _secondsAgo);

        _tickCache.difference = _tickCache.current - _tickCumulative2;
      }
      if (success) {
        _tickCache.period = _period(block.timestamp);
      } else {
        _tickCache.period = 0;
      }
    }
  }

  // Methods

  /// @inheritdoc IKeep3rJobFundableLiquidity
  function forceLiquidityCreditsToJob(address _job, uint256 _amount) external override onlyGovernance {
    if (!_jobs.contains(_job)) revert JobUnavailable();
    _settleJobAccountance(_job);
    _jobLiquidityCredits[_job] += _amount;
    emit LiquidityCreditsForced(_job, rewardedAt[_job], _jobLiquidityCredits[_job]);
  }

  /// @inheritdoc IKeep3rJobFundableLiquidity
  function approveLiquidity(address _liquidity) external override onlyGovernance {
    if (!_approvedLiquidities.add(_liquidity)) revert LiquidityPairApproved();
    _liquidityPool[_liquidity] = IPairManager(_liquidity).pool();
    _isKP3RToken0[_liquidity] = IKeep3rHelper(keep3rHelper).isKP3RToken0(_liquidityPool[_liquidity]);
    _tick[_liquidity] = observeLiquidity(_liquidity);
    emit LiquidityApproval(_liquidity);
  }

  /// @inheritdoc IKeep3rJobFundableLiquidity
  function revokeLiquidity(address _liquidity) external override onlyGovernance {
    if (!_approvedLiquidities.remove(_liquidity)) revert LiquidityPairUnexistent();
    emit LiquidityRevocation(_liquidity);
  }

  /// @inheritdoc IKeep3rJobFundableLiquidity
  function addLiquidityToJob(
    address _job,
    address _liquidity,
    uint256 _amount
  ) external override nonReentrant {
    if (!_approvedLiquidities.contains(_liquidity)) revert LiquidityPairUnapproved();
    if (!_jobs.contains(_job)) revert JobUnavailable();

    _jobLiquidities[_job].add(_liquidity);

    _settleJobAccountance(_job);

    if (_quoteLiquidity(liquidityAmount[_job][_liquidity] + _amount, _liquidity) < liquidityMinimum) revert JobLiquidityLessThanMin();

    emit LiquidityCreditsReward(_job, rewardedAt[_job], _jobLiquidityCredits[_job], _jobPeriodCredits[_job]);

    IERC20(_liquidity).safeTransferFrom(msg.sender, address(this), _amount);
    liquidityAmount[_job][_liquidity] += _amount;
    _jobPeriodCredits[_job] += _getReward(_quoteLiquidity(_amount, _liquidity));
    emit LiquidityAddition(_job, _liquidity, msg.sender, _amount);
  }

  /// @inheritdoc IKeep3rJobFundableLiquidity
  function unbondLiquidityFromJob(
    address _job,
    address _liquidity,
    uint256 _amount
  ) external override onlyJobOwner(_job) {
    canWithdrawAfter[_job][_liquidity] = block.timestamp + unbondTime;
    pendingUnbonds[_job][_liquidity] += _amount;
    _unbondLiquidityFromJob(_job, _liquidity, _amount);

    uint256 _remainingLiquidity = liquidityAmount[_job][_liquidity];
    if (_remainingLiquidity > 0 && _quoteLiquidity(_remainingLiquidity, _liquidity) < liquidityMinimum) revert JobLiquidityLessThanMin();

    emit Unbonding(_job, _liquidity, _amount);
  }

  /// @inheritdoc IKeep3rJobFundableLiquidity
  function withdrawLiquidityFromJob(
    address _job,
    address _liquidity,
    address _receiver
  ) external override onlyJobOwner(_job) {
    if (_receiver == address(0)) revert ZeroAddress();
    if (canWithdrawAfter[_job][_liquidity] == 0) revert UnbondsUnexistent();
    if (canWithdrawAfter[_job][_liquidity] >= block.timestamp) revert UnbondsLocked();
    if (disputes[_job]) revert Disputed();

    uint256 _amount = pendingUnbonds[_job][_liquidity];
    IERC20(_liquidity).safeTransfer(_receiver, _amount);
    emit LiquidityWithdrawal(_job, _liquidity, _receiver, _amount);

    pendingUnbonds[_job][_liquidity] = 0;
  }

  // Internal functions

  /// @notice Updates or rewards job liquidity credits depending on time since last job reward
  function _updateJobCreditsIfNeeded(address _job) internal returns (bool _rewarded) {
    if (rewardedAt[_job] < _period(block.timestamp)) {
      // Will exit function if job has been rewarded in current period
      if (rewardedAt[_job] <= _period(block.timestamp - rewardPeriodTime)) {
        // Will reset job to period syncronicity if a full period passed without rewards
        _updateJobPeriod(_job);
        _jobLiquidityCredits[_job] = _jobPeriodCredits[_job];
        rewardedAt[_job] = _period(block.timestamp);
        _rewarded = true;
      } else if ((block.timestamp - rewardedAt[_job]) >= rewardPeriodTime) {
        // Will reset job's syncronicity if last reward was more than epoch ago
        _updateJobPeriod(_job);
        _jobLiquidityCredits[_job] = _jobPeriodCredits[_job];
        rewardedAt[_job] += rewardPeriodTime;
        _rewarded = true;
      } else if (workedAt[_job] < _period(block.timestamp)) {
        // First keeper on period has to update job accountance to current twaps
        uint256 previousPeriodCredits = _jobPeriodCredits[_job];
        _updateJobPeriod(_job);
        _jobLiquidityCredits[_job] = (_jobLiquidityCredits[_job] * _jobPeriodCredits[_job]) / previousPeriodCredits;
        // Updating job accountance does not reward job
      }
    }
  }

  /// @notice Only called if _jobLiquidityCredits < payment
  function _rewardJobCredits(address _job) internal {
    /// @notice Only way to += jobLiquidityCredits is when keeper rewarding (cannot pay work)
    /* WARNING: this allows to top up _jobLiquidityCredits to a max of 1.99 but have to spend at least 1 */
    _jobLiquidityCredits[_job] += _phase(block.timestamp - rewardedAt[_job], _jobPeriodCredits[_job]);
    rewardedAt[_job] = block.timestamp;
  }

  /// @notice Updates accountance for _jobPeriodCredits
  function _updateJobPeriod(address _job) internal {
    _jobPeriodCredits[_job] = _calculateJobPeriodCredits(_job);
  }

  /// @notice Quotes the outdated job liquidities and calculates _periodCredits
  /// @dev This function is also responsible for keeping the KP3R/WETH quote updated
  function _calculateJobPeriodCredits(address _job) internal returns (uint256 _periodCredits) {
    if (_tick[kp3rWethPool].period != _period(block.timestamp)) {
      // Updates KP3R/WETH quote if needed
      _tick[kp3rWethPool] = observeLiquidity(kp3rWethPool);
    }

    for (uint256 i; i < _jobLiquidities[_job].length(); i++) {
      address _liquidity = _jobLiquidities[_job].at(i);
      if (_approvedLiquidities.contains(_liquidity)) {
        if (_tick[_liquidity].period != _period(block.timestamp)) {
          // Updates liquidity cache only if needed
          _tick[_liquidity] = observeLiquidity(_liquidity);
        }
        _periodCredits += _getReward(_quoteLiquidity(liquidityAmount[_job][_liquidity], _liquidity));
      }
    }
  }

  /// @notice Updates job accountance calculating the impact of the unbonded liquidity amount
  function _unbondLiquidityFromJob(
    address _job,
    address _liquidity,
    uint256 _amount
  ) internal nonReentrant {
    if (!_jobLiquidities[_job].contains(_liquidity)) revert JobLiquidityUnexistent();
    if (liquidityAmount[_job][_liquidity] < _amount) revert JobLiquidityInsufficient();

    // Ensures current twaps in job liquidities
    _updateJobPeriod(_job);
    uint256 _periodCreditsToRemove = _getReward(_quoteLiquidity(_amount, _liquidity));

    // A liquidity can be revoked causing a job to have 0 periodCredits
    if (_jobPeriodCredits[_job] > 0) {
      // Removes a % correspondant to a full rewardPeriodTime for the liquidity withdrawn vs all of the liquidities
      _jobLiquidityCredits[_job] -= (_jobLiquidityCredits[_job] * _periodCreditsToRemove) / _jobPeriodCredits[_job];
      _jobPeriodCredits[_job] -= _periodCreditsToRemove;
    }

    liquidityAmount[_job][_liquidity] -= _amount;
    if (liquidityAmount[_job][_liquidity] == 0) {
      _jobLiquidities[_job].remove(_liquidity);
    }
  }

  /// @notice Returns a fraction of the multiplier or the whole multiplier if equal or more than a rewardPeriodTime has passed
  function _phase(uint256 _timePassed, uint256 _multiplier) internal view returns (uint256 _result) {
    if (_timePassed < rewardPeriodTime) {
      _result = (_timePassed * _multiplier) / rewardPeriodTime;
    } else _result = _multiplier;
  }

  /// @notice Returns the start of the period of the provided timestamp
  function _period(uint256 _timestamp) internal view returns (uint256 _periodTimestamp) {
    return _timestamp - (_timestamp % rewardPeriodTime);
  }

  /// @notice Calculates relation between rewardPeriod and inflationPeriod
  function _getReward(uint256 _baseAmount) internal view returns (uint256 _credits) {
    return FullMath.mulDiv(_baseAmount, rewardPeriodTime, inflationPeriod);
  }

  /// @notice Returns underlying KP3R amount for a given liquidity amount
  function _quoteLiquidity(uint256 _amount, address _liquidity) internal view returns (uint256 _quote) {
    if (_tick[_liquidity].period != 0) {
      int56 _tickDifference = _isKP3RToken0[_liquidity] ? _tick[_liquidity].difference : -_tick[_liquidity].difference;
      _quote = IKeep3rHelper(keep3rHelper).getKP3RsAtTick(_amount, _tickDifference, rewardPeriodTime);
    }
  }

  /// @notice Updates job credits to current quotes and rewards job's pending minted credits
  /// @dev Ensures a maximum of 1 period of credits
  function _settleJobAccountance(address _job) internal virtual {
    _updateJobCreditsIfNeeded(_job);
    _rewardJobCredits(_job);
    _jobLiquidityCredits[_job] = Math.min(_jobLiquidityCredits[_job], _jobPeriodCredits[_job]);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './Keep3rParameters.sol';
import './Keep3rRoles.sol';
import '../../interfaces/peripherals/IKeep3rDisputable.sol';

abstract contract Keep3rDisputable is IKeep3rDisputable, Keep3rAccountance, Keep3rRoles {
  /// @inheritdoc IKeep3rDisputable
  function dispute(address _jobOrKeeper) external override onlyDisputer {
    if (disputes[_jobOrKeeper]) revert AlreadyDisputed();
    disputes[_jobOrKeeper] = true;
    emit Dispute(_jobOrKeeper, msg.sender);
  }

  /// @inheritdoc IKeep3rDisputable
  function resolve(address _jobOrKeeper) external override onlyDisputer {
    if (!disputes[_jobOrKeeper]) revert NotDisputed();
    disputes[_jobOrKeeper] = false;
    emit Resolve(_jobOrKeeper, msg.sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '../../../interfaces/peripherals/IKeep3rJobs.sol';

abstract contract Keep3rJobOwnership is IKeep3rJobOwnership {
  /// @inheritdoc IKeep3rJobOwnership
  mapping(address => address) public override jobOwner;

  /// @inheritdoc IKeep3rJobOwnership
  mapping(address => address) public override jobPendingOwner;

  /// @inheritdoc IKeep3rJobOwnership
  function changeJobOwnership(address _job, address _newOwner) external override onlyJobOwner(_job) {
    jobPendingOwner[_job] = _newOwner;
    emit JobOwnershipChange(_job, jobOwner[_job], _newOwner);
  }

  /// @inheritdoc IKeep3rJobOwnership
  function acceptJobOwnership(address _job) external override onlyPendingJobOwner(_job) {
    address _previousOwner = jobOwner[_job];

    jobOwner[_job] = jobPendingOwner[_job];
    delete jobPendingOwner[_job];

    emit JobOwnershipAssent(msg.sender, _job, _previousOwner);
  }

  modifier onlyJobOwner(address _job) {
    if (msg.sender != jobOwner[_job]) revert OnlyJobOwner();
    _;
  }

  modifier onlyPendingJobOwner(address _job) {
    if (msg.sender != jobPendingOwner[_job]) revert OnlyPendingJobOwner();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Keep3rJobFundableCredits contract
/// @notice Handles the addition and withdrawal of credits from a job
interface IKeep3rJobFundableCredits {
  // Events

  /// @notice Emitted when Keep3rJobFundableCredits#addTokenCreditsToJob is called
  /// @param _job The address of the job being credited
  /// @param _token The address of the token being provided
  /// @param _provider The user that calls the function
  /// @param _amount The amount of credit being added to the job
  event TokenCreditAddition(address indexed _job, address indexed _token, address indexed _provider, uint256 _amount);

  /// @notice Emitted when Keep3rJobFundableCredits#withdrawTokenCreditsFromJob is called
  /// @param _job The address of the job from which the credits are withdrawn
  /// @param _token The credit being withdrawn from the job
  /// @param _receiver The user that receives the tokens
  /// @param _amount The amount of credit withdrawn
  event TokenCreditWithdrawal(address indexed _job, address indexed _token, address indexed _receiver, uint256 _amount);

  // Errors

  /// @notice Throws when the token is KP3R, as it should not be used for direct token payments
  error TokenUnallowed();

  /// @notice Throws when the token withdraw cooldown has not yet passed
  error JobTokenCreditsLocked();

  /// @notice Throws when the user tries to withdraw more tokens than it has
  error InsufficientJobTokenCredits();

  // Variables

  /// @notice Last block where tokens were added to the job [job => token => timestamp]
  /// @return _timestamp The last block where tokens were added to the job
  function jobTokenCreditsAddedAt(address _job, address _token) external view returns (uint256 _timestamp);

  // Methods

  /// @notice Add credit to a job to be paid out for work
  /// @param _job The address of the job being credited
  /// @param _token The address of the token being credited
  /// @param _amount The amount of credit being added
  function addTokenCreditsToJob(
    address _job,
    address _token,
    uint256 _amount
  ) external;

  /// @notice Withdraw credit from a job
  /// @param _job The address of the job from which the credits are withdrawn
  /// @param _token The address of the token being withdrawn
  /// @param _amount The amount of token to be withdrawn
  /// @param _receiver The user that will receive tokens
  function withdrawTokenCreditsFromJob(
    address _job,
    address _token,
    uint256 _amount,
    address _receiver
  ) external;
}

/// @title  Keep3rJobFundableLiquidity contract
/// @notice Handles the funding of jobs through specific liquidity pairs
interface IKeep3rJobFundableLiquidity {
  // Events

  /// @notice Emitted when Keep3rJobFundableLiquidity#approveLiquidity function is called
  /// @param _liquidity The address of the liquidity pair being approved
  event LiquidityApproval(address _liquidity);

  /// @notice Emitted when Keep3rJobFundableLiquidity#revokeLiquidity function is called
  /// @param _liquidity The address of the liquidity pair being revoked
  event LiquidityRevocation(address _liquidity);

  /// @notice Emitted when IKeep3rJobFundableLiquidity#addLiquidityToJob function is called
  /// @param _job The address of the job to which liquidity will be added
  /// @param _liquidity The address of the liquidity being added
  /// @param _provider The user that calls the function
  /// @param _amount The amount of liquidity being added
  event LiquidityAddition(address indexed _job, address indexed _liquidity, address indexed _provider, uint256 _amount);

  /// @notice Emitted when IKeep3rJobFundableLiquidity#withdrawLiquidityFromJob function is called
  /// @param _job The address of the job of which liquidity will be withdrawn from
  /// @param _liquidity The address of the liquidity being withdrawn
  /// @param _receiver The receiver of the liquidity tokens
  /// @param _amount The amount of liquidity being withdrawn from the job
  event LiquidityWithdrawal(address indexed _job, address indexed _liquidity, address indexed _receiver, uint256 _amount);

  /// @notice Emitted when Keep3rJobFundableLiquidity#addLiquidityToJob function is called
  /// @param _job The address of the job whose credits will be updated
  /// @param _rewardedAt The time at which the job was last rewarded
  /// @param _currentCredits The current credits of the job
  /// @param _periodCredits The credits of the job for the current period
  event LiquidityCreditsReward(address indexed _job, uint256 _rewardedAt, uint256 _currentCredits, uint256 _periodCredits);

  /// @notice Emitted when Keep3rJobFundableLiquidity#forceLiquidityCreditsToJob function is called
  /// @param _job The address of the job whose credits will be updated
  /// @param _rewardedAt The time at which the job was last rewarded
  /// @param _currentCredits The current credits of the job
  event LiquidityCreditsForced(address indexed _job, uint256 _rewardedAt, uint256 _currentCredits);

  // Errors

  /// @notice Throws when the liquidity being approved has already been approved
  error LiquidityPairApproved();

  /// @notice Throws when the liquidity being removed has not been approved
  error LiquidityPairUnexistent();

  /// @notice Throws when trying to add liquidity to an unapproved pool
  error LiquidityPairUnapproved();

  /// @notice Throws when the job doesn't have the requested liquidity
  error JobLiquidityUnexistent();

  /// @notice Throws when trying to remove more liquidity than the job has
  error JobLiquidityInsufficient();

  /// @notice Throws when trying to add less liquidity than the minimum liquidity required
  error JobLiquidityLessThanMin();

  // Structs

  /// @notice Stores the tick information of the different liquidity pairs
  struct TickCache {
    int56 current; // Tracks the current tick
    int56 difference; // Stores the difference between the current tick and the last tick
    uint256 period; // Stores the period at which the last observation was made
  }

  // Variables

  /// @notice Lists liquidity pairs
  /// @return _list An array of addresses with all the approved liquidity pairs
  function approvedLiquidities() external view returns (address[] memory _list);

  /// @notice Amount of liquidity in a specified job
  /// @param _job The address of the job being checked
  /// @param _liquidity The address of the liquidity we are checking
  /// @return _amount Amount of liquidity in the specified job
  function liquidityAmount(address _job, address _liquidity) external view returns (uint256 _amount);

  /// @notice Last time the job was rewarded liquidity credits
  /// @param _job The address of the job being checked
  /// @return _timestamp Timestamp of the last time the job was rewarded liquidity credits
  function rewardedAt(address _job) external view returns (uint256 _timestamp);

  /// @notice Last time the job was worked
  /// @param _job The address of the job being checked
  /// @return _timestamp Timestamp of the last time the job was worked
  function workedAt(address _job) external view returns (uint256 _timestamp);

  // Methods

  /// @notice Returns the liquidity credits of a given job
  /// @param _job The address of the job of which we want to know the liquidity credits
  /// @return _amount The liquidity credits of a given job
  function jobLiquidityCredits(address _job) external view returns (uint256 _amount);

  /// @notice Returns the credits of a given job for the current period
  /// @param _job The address of the job of which we want to know the period credits
  /// @return _amount The credits the given job has at the current period
  function jobPeriodCredits(address _job) external view returns (uint256 _amount);

  /// @notice Calculates the total credits of a given job
  /// @param _job The address of the job of which we want to know the total credits
  /// @return _amount The total credits of the given job
  function totalJobCredits(address _job) external view returns (uint256 _amount);

  /// @notice Calculates how many credits should be rewarded periodically for a given liquidity amount
  /// @dev _periodCredits = underlying KP3Rs for given liquidity amount * rewardPeriod / inflationPeriod
  /// @param _liquidity The liquidity to provide
  /// @param _amount The amount of liquidity to provide
  /// @return _periodCredits The amount of KP3R periodically minted for the given liquidity
  function quoteLiquidity(address _liquidity, uint256 _amount) external view returns (uint256 _periodCredits);

  /// @notice Observes the current state of the liquidity pair being observed and updates TickCache with the information
  /// @param _liquidity The liquidity pair being observed
  /// @return _tickCache The updated TickCache
  function observeLiquidity(address _liquidity) external view returns (TickCache memory _tickCache);

  /// @notice Gifts liquidity credits to the specified job
  /// @param _job The address of the job being credited
  /// @param _amount The amount of liquidity credits to gift
  function forceLiquidityCreditsToJob(address _job, uint256 _amount) external;

  /// @notice Approve a liquidity pair for being accepted in future
  /// @param _liquidity The address of the liquidity accepted
  function approveLiquidity(address _liquidity) external;

  /// @notice Revoke a liquidity pair from being accepted in future
  /// @param _liquidity The liquidity no longer accepted
  function revokeLiquidity(address _liquidity) external;

  /// @notice Allows anyone to fund a job with liquidity
  /// @param _job The address of the job to assign liquidity to
  /// @param _liquidity The liquidity being added
  /// @param _amount The amount of liquidity tokens to add
  function addLiquidityToJob(
    address _job,
    address _liquidity,
    uint256 _amount
  ) external;

  /// @notice Unbond liquidity for a job
  /// @dev Can only be called by the job's owner
  /// @param _job The address of the job being unbound from
  /// @param _liquidity The liquidity being unbound
  /// @param _amount The amount of liquidity being removed
  function unbondLiquidityFromJob(
    address _job,
    address _liquidity,
    uint256 _amount
  ) external;

  /// @notice Withdraw liquidity from a job
  /// @param _job The address of the job being withdrawn from
  /// @param _liquidity The liquidity being withdrawn
  /// @param _receiver The address that will receive the withdrawn liquidity
  function withdrawLiquidityFromJob(
    address _job,
    address _liquidity,
    address _receiver
  ) external;
}

/// @title Keep3rJobManager contract
/// @notice Handles the addition and withdrawal of credits from a job
interface IKeep3rJobManager {
  // Events

  /// @notice Emitted when Keep3rJobManager#addJob is called
  /// @param _job The address of the job to add
  /// @param _jobOwner The job's owner
  event JobAddition(address indexed _job, address indexed _jobOwner);

  // Errors

  /// @notice Throws when trying to add a job that has already been added
  error JobAlreadyAdded();

  /// @notice Throws when the address that is trying to register as a keeper is already a keeper
  error AlreadyAKeeper();

  // Methods

  /// @notice Allows any caller to add a new job
  /// @param _job Address of the contract for which work should be performed
  function addJob(address _job) external;
}

/// @title Keep3rJobWorkable contract
/// @notice Handles the mechanisms jobs can pay keepers with along with the restrictions jobs can put on keepers before they can work on jobs
interface IKeep3rJobWorkable {
  // Events

  /// @notice Emitted when a keeper is validated before a job
  /// @param _gasLeft The amount of gas that the transaction has left at the moment of keeper validation
  event KeeperValidation(uint256 _gasLeft);

  /// @notice Emitted when a keeper works a job
  /// @param _credit The address of the asset in which the keeper is paid
  /// @param _job The address of the job the keeper has worked
  /// @param _keeper The address of the keeper that has worked the job
  /// @param _amount The amount that has been paid out to the keeper in exchange for working the job
  /// @param _gasLeft The amount of gas that the transaction has left at the moment of payment
  event KeeperWork(address indexed _credit, address indexed _job, address indexed _keeper, uint256 _amount, uint256 _gasLeft);

  // Errors

  /// @notice Throws if the address claiming to be a job is not in the list of approved jobs
  error JobUnapproved();

  /// @notice Throws if the amount of funds in the job is less than the payment that must be paid to the keeper that works that job
  error InsufficientFunds();

  // Methods

  /// @notice Confirms if the current keeper is registered, can be used for general (non critical) functions
  /// @param _keeper The keeper being investigated
  /// @return _isKeeper Whether the address passed as a parameter is a keeper or not
  function isKeeper(address _keeper) external returns (bool _isKeeper);

  /// @notice Confirms if the current keeper is registered and has a minimum bond of any asset. Should be used for protected functions
  /// @param _keeper The keeper to check
  /// @param _bond The bond token being evaluated
  /// @param _minBond The minimum amount of bonded tokens
  /// @param _earned The minimum funds earned in the keepers lifetime
  /// @param _age The minimum keeper age required
  /// @return _isBondedKeeper Whether the `_keeper` meets the given requirements
  function isBondedKeeper(
    address _keeper,
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age
  ) external returns (bool _isBondedKeeper);

  /// @notice Implemented by jobs to show that a keeper performed work
  /// @dev Automatically calculates the payment for the keeper
  /// @param _keeper Address of the keeper that performed the work
  function worked(address _keeper) external;

  /// @notice Implemented by jobs to show that a keeper performed work
  /// @dev Pays the keeper that performs the work with KP3R
  /// @param _keeper Address of the keeper that performed the work
  /// @param _payment The reward that should be allocated for the job
  function bondedPayment(address _keeper, uint256 _payment) external;

  /// @notice Implemented by jobs to show that a keeper performed work
  /// @dev Pays the keeper that performs the work with a specific token
  /// @param _token The asset being awarded to the keeper
  /// @param _keeper Address of the keeper that performed the work
  /// @param _amount The reward that should be allocated
  function directTokenPayment(
    address _token,
    address _keeper,
    uint256 _amount
  ) external;
}

/// @title Keep3rJobOwnership contract
/// @notice Handles the ownership of the jobs
interface IKeep3rJobOwnership {
  // Events

  /// @notice Emitted when Keep3rJobOwnership#changeJobOwnership is called
  /// @param _job The address of the job proposed to have a change of owner
  /// @param _owner The current owner of the job
  /// @param _pendingOwner The new address proposed to be the owner of the job
  event JobOwnershipChange(address indexed _job, address indexed _owner, address indexed _pendingOwner);

  /// @notice Emitted when Keep3rJobOwnership#JobOwnershipAssent is called
  /// @param _job The address of the job which the proposed owner will now own
  /// @param _previousOwner The previous owner of the job
  /// @param _newOwner The newowner of the job
  event JobOwnershipAssent(address indexed _job, address indexed _previousOwner, address indexed _newOwner);

  // Errors

  /// @notice Throws when the caller of the function is not the job owner
  error OnlyJobOwner();

  /// @notice Throws when the caller of the function is not the pending job owner
  error OnlyPendingJobOwner();

  // Variables

  /// @notice Maps the job to the owner of the job (job => user)
  /// @return _owner The addres of the owner of the job
  function jobOwner(address _job) external view returns (address _owner);

  /// @notice Maps the owner of the job to its pending owner (job => user)
  /// @return _pendingOwner The address of the pending owner of the job
  function jobPendingOwner(address _job) external view returns (address _pendingOwner);

  // Methods

  /// @notice Proposes a new address to be the owner of the job
  function changeJobOwnership(address _job, address _newOwner) external;

  /// @notice The proposed address accepts to be the owner of the job
  function acceptJobOwnership(address _job) external;
}

/// @title Keep3rJobMigration contract
/// @notice Handles the migration process of jobs to different addresses
interface IKeep3rJobMigration {
  // Events

  /// @notice Emitted when Keep3rJobMigration#migrateJob function is called
  /// @param _fromJob The address of the job that requests to migrate
  /// @param _toJob The address at which the job requests to migrate
  event JobMigrationRequested(address indexed _fromJob, address _toJob);

  /// @notice Emitted when Keep3rJobMigration#acceptJobMigration function is called
  /// @param _fromJob The address of the job that requested to migrate
  /// @param _toJob The address at which the job had requested to migrate
  event JobMigrationSuccessful(address _fromJob, address indexed _toJob);

  // Errors

  /// @notice Throws when the address of the job that requests to migrate wants to migrate to its same address
  error JobMigrationImpossible();

  /// @notice Throws when the _toJob address differs from the address being tracked in the pendingJobMigrations mapping
  error JobMigrationUnavailable();

  /// @notice Throws when cooldown between migrations has not yet passed
  error JobMigrationLocked();

  // Variables

  /// @notice Maps the jobs that have requested a migration to the address they have requested to migrate to
  /// @return _toJob The address to which the job has requested to migrate to
  function pendingJobMigrations(address _fromJob) external view returns (address _toJob);

  // Methods

  /// @notice Initializes the migration process for a job by adding the request to the pendingJobMigrations mapping
  /// @param _fromJob The address of the job that is requesting to migrate
  /// @param _toJob The address at which the job is requesting to migrate
  function migrateJob(address _fromJob, address _toJob) external;

  /// @notice Completes the migration process for a job
  /// @dev Unbond/withdraw process doesn't get migrated
  /// @param _fromJob The address of the job that requested to migrate
  /// @param _toJob The address to which the job wants to migrate to
  function acceptJobMigration(address _fromJob, address _toJob) external;
}

/// @title Keep3rJobDisputable contract
/// @notice Handles the actions that can be taken on a disputed job
interface IKeep3rJobDisputable is IKeep3rJobFundableCredits, IKeep3rJobFundableLiquidity {
  // Events

  /// @notice Emitted when Keep3rJobDisputable#slashTokenFromJob is called
  /// @param _job The address of the job from which the token will be slashed
  /// @param _token The address of the token being slashed
  /// @param _slasher The user that slashes the token
  /// @param _amount The amount of the token being slashed
  event JobSlashToken(address indexed _job, address _token, address indexed _slasher, uint256 _amount);

  /// @notice Emitted when Keep3rJobDisputable#slashLiquidityFromJob is called
  /// @param _job The address of the job from which the liquidity will be slashed
  /// @param _liquidity The address of the liquidity being slashed
  /// @param _slasher The user that slashes the liquidity
  /// @param _amount The amount of the liquidity being slashed
  event JobSlashLiquidity(address indexed _job, address _liquidity, address indexed _slasher, uint256 _amount);

  // Errors

  /// @notice Throws when the token trying to be slashed doesn't exist
  error JobTokenUnexistent();

  /// @notice Throws when someone tries to slash more tokens than the job has
  error JobTokenInsufficient();

  // Methods

  /// @notice Allows governance or slasher to slash a job specific token
  /// @param _job The address of the job from which the token will be slashed
  /// @param _token The address of the token that will be slashed
  /// @param _amount The amount of the token that will be slashed
  function slashTokenFromJob(
    address _job,
    address _token,
    uint256 _amount
  ) external;

  /// @notice Allows governance or a slasher to slash liquidity from a job
  /// @param _job The address being slashed
  /// @param _liquidity The address of the liquidity that will be slashed
  /// @param _amount The amount of liquidity that will be slashed
  function slashLiquidityFromJob(
    address _job,
    address _liquidity,
    uint256 _amount
  ) external;
}

// solhint-disable-next-line no-empty-blocks
interface IKeep3rJobs is IKeep3rJobOwnership, IKeep3rJobDisputable, IKeep3rJobMigration, IKeep3rJobManager, IKeep3rJobWorkable {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Keep3rDisputable contract
/// @notice Disputes keepers, or if they're already disputed, it can resolve the case
/// @dev Argument `bonding` can be the address of either a token or a liquidity
interface IKeep3rAccountance {
  // Events

  /// @notice Emitted when the bonding process of a new keeper begins
  /// @param _keeper The caller of Keep3rKeeperFundable#bond function
  /// @param _bonding The asset the keeper has bonded
  /// @param _amount The amount the keeper has bonded
  event Bonding(address indexed _keeper, address indexed _bonding, uint256 _amount);

  /// @notice Emitted when a keeper or job begins the unbonding process to withdraw the funds
  /// @param _keeperOrJob The keeper or job that began the unbonding process
  /// @param _unbonding The liquidity pair or asset being unbonded
  /// @param _amount The amount being unbonded
  event Unbonding(address indexed _keeperOrJob, address indexed _unbonding, uint256 _amount);

  // Variables

  /// @notice Tracks the total KP3R earnings of a keeper since it started working
  /// @return _workCompleted Total KP3R earnings of a keeper since it started working
  function workCompleted(address _keeper) external view returns (uint256 _workCompleted);

  /// @notice Tracks when a keeper was first registered
  /// @return timestamp The time at which the keeper was first registered
  function firstSeen(address _keeper) external view returns (uint256 timestamp);

  /// @notice Tracks if a keeper or job has a pending dispute
  /// @return _disputed Whether a keeper or job has a pending dispute
  function disputes(address _keeperOrJob) external view returns (bool _disputed);

  /// @notice Tracks how much a keeper has bonded of a certain token
  /// @return _bonds Amount of a certain token that a keeper has bonded
  function bonds(address _keeper, address _bond) external view returns (uint256 _bonds);

  /// @notice The current token credits available for a job
  /// @return _amount The amount of token credits available for a job
  function jobTokenCredits(address _job, address _token) external view returns (uint256 _amount);

  /// @notice Tracks the amount of assets deposited in pending bonds
  /// @return _pendingBonds Amount of a certain asset a keeper has unbonding
  function pendingBonds(address _keeper, address _bonding) external view returns (uint256 _pendingBonds);

  /// @notice Tracks when a bonding for a keeper can be activated
  /// @return _timestamp Time at which the bonding for a keeper can be activated
  function canActivateAfter(address _keeper, address _bonding) external view returns (uint256 _timestamp);

  /// @notice Tracks when keeper bonds are ready to be withdrawn
  /// @return _timestamp Time at which the keeper bonds are ready to be withdrawn
  function canWithdrawAfter(address _keeper, address _bonding) external view returns (uint256 _timestamp);

  /// @notice Tracks how much keeper bonds are to be withdrawn
  /// @return _pendingUnbonds The amount of keeper bonds that are to be withdrawn
  function pendingUnbonds(address _keeper, address _bonding) external view returns (uint256 _pendingUnbonds);

  /// @notice Checks whether the address has ever bonded an asset
  /// @return _hasBonded Whether the address has ever bonded an asset
  function hasBonded(address _keeper) external view returns (bool _hasBonded);

  // Methods
  /// @notice Lists all jobs
  /// @return _jobList Array with all the jobs in _jobs
  function jobs() external view returns (address[] memory _jobList);

  /// @notice Lists all keepers
  /// @return _keeperList Array with all the jobs in keepers
  function keepers() external view returns (address[] memory _keeperList);

  // Errors

  /// @notice Throws when an address is passed as a job, but that address is not a job
  error JobUnavailable();

  /// @notice Throws when an action that requires an undisputed job is applied on a disputed job
  error JobDisputed();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/// @title Keep3rHelper contract
/// @notice Contains all the helper functions used throughout the different files.
interface IKeep3rHelper {
  // Errors

  /// @notice Throws when none of the tokens in the liquidity pair is KP3R
  error LiquidityPairInvalid();

  // Variables

  /// @notice Address of KP3R token
  /// @return _kp3r Address of KP3R token
  // solhint-disable func-name-mixedcase
  function KP3R() external view returns (address _kp3r);

  /// @notice Address of KP3R-WETH pool to use as oracle
  /// @return _kp3rWeth Address of KP3R-WETH pool to use as oracle
  function KP3R_WETH_POOL() external view returns (address _kp3rWeth);

  /// @notice The minimum multiplier used to calculate the amount of gas paid to the Keeper for the gas used to perform a job
  ///         For example: if the quoted gas used is 1000, then the minimum amount to be paid will be 1000 * MIN / BOOST_BASE
  /// @return _multiplier The MIN multiplier
  function MIN() external view returns (uint256 _multiplier);

  /// @notice The maximum multiplier used to calculate the amount of gas paid to the Keeper for the gas used to perform a job
  ///         For example: if the quoted gas used is 1000, then the maximum amount to be paid will be 1000 * MAX / BOOST_BASE
  /// @return _multiplier The MAX multiplier
  function MAX() external view returns (uint256 _multiplier);

  /// @notice The boost base used to calculate the boost rewards for the keeper
  /// @return _base The boost base number
  function BOOST_BASE() external view returns (uint256 _base);

  /// @notice The targeted amount of bonded KP3Rs to max-up reward multiplier
  ///         For example: if the amount of KP3R the keeper has bonded is TARGETBOND or more, then the keeper will get
  ///                      the maximum boost possible in his rewards, if it's less, the reward boost will be proportional
  /// @return _target The amount of KP3R that comforms the TARGETBOND
  function TARGETBOND() external view returns (uint256 _target);

  // Methods
  // solhint-enable func-name-mixedcase

  /// @notice Calculates the amount of KP3R that corresponds to the ETH passed into the function
  /// @dev This function allows us to calculate how much KP3R we should pay to a keeper for things expressed in ETH, like gas
  /// @param _eth The amount of ETH
  /// @return _amountOut The amount of KP3R
  function quote(uint256 _eth) external view returns (uint256 _amountOut);

  /// @notice Returns the amount of KP3R the keeper has bonded
  /// @param _keeper The address of the keeper to check
  /// @return _amountBonded The amount of KP3R the keeper has bonded
  function bonds(address _keeper) external view returns (uint256 _amountBonded);

  /// @notice Calculates the reward (in KP3R) that corresponds to a keeper for using gas
  /// @param _keeper The address of the keeper to check
  /// @param _gasUsed The amount of gas used that will be rewarded
  /// @return _kp3r The amount of KP3R that should be awarded to the keeper
  function getRewardAmountFor(address _keeper, uint256 _gasUsed) external view returns (uint256 _kp3r);

  /// @notice Calculates the boost in the reward given to a keeper based on the amount of KP3R that keeper has bonded
  /// @param _bonds The amount of KP3R tokens bonded by the keeper
  /// @return _rewardBoost The reward boost that corresponds to the keeper
  function getRewardBoostFor(uint256 _bonds) external view returns (uint256 _rewardBoost);

  /// @notice Calculates the reward (in KP3R) that corresponds to tx.origin for using gas
  /// @param _gasUsed The amount of gas used that will be rewarded
  /// @return _amount The amount of KP3R that should be awarded to tx.origin
  function getRewardAmount(uint256 _gasUsed) external view returns (uint256 _amount);

  /// @notice Given a pool address, returns the underlying tokens of the pair
  /// @param _pool Address of the correspondant pool
  /// @return _token0 Address of the first token of the pair
  /// @return _token1 Address of the second token of the pair
  function getPoolTokens(address _pool) external view returns (address _token0, address _token1);

  /// @notice Defines the order of the tokens in the pair for twap calculations
  /// @param _pool Address of the correspondant pool
  /// @return _isKP3RToken0 Boolean indicating the order of the tokens in the pair
  function isKP3RToken0(address _pool) external view returns (bool _isKP3RToken0);

  /// @notice Given an array of secondsAgo, returns UniswapV3 pool cumulatives at that moment
  /// @param _pool Address of the pool to observe
  /// @param _secondsAgo Array with time references to observe
  /// @return _tickCumulative1 Cummulative sum of ticks until first time reference
  /// @return _tickCumulative2 Cummulative sum of ticks until second time reference
  /// @return _success Boolean indicating if the observe call was succesfull
  function observe(address _pool, uint32[] memory _secondsAgo)
    external
    view
    returns (
      int56 _tickCumulative1,
      int56 _tickCumulative2,
      bool _success
    );

  /// @notice Given a tick and a liquidity amount, calculates the underlying KP3R tokens
  /// @param _liquidityAmount Amount of liquidity to be converted
  /// @param _tickDifference Tick value used to calculate the quote
  /// @param _timeInterval Time value used to calculate the quote
  /// @return _kp3rAmount Amount of KP3R tokens underlying on the given liquidity
  function getKP3RsAtTick(
    uint256 _liquidityAmount,
    int56 _tickDifference,
    uint256 _timeInterval
  ) external pure returns (uint256 _kp3rAmount);

  /// @notice Given a tick and a token amount, calculates the output in correspondant token
  /// @param _baseAmount Amount of token to be converted
  /// @param _tickDifference Tick value used to calculate the quote
  /// @param _timeInterval Time value used to calculate the quote
  /// @return _quoteAmount Amount of credits deserved for the baseAmount at the tick value
  function getQuoteAtTick(
    uint128 _baseAmount,
    int56 _tickDifference,
    uint256 _timeInterval
  ) external pure returns (uint256 _quoteAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './IBaseErrors.sol';

/// @title Keep3rParameters contract
/// @notice Handles and sets all the required parameters for Keep3r

interface IKeep3rParameters is IBaseErrors {
  // Events

  /// @notice Emitted when the Keep3rHelper address is changed
  /// @param _keep3rHelper The address of Keep3rHelper's contract
  event Keep3rHelperChange(address _keep3rHelper);

  /// @notice Emitted when the Keep3rV1 address is changed
  /// @param _keep3rV1 The address of Keep3rV1's contract
  event Keep3rV1Change(address _keep3rV1);

  /// @notice Emitted when the Keep3rV1Proxy address is changed
  /// @param _keep3rV1Proxy The address of Keep3rV1Proxy's contract
  event Keep3rV1ProxyChange(address _keep3rV1Proxy);

  /// @notice Emitted when the KP3R-WETH pool address is changed
  /// @param _kp3rWethPool The address of the KP3R-WETH pool
  event Kp3rWethPoolChange(address _kp3rWethPool);

  /// @notice Emitted when bondTime is changed
  /// @param _bondTime The new bondTime
  event BondTimeChange(uint256 _bondTime);

  /// @notice Emitted when _liquidityMinimum is changed
  /// @param _liquidityMinimum The new _liquidityMinimum
  event LiquidityMinimumChange(uint256 _liquidityMinimum);

  /// @notice Emitted when _unbondTime is changed
  /// @param _unbondTime The new _unbondTime
  event UnbondTimeChange(uint256 _unbondTime);

  /// @notice Emitted when _rewardPeriodTime is changed
  /// @param _rewardPeriodTime The new _rewardPeriodTime
  event RewardPeriodTimeChange(uint256 _rewardPeriodTime);

  /// @notice Emitted when the inflationPeriod is changed
  /// @param _inflationPeriod The new inflationPeriod
  event InflationPeriodChange(uint256 _inflationPeriod);

  /// @notice Emitted when the fee is changed
  /// @param _fee The new token credits fee
  event FeeChange(uint256 _fee);

  // Variables

  /// @notice Address of Keep3rHelper's contract
  /// @return _keep3rHelper The address of Keep3rHelper's contract
  function keep3rHelper() external view returns (address _keep3rHelper);

  /// @notice Address of Keep3rV1's contract
  /// @return _keep3rV1 The address of Keep3rV1's contract
  function keep3rV1() external view returns (address _keep3rV1);

  /// @notice Address of Keep3rV1Proxy's contract
  /// @return _keep3rV1Proxy The address of Keep3rV1Proxy's contract
  function keep3rV1Proxy() external view returns (address _keep3rV1Proxy);

  /// @notice Address of the KP3R-WETH pool
  /// @return _kp3rWethPool The address of KP3R-WETH pool
  function kp3rWethPool() external view returns (address _kp3rWethPool);

  /// @notice The amount of time required to pass after a keeper has bonded assets for it to be able to activate
  /// @return _days The required bondTime in days
  function bondTime() external view returns (uint256 _days);

  /// @notice The amount of time required to pass before a keeper can unbond what he has bonded
  /// @return _days The required unbondTime in days
  function unbondTime() external view returns (uint256 _days);

  /// @notice The minimum amount of liquidity required to fund a job per liquidity
  /// @return _amount The minimum amount of liquidity in KP3R
  function liquidityMinimum() external view returns (uint256 _amount);

  /// @notice The amount of time between each scheduled credits reward given to a job
  /// @return _days The reward period in days
  function rewardPeriodTime() external view returns (uint256 _days);

  /// @notice The inflation period is the denominator used to regulate the emission of KP3R
  /// @return _period The denominator used to regulate the emission of KP3R
  function inflationPeriod() external view returns (uint256 _period);

  /// @notice The fee to be sent to governance when a user adds liquidity to a job
  /// @return _amount The fee amount to be sent to governance when a user adds liquidity to a job
  function fee() external view returns (uint256 _amount);

  // solhint-disable func-name-mixedcase
  /// @notice The base that will be used to calculate the fee
  /// @return _base The base that will be used to calculate the fee
  function BASE() external view returns (uint256 _base);

  /// @notice The minimum rewardPeriodTime value to be set
  /// @return _minPeriod The minimum reward period in seconds
  function MIN_REWARD_PERIOD_TIME() external view returns (uint256 _minPeriod);

  // solhint-enable func-name-mixedcase

  // Errors

  /// @notice Throws if the reward period is less than the minimum reward period time
  error MinRewardPeriod();

  /// @notice Throws if either a job or a keeper is disputed
  error Disputed();

  /// @notice Throws if there are no bonded assets
  error BondsUnexistent();

  /// @notice Throws if the time required to bond an asset has not passed yet
  error BondsLocked();

  /// @notice Throws if there are no bonds to withdraw
  error UnbondsUnexistent();

  /// @notice Throws if the time required to withdraw the bonds has not passed yet
  error UnbondsLocked();

  // Methods

  /// @notice Sets the Keep3rHelper address
  /// @param _keep3rHelper The Keep3rHelper address
  function setKeep3rHelper(address _keep3rHelper) external;

  /// @notice Sets the Keep3rV1 address
  /// @param _keep3rV1 The Keep3rV1 address
  function setKeep3rV1(address _keep3rV1) external;

  /// @notice Sets the Keep3rV1Proxy address
  /// @param _keep3rV1Proxy The Keep3rV1Proxy address
  function setKeep3rV1Proxy(address _keep3rV1Proxy) external;

  /// @notice Sets the KP3R-WETH pool address
  /// @param _kp3rWethPool The KP3R-WETH pool address
  function setKp3rWethPool(address _kp3rWethPool) external;

  /// @notice Sets the bond time required to activate as a keeper
  /// @param _bond The new bond time
  function setBondTime(uint256 _bond) external;

  /// @notice Sets the unbond time required unbond what has been bonded
  /// @param _unbond The new unbond time
  function setUnbondTime(uint256 _unbond) external;

  /// @notice Sets the minimum amount of liquidity required to fund a job
  /// @param _liquidityMinimum The new minimum amount of liquidity
  function setLiquidityMinimum(uint256 _liquidityMinimum) external;

  /// @notice Sets the time required to pass between rewards for jobs
  /// @param _rewardPeriodTime The new amount of time required to pass between rewards
  function setRewardPeriodTime(uint256 _rewardPeriodTime) external;

  /// @notice Sets the new inflation period
  /// @param _inflationPeriod The new inflation period
  function setInflationPeriod(uint256 _inflationPeriod) external;

  /// @notice Sets the new fee
  /// @param _fee The new fee
  function setFee(uint256 _fee) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

interface IBaseErrors {
  /// @notice Throws if a variable is assigned to the zero address
  error ZeroAddress();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Keep3rRoles contract
/// @notice Manages the Keep3r specific roles
interface IKeep3rRoles {
  // Events

  /// @notice Emitted when a slasher is added
  /// @param _slasher Address of the added slasher
  event SlasherAdded(address _slasher);

  /// @notice Emitted when a slasher is removed
  /// @param _slasher Address of the removed slasher
  event SlasherRemoved(address _slasher);

  /// @notice Emitted when a disputer is added
  /// @param _disputer Address of the added disputer
  event DisputerAdded(address _disputer);

  /// @notice Emitted when a disputer is removed
  /// @param _disputer Address of the removed disputer
  event DisputerRemoved(address _disputer);

  // Variables

  /// @notice Maps an address to a boolean to determine whether the address is a slasher or not.
  /// @return _isSlasher Whether the address is a slasher or not
  function slashers(address _slasher) external view returns (bool _isSlasher);

  /// @notice Maps an address to a boolean to determine whether the address is a disputer or not.
  /// @return _isDisputer Whether the address is a disputer or not
  function disputers(address _disputer) external view returns (bool _isDisputer);

  // Errors

  /// @notice Throws if the address is already a registered slasher
  error SlasherExistent();

  /// @notice Throws if caller is not a registered slasher
  error SlasherUnexistent();

  /// @notice Throws if the address is already a registered disputer
  error DisputerExistent();

  /// @notice Throws if caller is not a registered disputer
  error DisputerUnexistent();

  /// @notice Throws if the msg.sender is not a slasher or is not a part of governance
  error OnlySlasher();

  /// @notice Throws if the msg.sender is not a disputer or is not a part of governance
  error OnlyDisputer();

  // Methods

  /// @notice Registers a slasher by updating the slashers mapping
  function addSlasher(address _slasher) external;

  /// @notice Removes a slasher by updating the slashers mapping
  function removeSlasher(address _slasher) external;

  /// @notice Registers a disputer by updating the disputers mapping
  function addDisputer(address _disputer) external;

  /// @notice Removes a disputer by updating the disputers mapping
  function removeDisputer(address _disputer) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '../../interfaces/peripherals/IGovernable.sol';

abstract contract Governable is IGovernable {
  /// @inheritdoc IGovernable
  address public override governance;

  /// @inheritdoc IGovernable
  address public override pendingGovernance;

  constructor(address _governance) {
    if (_governance == address(0)) revert NoGovernanceZeroAddress();
    governance = _governance;
  }

  /// @inheritdoc IGovernable
  function setGovernance(address _governance) external override onlyGovernance {
    pendingGovernance = _governance;
    emit GovernanceProposal(_governance);
  }

  /// @inheritdoc IGovernable
  function acceptGovernance() external override onlyPendingGovernance {
    governance = pendingGovernance;
    delete pendingGovernance;
    emit GovernanceSet(governance);
  }

  /// @notice Functions with this modifier can only be called by governance
  modifier onlyGovernance {
    if (msg.sender != governance) revert OnlyGovernance();
    _;
  }

  /// @notice Functions with this modifier can only be called by pendingGovernance
  modifier onlyPendingGovernance {
    if (msg.sender != pendingGovernance) revert OnlyPendingGovernance();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Governable contract
/// @notice Manages the governance role
interface IGovernable {
  // Events

  /// @notice Emitted when pendingGovernance accepts to be governance
  /// @param _governance Address of the new governance
  event GovernanceSet(address _governance);

  /// @notice Emitted when a new governance is proposed
  /// @param _pendingGovernance Address that is proposed to be the new governance
  event GovernanceProposal(address _pendingGovernance);

  // Errors

  /// @notice Throws if the caller of the function is not governance
  error OnlyGovernance();

  /// @notice Throws if the caller of the function is not pendingGovernance
  error OnlyPendingGovernance();

  /// @notice Throws if trying to set governance to zero address
  error NoGovernanceZeroAddress();

  // Variables

  /// @notice Stores the governance address
  /// @return _governance The governance addresss
  function governance() external view returns (address _governance);

  /// @notice Stores the pendingGovernance address
  /// @return _pendingGovernance The pendingGovernance addresss
  function pendingGovernance() external view returns (address _pendingGovernance);

  // Methods

  /// @notice Proposes a new address to be governance
  /// @param _governance The address of the user proposed to be the new governance
  function setGovernance(address _governance) external;

  /// @notice Changes the governance from the current governance to the previously proposed address
  function acceptGovernance() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

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
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
        require(isContract(target), "Address: static call to non-contract");

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
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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
        require(isContract(target), "Address: delegate call to non-contract");

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

/// @title  Pair Manager interface
/// @notice Generic interface for Keep3r liquidity pools (kLP)
interface IPairManager is IERC20Metadata {
  /// @notice Address of the pool from which the Keep3r pair manager will interact with
  /// @return _pool The pool's address
  function pool() external view returns (address _pool);

  /// @notice Token0 of the pool
  /// @return _token0 The address of token0
  function token0() external view returns (address _token0);

  /// @notice Token1 of the pool
  /// @return _token1 The address of token1
  function token1() external view returns (address _token1);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
  /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
  function mulDiv(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    unchecked {
      // 512-bit multiply [prod1 prod0] = a * b
      // Compute the product mod 2**256 and mod 2**256 - 1
      // then use the Chinese Remainder Theorem to reconstruct
      // the 512 bit result. The result is stored in two 256
      // variables such that product = prod1 * 2**256 + prod0
      uint256 prod0; // Least significant 256 bits of the product
      uint256 prod1; // Most significant 256 bits of the product
      assembly {
        let mm := mulmod(a, b, not(0))
        prod0 := mul(a, b)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
      }

      // Handle non-overflow cases, 256 by 256 division
      if (prod1 == 0) {
        require(denominator > 0);
        assembly {
          result := div(prod0, denominator)
        }
        return result;
      }

      // Make sure the result is less than 2**256.
      // Also prevents denominator == 0
      require(denominator > prod1);

      ///////////////////////////////////////////////
      // 512 by 256 division.
      ///////////////////////////////////////////////

      // Make division exact by subtracting the remainder from [prod1 prod0]
      // Compute remainder using mulmod
      uint256 remainder;
      assembly {
        remainder := mulmod(a, b, denominator)
      }
      // Subtract 256 bit number from 512 bit number
      assembly {
        prod1 := sub(prod1, gt(remainder, prod0))
        prod0 := sub(prod0, remainder)
      }

      // Factor powers of two out of denominator
      // Compute largest power of two divisor of denominator.
      // Always >= 1.
      uint256 twos = (~denominator + 1) & denominator;
      // Divide denominator by power of two
      assembly {
        denominator := div(denominator, twos)
      }

      // Divide [prod1 prod0] by the factors of two
      assembly {
        prod0 := div(prod0, twos)
      }
      // Shift in bits from prod1 into prod0. For this we need
      // to flip `twos` such that it is 2**256 / twos.
      // If twos is zero, then it becomes one
      assembly {
        twos := add(div(sub(0, twos), twos), 1)
      }
      prod0 |= prod1 * twos;

      // Invert denominator mod 2**256
      // Now that denominator is an odd number, it has an inverse
      // modulo 2**256 such that denominator * inv = 1 mod 2**256.
      // Compute the inverse by starting with a seed that is correct
      // correct for four bits. That is, denominator * inv = 1 mod 2**4
      uint256 inv = (3 * denominator) ^ 2;
      // Now use Newton-Raphson iteration to improve the precision.
      // Thanks to Hensel's lifting lemma, this also works in modular
      // arithmetic, doubling the correct bits in each step.
      inv *= 2 - denominator * inv; // inverse mod 2**8
      inv *= 2 - denominator * inv; // inverse mod 2**16
      inv *= 2 - denominator * inv; // inverse mod 2**32
      inv *= 2 - denominator * inv; // inverse mod 2**64
      inv *= 2 - denominator * inv; // inverse mod 2**128
      inv *= 2 - denominator * inv; // inverse mod 2**256

      // Because the division is now exact we can divide by multiplying
      // with the modular inverse of denominator. This will give us the
      // correct result modulo 2**256. Since the precoditions guarantee
      // that the outcome is less than 2**256, this is the final result.
      // We don't need to compute the high bits of the result and prod1
      // is no longer required.
      result = prod0 * inv;
      return result;
    }
  }

  /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  function mulDivRoundingUp(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    unchecked {
      result = mulDiv(a, b, denominator);
      if (mulmod(a, b, denominator) > 0) {
        require(result < type(uint256).max);
        result++;
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Keep3rDisputable contract
/// @notice Creates/resolves disputes for jobs or keepers
///         A disputed keeper is slashable and is not able to bond, activate, withdraw or receive direct payments
///         A disputed job is slashable and is not able to pay the keepers, withdraw tokens or to migrate
interface IKeep3rDisputable {
  /// @notice Emitted when a keeper or a job is disputed
  /// @param _jobOrKeeper The address of the disputed keeper/job
  /// @param _disputer The user that called the function and disputed the keeper
  event Dispute(address indexed _jobOrKeeper, address indexed _disputer);

  /// @notice Emitted when a dispute is resolved
  /// @param _jobOrKeeper The address of the disputed keeper/job
  /// @param _resolver The user that called the function and resolved the dispute
  event Resolve(address indexed _jobOrKeeper, address indexed _resolver);

  /// @notice Throws when a job or keeper is already disputed
  error AlreadyDisputed();

  /// @notice Throws when a job or keeper is not disputed and someone tries to resolve the dispute
  error NotDisputed();

  /// @notice Allows governance to create a dispute for a given keeper/job
  /// @param _jobOrKeeper The address in dispute
  function dispute(address _jobOrKeeper) external;

  /// @notice Allows governance to resolve a dispute on a keeper/job
  /// @param _jobOrKeeper The address cleared
  function resolve(address _jobOrKeeper) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '../../../interfaces/peripherals/IKeep3rJobs.sol';
import './Keep3rJobFundableCredits.sol';
import './Keep3rJobFundableLiquidity.sol';

abstract contract Keep3rJobMigration is IKeep3rJobMigration, Keep3rJobFundableCredits, Keep3rJobFundableLiquidity {
  using EnumerableSet for EnumerableSet.AddressSet;

  uint256 internal constant _MIGRATION_COOLDOWN = 1 minutes;

  /// @inheritdoc IKeep3rJobMigration
  mapping(address => address) public override pendingJobMigrations;
  mapping(address => mapping(address => uint256)) internal _migrationCreatedAt;

  /// @inheritdoc IKeep3rJobMigration
  function migrateJob(address _fromJob, address _toJob) external override onlyJobOwner(_fromJob) {
    if (_fromJob == _toJob) revert JobMigrationImpossible();

    pendingJobMigrations[_fromJob] = _toJob;
    _migrationCreatedAt[_fromJob][_toJob] = block.timestamp;

    emit JobMigrationRequested(_fromJob, _toJob);
  }

  /// @inheritdoc IKeep3rJobMigration
  function acceptJobMigration(address _fromJob, address _toJob) external override onlyJobOwner(_toJob) {
    if (disputes[_fromJob] || disputes[_toJob]) revert JobDisputed();
    if (pendingJobMigrations[_fromJob] != _toJob) revert JobMigrationUnavailable();
    if (block.timestamp < _migrationCreatedAt[_fromJob][_toJob] + _MIGRATION_COOLDOWN) revert JobMigrationLocked();

    // force job credits update for both jobs
    _settleJobAccountance(_fromJob);
    _settleJobAccountance(_toJob);

    // migrate tokens
    while (_jobTokens[_fromJob].length() > 0) {
      address _tokenToMigrate = _jobTokens[_fromJob].at(0);
      jobTokenCredits[_toJob][_tokenToMigrate] += jobTokenCredits[_fromJob][_tokenToMigrate];
      jobTokenCredits[_fromJob][_tokenToMigrate] = 0;
      _jobTokens[_fromJob].remove(_tokenToMigrate);
      _jobTokens[_toJob].add(_tokenToMigrate);
    }

    // migrate liquidities
    while (_jobLiquidities[_fromJob].length() > 0) {
      address _liquidity = _jobLiquidities[_fromJob].at(0);

      liquidityAmount[_toJob][_liquidity] += liquidityAmount[_fromJob][_liquidity];
      delete liquidityAmount[_fromJob][_liquidity];

      _jobLiquidities[_toJob].add(_liquidity);
      _jobLiquidities[_fromJob].remove(_liquidity);
    }

    // migrate job balances
    _jobPeriodCredits[_toJob] += _jobPeriodCredits[_fromJob];
    delete _jobPeriodCredits[_fromJob];

    _jobLiquidityCredits[_toJob] += _jobLiquidityCredits[_fromJob];
    delete _jobLiquidityCredits[_fromJob];

    // stop _fromJob from being a job
    delete rewardedAt[_fromJob];
    _jobs.remove(_fromJob);

    // delete unused data slots
    delete jobOwner[_fromJob];
    delete jobPendingOwner[_fromJob];
    delete _migrationCreatedAt[_fromJob][_toJob];
    delete pendingJobMigrations[_fromJob];

    emit JobMigrationSuccessful(_fromJob, _toJob);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './Keep3rKeeperFundable.sol';
import '../Keep3rDisputable.sol';
import '../../../interfaces/external/IKeep3rV1.sol';
import '../../../interfaces/peripherals/IKeep3rKeepers.sol';

abstract contract Keep3rKeeperDisputable is IKeep3rKeeperDisputable, Keep3rDisputable, Keep3rKeeperFundable {
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  /// @inheritdoc IKeep3rKeeperDisputable
  function slash(
    address _keeper,
    address _bonded,
    uint256 _amount
  ) public override onlySlasher {
    if (!disputes[_keeper]) revert NotDisputed();
    _slash(_keeper, _bonded, _amount);
    emit KeeperSlash(_keeper, msg.sender, _amount);
  }

  /// @inheritdoc IKeep3rKeeperDisputable
  function revoke(address _keeper) external override onlySlasher {
    if (!disputes[_keeper]) revert NotDisputed();
    _keepers.remove(_keeper);
    _slash(_keeper, keep3rV1, bonds[_keeper][keep3rV1]);
    emit KeeperRevoke(_keeper, msg.sender);
  }

  function _slash(
    address _keeper,
    address _bonded,
    uint256 _amount
  ) internal {
    if (_bonded != keep3rV1) {
      try IERC20(_bonded).transfer(governance, _amount) returns (bool) {} catch (bytes memory) {}
    }
    bonds[_keeper][_bonded] -= _amount;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '../Keep3rAccountance.sol';
import '../Keep3rParameters.sol';
import '../../../interfaces/peripherals/IKeep3rKeepers.sol';

import '../../../interfaces/external/IKeep3rV1.sol';
import '../../../interfaces/external/IKeep3rV1Proxy.sol';

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

abstract contract Keep3rKeeperFundable is IKeep3rKeeperFundable, ReentrancyGuard, Keep3rParameters {
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  /// @inheritdoc IKeep3rKeeperFundable
  function bond(address _bonding, uint256 _amount) external override nonReentrant {
    if (disputes[msg.sender]) revert Disputed();
    if (_jobs.contains(msg.sender)) revert AlreadyAJob();
    canActivateAfter[msg.sender][_bonding] = block.timestamp + bondTime;

    uint256 _before = IERC20(_bonding).balanceOf(address(this));
    IERC20(_bonding).safeTransferFrom(msg.sender, address(this), _amount);
    _amount = IERC20(_bonding).balanceOf(address(this)) - _before;

    hasBonded[msg.sender] = true;
    pendingBonds[msg.sender][_bonding] += _amount;

    emit Bonding(msg.sender, _bonding, _amount);
  }

  /// @inheritdoc IKeep3rKeeperFundable
  function activate(address _bonding) external override {
    if (disputes[msg.sender]) revert Disputed();
    if (canActivateAfter[msg.sender][_bonding] == 0) revert BondsUnexistent();
    if (canActivateAfter[msg.sender][_bonding] >= block.timestamp) revert BondsLocked();

    _activate(msg.sender, _bonding);
  }

  /// @inheritdoc IKeep3rKeeperFundable
  function unbond(address _bonding, uint256 _amount) external override {
    canWithdrawAfter[msg.sender][_bonding] = block.timestamp + unbondTime;
    bonds[msg.sender][_bonding] -= _amount;
    pendingUnbonds[msg.sender][_bonding] += _amount;

    emit Unbonding(msg.sender, _bonding, _amount);
  }

  /// @inheritdoc IKeep3rKeeperFundable
  function withdraw(address _bonding) external override nonReentrant {
    if (canWithdrawAfter[msg.sender][_bonding] == 0) revert UnbondsUnexistent();
    if (canWithdrawAfter[msg.sender][_bonding] >= block.timestamp) revert UnbondsLocked();
    if (disputes[msg.sender]) revert Disputed();

    uint256 _amount = pendingUnbonds[msg.sender][_bonding];

    if (_bonding == keep3rV1) {
      IKeep3rV1Proxy(keep3rV1Proxy).mint(_amount);
    }

    pendingUnbonds[msg.sender][_bonding] = 0;
    IERC20(_bonding).safeTransfer(msg.sender, _amount);

    emit Withdrawal(msg.sender, _bonding, _amount);
  }

  function _bond(
    address _bonding,
    address _from,
    uint256 _amount
  ) internal {
    bonds[_from][_bonding] += _amount;
    if (_bonding == keep3rV1) {
      IKeep3rV1(keep3rV1).burn(_amount);
    }
  }

  function _activate(address _keeper, address _bonding) internal {
    if (firstSeen[_keeper] == 0) {
      firstSeen[_keeper] = block.timestamp;
    }
    _keepers.add(_keeper);
    uint256 _amount = pendingBonds[_keeper][_bonding];
    pendingBonds[_keeper][_bonding] = 0;
    _bond(_bonding, _keeper, _amount);

    emit Activation(_keeper, _bonding, _amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

// solhint-disable func-name-mixedcase
interface IKeep3rV1 is IERC20, IERC20Metadata {
  // Structs
  struct Checkpoint {
    uint32 fromBlock;
    uint256 votes;
  }

  // Events
  event DelegateChanged(address indexed _delegator, address indexed _fromDelegate, address indexed _toDelegate);
  event DelegateVotesChanged(address indexed _delegate, uint256 _previousBalance, uint256 _newBalance);
  event SubmitJob(address indexed _job, address indexed _liquidity, address indexed _provider, uint256 _block, uint256 _credit);
  event ApplyCredit(address indexed _job, address indexed _liquidity, address indexed _provider, uint256 _block, uint256 _credit);
  event RemoveJob(address indexed _job, address indexed _liquidity, address indexed _provider, uint256 _block, uint256 _credit);
  event UnbondJob(address indexed _job, address indexed _liquidity, address indexed _provider, uint256 _block, uint256 _credit);
  event JobAdded(address indexed _job, uint256 _block, address _governance);
  event JobRemoved(address indexed _job, uint256 _block, address _governance);
  event KeeperWorked(address indexed _credit, address indexed _job, address indexed _keeper, uint256 _block, uint256 _amount);
  event KeeperBonding(address indexed _keeper, uint256 _block, uint256 _active, uint256 _bond);
  event KeeperBonded(address indexed _keeper, uint256 _block, uint256 _activated, uint256 _bond);
  event KeeperUnbonding(address indexed _keeper, uint256 _block, uint256 _deactive, uint256 _bond);
  event KeeperUnbound(address indexed _keeper, uint256 _block, uint256 _deactivated, uint256 _bond);
  event KeeperSlashed(address indexed _keeper, address indexed _slasher, uint256 _block, uint256 _slash);
  event KeeperDispute(address indexed _keeper, uint256 _block);
  event KeeperResolved(address indexed _keeper, uint256 _block);
  event TokenCreditAddition(address indexed _credit, address indexed _job, address indexed _creditor, uint256 _block, uint256 _amount);

  // Variables
  function KPRH() external returns (address);

  function delegates(address _delegator) external view returns (address);

  function checkpoints(address _account, uint32 _checkpoint) external view returns (Checkpoint memory);

  function numCheckpoints(address _account) external view returns (uint32);

  function DOMAIN_TYPEHASH() external returns (bytes32);

  function DOMAINSEPARATOR() external returns (bytes32);

  function DELEGATION_TYPEHASH() external returns (bytes32);

  function PERMIT_TYPEHASH() external returns (bytes32);

  function nonces(address _user) external view returns (uint256);

  function BOND() external returns (uint256);

  function UNBOND() external returns (uint256);

  function LIQUIDITYBOND() external returns (uint256);

  function FEE() external returns (uint256);

  function BASE() external returns (uint256);

  function ETH() external returns (address);

  function bondings(address _user, address _bonding) external view returns (uint256);

  function canWithdrawAfter(address _user, address _bonding) external view returns (uint256);

  function pendingUnbonds(address _keeper, address _bonding) external view returns (uint256);

  function pendingbonds(address _keeper, address _bonding) external view returns (uint256);

  function bonds(address _keeper, address _bonding) external view returns (uint256);

  function votes(address _delegator) external view returns (uint256);

  function firstSeen(address _keeper) external view returns (uint256);

  function disputes(address _keeper) external view returns (bool);

  function lastJob(address _keeper) external view returns (uint256);

  function workCompleted(address _keeper) external view returns (uint256);

  function jobs(address _job) external view returns (bool);

  function credits(address _job, address _credit) external view returns (uint256);

  function liquidityProvided(
    address _provider,
    address _liquidity,
    address _job
  ) external view returns (uint256);

  function liquidityUnbonding(
    address _provider,
    address _liquidity,
    address _job
  ) external view returns (uint256);

  function liquidityAmountsUnbonding(
    address _provider,
    address _liquidity,
    address _job
  ) external view returns (uint256);

  function jobProposalDelay(address _job) external view returns (uint256);

  function liquidityApplied(
    address _provider,
    address _liquidity,
    address _job
  ) external view returns (uint256);

  function liquidityAmount(
    address _provider,
    address _liquidity,
    address _job
  ) external view returns (uint256);

  function keepers(address _keeper) external view returns (bool);

  function blacklist(address _keeper) external view returns (bool);

  function keeperList(uint256 _index) external view returns (address);

  function jobList(uint256 _index) external view returns (address);

  function governance() external returns (address);

  function pendingGovernance() external returns (address);

  function liquidityAccepted(address _liquidity) external view returns (bool);

  function liquidityPairs(uint256 _index) external view returns (address);

  // Methods
  function getCurrentVotes(address _account) external view returns (uint256);

  function addCreditETH(address _job) external payable;

  function addCredit(
    address _credit,
    address _job,
    uint256 _amount
  ) external;

  function addVotes(address _voter, uint256 _amount) external;

  function removeVotes(address _voter, uint256 _amount) external;

  function addKPRCredit(address _job, uint256 _amount) external;

  function approveLiquidity(address _liquidity) external;

  function revokeLiquidity(address _liquidity) external;

  function pairs() external view returns (address[] memory);

  function addLiquidityToJob(
    address _liquidity,
    address _job,
    uint256 _amount
  ) external;

  function applyCreditToJob(
    address _provider,
    address _liquidity,
    address _job
  ) external;

  function unbondLiquidityFromJob(
    address _liquidity,
    address _job,
    uint256 _amount
  ) external;

  function removeLiquidityFromJob(address _liquidity, address _job) external;

  function mint(uint256 _amount) external;

  function burn(uint256 _amount) external;

  function worked(address _keeper) external;

  function receipt(
    address _credit,
    address _keeper,
    uint256 _amount
  ) external;

  function receiptETH(address _keeper, uint256 _amount) external;

  function addJob(address _job) external;

  function getJobs() external view returns (address[] memory);

  function removeJob(address _job) external;

  function setKeep3rHelper(address _keep3rHelper) external;

  function setGovernance(address _governance) external;

  function acceptGovernance() external;

  function isKeeper(address _keeper) external returns (bool);

  function isMinKeeper(
    address _keeper,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age
  ) external returns (bool);

  function isBondedKeeper(
    address _keeper,
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age
  ) external returns (bool);

  function bond(address _bonding, uint256 _amount) external;

  function getKeepers() external view returns (address[] memory);

  function activate(address _bonding) external;

  function unbond(address _bonding, uint256 _amount) external;

  function slash(
    address _bonded,
    address _keeper,
    uint256 _amount
  ) external;

  function withdraw(address _bonding) external;

  function dispute(address _keeper) external;

  function revoke(address _keeper) external;

  function resolve(address _keeper) external;

  function permit(
    address _owner,
    address _spender,
    uint256 _amount,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Keep3rKeeperFundable contract
/// @notice Handles the actions required to become a keeper
interface IKeep3rKeeperFundable {
  // Events

  /// @notice Emitted when Keep3rKeeperFundable#activate is called
  /// @param _keeper The keeper that has been activated
  /// @param _bond The asset the keeper has bonded
  /// @param _amount The amount of the asset the keeper has bonded
  event Activation(address indexed _keeper, address indexed _bond, uint256 _amount);

  /// @notice Emitted when Keep3rKeeperFundable#withdraw is called
  /// @param _keeper The caller of Keep3rKeeperFundable#withdraw function
  /// @param _bond The asset to withdraw from the bonding pool
  /// @param _amount The amount of funds withdrawn
  event Withdrawal(address indexed _keeper, address indexed _bond, uint256 _amount);

  // Errors

  /// @notice Throws when the address that is trying to register as a job is already a job
  error AlreadyAJob();

  // Methods

  /// @notice Beginning of the bonding process
  /// @param _bonding The asset being bound
  /// @param _amount The amount of bonding asset being bound
  function bond(address _bonding, uint256 _amount) external;

  /// @notice Beginning of the unbonding process
  /// @param _bonding The asset being unbound
  /// @param _amount Allows for partial unbonding
  function unbond(address _bonding, uint256 _amount) external;

  /// @notice End of the bonding process after bonding time has passed
  /// @param _bonding The asset being activated as bond collateral
  function activate(address _bonding) external;

  /// @notice Withdraw funds after unbonding has finished
  /// @param _bonding The asset to withdraw from the bonding pool
  function withdraw(address _bonding) external;
}

/// @title Keep3rKeeperDisputable contract
/// @notice Handles the actions that can be taken on a disputed keeper
interface IKeep3rKeeperDisputable {
  // Events

  /// @notice Emitted when Keep3rKeeperDisputable#slash is called
  /// @param _keeper The slashed keeper
  /// @param _slasher The user that called Keep3rKeeperDisputable#slash
  /// @param _amount The amount of credits slashed from the keeper
  event KeeperSlash(address indexed _keeper, address indexed _slasher, uint256 _amount);

  /// @notice Emitted when Keep3rKeeperDisputable#revoke is called
  /// @param _keeper The revoked keeper
  /// @param _slasher The user that called Keep3rKeeperDisputable#revoke
  event KeeperRevoke(address indexed _keeper, address indexed _slasher);

  /// @notice Keeper revoked

  // Methods

  /// @notice Allows governance to slash a keeper based on a dispute
  /// @param _keeper The address being slashed
  /// @param _bonded The asset being slashed
  /// @param _amount The amount being slashed
  function slash(
    address _keeper,
    address _bonded,
    uint256 _amount
  ) external;

  /// @notice Blacklists a keeper from participating in the network
  /// @param _keeper The address being slashed
  function revoke(address _keeper) external;
}

// solhint-disable-next-line no-empty-blocks

/// @title Keep3rKeepers contract
interface IKeep3rKeepers is IKeep3rKeeperDisputable {

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '../peripherals/IGovernable.sol';

interface IKeep3rV1Proxy is IGovernable {
  // Structs
  struct Recipient {
    address recipient;
    uint256 caps;
  }

  // Variables
  function keep3rV1() external view returns (address);

  function minter() external view returns (address);

  function next(address) external view returns (uint256);

  function caps(address) external view returns (uint256);

  function recipients() external view returns (address[] memory);

  function recipientsCaps() external view returns (Recipient[] memory);

  // Errors
  error Cooldown();
  error NoDrawableAmount();
  error ZeroAddress();
  error OnlyMinter();

  // Methods
  function addRecipient(address recipient, uint256 amount) external;

  function removeRecipient(address recipient) external;

  function draw() external returns (uint256 _amount);

  function setKeep3rV1(address _keep3rV1) external;

  function setMinter(address _minter) external;

  function mint(uint256 _amount) external;

  function mint(address _account, uint256 _amount) external;

  function setKeep3rV1Governance(address _governance) external;

  function acceptKeep3rV1Governance() external;

  function dispute(address _keeper) external;

  function slash(
    address _bonded,
    address _keeper,
    uint256 _amount
  ) external;

  function revoke(address _keeper) external;

  function resolve(address _keeper) external;

  function addJob(address _job) external;

  function removeJob(address _job) external;

  function addKPRCredit(address _job, uint256 _amount) external;

  function approveLiquidity(address _liquidity) external;

  function revokeLiquidity(address _liquidity) external;

  function setKeep3rHelper(address _keep3rHelper) external;

  function addVotes(address _voter, uint256 _amount) external;

  function removeVotes(address _voter, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import './IBaseErrors.sol';

interface IDustCollector is IBaseErrors {
  /// @notice Emitted when dust is sent
  /// @param _to The address which wil received the funds
  /// @param _token The token that will be transferred
  /// @param _amount The amount of the token that will be transferred
  event DustSent(address _token, uint256 _amount, address _to);

  /// @notice Allows an authorized user to transfer the tokens or eth that may have been left in a contract
  /// @param _token The token that will be transferred
  /// @param _amount The amont of the token that will be transferred
  /// @param _to The address that will receive the idle funds
  function sendDust(
    address _token,
    uint256 _amount,
    address _to
  ) external;
}