// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IVaultStrategyDataStore.sol";
import "./roles/Governable.sol";
import "./BaseVault.sol";

/// @notice This contract will allow governance and managers to configure strategies and withdraw queues for a vault.
///  This contract should be deployed first, and then the address of this contract should be used to deploy a vault.
///  Once the vaults & strategies are deployed, call `addStrategy` function to assign a strategy to a vault.
contract VaultStrategyDataStore is IVaultStrategyDataStore, Context, Governable {
  /// @notice parameters associated with a strategy
  struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    address vault;
  }

  struct VaultStrategyConfig {
    // save the vault address in the mapping too to allow us to check if the vaultStrategy is actually created
    // it can also be used to validate if msg.sender if the vault itself
    address vault;
    address manager;
    uint256 totalDebtRatio;
    uint256 maxTotalDebtRatio;
    address[] withdrawQueue;
    address[] strategies;
  }

  event VaultManagerUpdated(address indexed _vault, address indexed _manager);

  event StrategyAdded(
    address indexed _vault,
    address indexed _strategyAddress,
    uint256 _debtRatio,
    uint256 _minDebtPerHarvest,
    uint256 _maxDebtPerHarvest,
    uint256 _performanceFee
  );

  event WithdrawQueueUpdated(address indexed _vault, address[] _queue);
  event StrategyDebtRatioUpdated(address indexed _vault, address indexed _strategy, uint256 _debtRatio);
  event StrategyMinDebtPerHarvestUpdated(address indexed _vault, address indexed _strategy, uint256 _minDebtPerHarvest);
  event StrategyMaxDebtPerHarvestUpdated(address indexed _vault, address indexed _strategy, uint256 _maxDebtPerHarvest);
  event StrategyPerformanceFeeUpdated(address indexed _vault, address indexed _strategy, uint256 _performanceFee);
  event StrategyMigrated(address indexed _vault, address indexed _old, address indexed _new);
  event StrategyRevoked(address indexed _vault, address indexed _strategy);
  event StrategyRemovedFromQueue(address indexed _vault, address indexed _strategy);
  event StrategyAddedToQueue(address indexed _vault, address indexed _strategy);
  event MaxTotalRatioUpdated(address indexed _vault, uint256 _maxTotalDebtRatio);

  /// @notice The maximum basis points. 1 basis point is 0.01% and 100% is 10000 basis points
  uint256 public constant MAX_BASIS_POINTS = 10_000;
  uint256 public constant DEFAULT_MAX_TOTAL_DEBT_RATIO = 9500;
  /// @notice maximum number of strategies allowed for the withdraw queue
  uint256 public constant MAX_STRATEGIES_PER_VAULT = 20;

  /// @notice vaults and their strategy-related configs
  mapping(address => VaultStrategyConfig) internal configs;

  /// @notice vaults and their strategies.
  /// @dev Can't put into the {VaultStrategyConfig} struct because nested mappings can't be constructed
  mapping(address => mapping(address => StrategyParams)) internal strategies;

  // solhint-disable-next-line
  constructor(address _governance) Governable(_governance) {}

  /// @notice returns the performance fee for a strategy in basis points.
  /// @param _vault the address of the vault
  /// @param _strategy the address of the strategy
  /// @return performance fee in basis points (100 = 1%)
  function strategyPerformanceFee(address _vault, address _strategy) external view returns (uint256) {
    require(_vault != address(0) && _strategy != address(0), "invalid address");
    if (_strategyExists(_vault, _strategy)) {
      return strategies[_vault][_strategy].performanceFee;
    } else {
      return 0;
    }
  }

  /// @notice returns the time when a strategy is added to a vault
  /// @param _vault the address of the vault
  /// @param _strategy the address of the strategy
  /// @return the time when the strategy is added to the vault. 0 means the strategy is not added to the vault.
  function strategyActivation(address _vault, address _strategy) external view returns (uint256) {
    require(_vault != address(0) && _strategy != address(0), "invalid address");
    if (_strategyExists(_vault, _strategy)) {
      return strategies[_vault][_strategy].activation;
    } else {
      return 0;
    }
  }

  /// @notice returns the debt ratio for a strategy in basis points.
  /// @param _vault the address of the vault
  /// @param _strategy the address of the strategy
  /// @return debt ratio in basis points (100 = 1%). Total debt ratio of all strategies for a vault can not exceed the MaxTotalDebtRatio of the vault.
  function strategyDebtRatio(address _vault, address _strategy) external view returns (uint256) {
    require(_vault != address(0) && _strategy != address(0), "invalid address");
    if (_strategyExists(_vault, _strategy)) {
      return strategies[_vault][_strategy].debtRatio;
    } else {
      return 0;
    }
  }

  /// @notice returns the minimum value that the strategy can borrow from the vault per harvest.
  /// @param _vault the address of the vault
  /// @param _strategy the address of the strategy
  /// @return minimum value the strategy should borrow from the vault per harvest
  function strategyMinDebtPerHarvest(address _vault, address _strategy) external view returns (uint256) {
    require(_vault != address(0) && _strategy != address(0), "invalid address");
    if (_strategyExists(_vault, _strategy)) {
      return strategies[_vault][_strategy].minDebtPerHarvest;
    } else {
      return 0;
    }
  }

  /// @notice returns the maximum value that the strategy can borrow from the vault per harvest.
  /// @param _vault the address of the vault
  /// @param _strategy the address of the strategy
  /// @return maximum value the strategy should borrow from the vault per harvest
  function strategyMaxDebtPerHarvest(address _vault, address _strategy) external view returns (uint256) {
    require(_vault != address(0) && _strategy != address(0), "invalid address");
    if (_strategyExists(_vault, _strategy)) {
      return strategies[_vault][_strategy].maxDebtPerHarvest;
    } else {
      return type(uint256).max;
    }
  }

  /// @notice returns the total debt ratio of all the strategies for the vault in basis points
  /// @param _vault the address of the vault
  /// @return the total debt ratio of all the strategies. Should never exceed the value of MaxTotalDebtRatio
  function vaultTotalDebtRatio(address _vault) external view returns (uint256) {
    require(_vault != address(0), "invalid vault");
    if (_vaultExists(_vault)) {
      return configs[_vault].totalDebtRatio;
    } else {
      return 0;
    }
  }

  /// @notice returns the address of strategies that will be withdrawn from if the vault needs to withdraw
  /// @param _vault the address of the vault
  /// @return the address of strategies for withdraw. First strategies in the queue will be withdrawn first.
  function withdrawQueue(address _vault) external view returns (address[] memory) {
    require(_vault != address(0), "invalid vault");
    if (_vaultExists(_vault)) {
      return configs[_vault].withdrawQueue;
    } else {
      return new address[](0);
    }
  }

  /// @notice returns the manager address of the vault. Could be address(0) if it's not set
  /// @param _vault the address of the vault
  /// @return the manager address of the vault
  function vaultManager(address _vault) external view returns (address) {
    require(_vault != address(0), "invalid vault");
    if (_vaultExists(_vault)) {
      return configs[_vault].manager;
    } else {
      return address(0);
    }
  }

  /// @notice returns the maxTotalDebtRatio of the vault in basis points. It limits the maximum amount of funds that all strategies of the value can borrow.
  /// @param _vault the address of the vault
  /// @return the maxTotalDebtRatio config of the vault
  function vaultMaxTotalDebtRatio(address _vault) external view returns (uint256) {
    require(_vault != address(0), "invalid vault");
    if (_vaultExists(_vault)) {
      return configs[_vault].maxTotalDebtRatio;
    } else {
      return DEFAULT_MAX_TOTAL_DEBT_RATIO;
    }
  }

  /// @notice returns the list of strategies used by the vault. Use `strategyDebtRatio` to query fund allocation for a strategy.
  /// @param _vault the address of the vault
  /// @return the strategies of the vault
  function vaultStrategies(address _vault) external view returns (address[] memory) {
    require(_vault != address(0), "invalid vault");
    if (_vaultExists(_vault)) {
      return configs[_vault].strategies;
    } else {
      return new address[](0);
    }
  }

  /// @notice set the manager of the vault. Can only be called by the governance.
  /// @param _vault the address of the vault
  /// @param _manager the address of the manager for the vault
  function setVaultManager(address _vault, address _manager) external onlyGovernance {
    require(_vault != address(0), "invalid vault");
    _initConfigsIfNeeded(_vault);
    if (configs[_vault].manager != _manager) {
      configs[_vault].manager = _manager;
      emit VaultManagerUpdated(_vault, _manager);
    }
  }

  /// @notice set the maxTotalDebtRatio of the value.
  /// @param _vault the address of the vault
  /// @param _maxTotalDebtRatio the maximum total debt ratio value in basis points. Can not exceed 10000 (100%).
  function setMaxTotalDebtRatio(address _vault, uint256 _maxTotalDebtRatio) external {
    require(_vault != address(0), "invalid vault");
    _onlyGovernanceOrVaultManager(_vault);
    require(_maxTotalDebtRatio <= MAX_BASIS_POINTS, "invalid value");
    _initConfigsIfNeeded(_vault);
    if (configs[_vault].maxTotalDebtRatio != _maxTotalDebtRatio) {
      configs[_vault].maxTotalDebtRatio = _maxTotalDebtRatio;
      emit MaxTotalRatioUpdated(_vault, _maxTotalDebtRatio);
    }
  }

  /// @notice add the given strategy to the vault
  /// @param _vault the address of the vault to add strategy to
  /// @param _strategy the address of the strategy contract
  /// @param _debtRatio the percentage of the asset in the vault that will be allocated to the strategy, in basis points (1 BP is 0.01%).
  /// @param _minDebtPerHarvest lower limit on the increase of debt since last harvest
  /// @param _maxDebtPerHarvest upper limit on the increase of debt since last harvest
  /// @param _performanceFee the fee that the strategist will receive based on the strategy's performance. In basis points.
  function addStrategy(
    address _vault,
    address _strategy,
    uint256 _debtRatio,
    uint256 _minDebtPerHarvest,
    uint256 _maxDebtPerHarvest,
    uint256 _performanceFee
  ) external {
    _onlyGovernanceOrVaultManager(_vault);
    require(_strategy != address(0), "strategy address is not valid");
    _initConfigsIfNeeded(_vault);
    require(configs[_vault].withdrawQueue.length < MAX_STRATEGIES_PER_VAULT, "too many strategies");
    require(strategies[_vault][_strategy].activation == 0, "strategy already added");
    if (IStrategy(_strategy).vault() != address(0)) {
      require(IStrategy(_strategy).vault() == _vault, "wrong vault");
    }
    require(_minDebtPerHarvest <= _maxDebtPerHarvest, "invalid minDebtPerHarvest value");
    require(
      configs[_vault].totalDebtRatio + _debtRatio <= configs[_vault].maxTotalDebtRatio,
      "total debtRatio over limit"
    );
    require(_performanceFee <= MAX_BASIS_POINTS / 2, "invalid performance fee");

    /* solhint-disable not-rely-on-time */
    strategies[_vault][_strategy] = StrategyParams({
      performanceFee: _performanceFee,
      activation: block.timestamp,
      debtRatio: _debtRatio,
      minDebtPerHarvest: _minDebtPerHarvest,
      maxDebtPerHarvest: _maxDebtPerHarvest,
      vault: _vault
    });
    /* solhint-enable */

    require(IBaseVault(_vault).addStrategy(_strategy), "vault error");
    if (IStrategy(_strategy).vault() == address(0)) {
      IStrategy(_strategy).setVault(_vault);
    }

    emit StrategyAdded(_vault, _strategy, _debtRatio, _minDebtPerHarvest, _maxDebtPerHarvest, _performanceFee);
    configs[_vault].totalDebtRatio += _debtRatio;
    configs[_vault].withdrawQueue.push(_strategy);
    configs[_vault].strategies.push(_strategy);
  }

  /// @notice update the performance fee of the given strategy
  /// @param _vault the address of the vault
  /// @param _strategy the address of the strategy contract
  /// @param _performanceFee the new performance fee in basis points
  function updateStrategyPerformanceFee(
    address _vault,
    address _strategy,
    uint256 _performanceFee
  ) external onlyGovernance {
    _validateVaultExists(_vault); //the strategy should be added already means the vault should exist
    _validateStrategy(_vault, _strategy);
    require(_performanceFee <= MAX_BASIS_POINTS / 2, "invalid performance fee");
    strategies[_vault][_strategy].performanceFee = _performanceFee;
    emit StrategyPerformanceFeeUpdated(_vault, _strategy, _performanceFee);
  }

  /// @notice update the debt ratio for the given strategy
  /// @param _vault the address of the vault
  /// @param _strategy the address of the strategy contract
  /// @param _debtRatio the new debt ratio of the strategy in basis points
  function updateStrategyDebtRatio(
    address _vault,
    address _strategy,
    uint256 _debtRatio
  ) external {
    _validateVaultExists(_vault);
    // This could be called by the Vault itself to update the debt ratio when a strategy is not performing well
    _onlyAdminOrVault(_vault);
    _validateStrategy(_vault, _strategy);
    _updateStrategyDebtRatio(_vault, _strategy, _debtRatio);
  }

  /// @notice update the minDebtHarvest for the given strategy
  /// @param _vault the address of the vault
  /// @param _strategy the address of the strategy contract
  /// @param _minDebtPerHarvest the new minDebtPerHarvest value
  function updateStrategyMinDebtHarvest(
    address _vault,
    address _strategy,
    uint256 _minDebtPerHarvest
  ) external {
    _validateVaultExists(_vault);
    _onlyGovernanceOrVaultManager(_vault);
    _validateStrategy(_vault, _strategy);
    require(strategies[_vault][_strategy].maxDebtPerHarvest >= _minDebtPerHarvest, "invalid minDebtPerHarvest");
    strategies[_vault][_strategy].minDebtPerHarvest = _minDebtPerHarvest;
    emit StrategyMinDebtPerHarvestUpdated(_vault, _strategy, _minDebtPerHarvest);
  }

  /// @notice update the maxDebtHarvest for the given strategy
  /// @param _vault the address of the vault
  /// @param _strategy the address of the strategy contract
  /// @param _maxDebtPerHarvest the new maxDebtPerHarvest value
  function updateStrategyMaxDebtHarvest(
    address _vault,
    address _strategy,
    uint256 _maxDebtPerHarvest
  ) external {
    _validateVaultExists(_vault);
    _onlyGovernanceOrVaultManager(_vault);
    _validateStrategy(_vault, _strategy);
    require(strategies[_vault][_strategy].minDebtPerHarvest <= _maxDebtPerHarvest, "invalid maxDebtPerHarvest");
    strategies[_vault][_strategy].maxDebtPerHarvest = _maxDebtPerHarvest;
    emit StrategyMaxDebtPerHarvestUpdated(_vault, _strategy, _maxDebtPerHarvest);
  }

  /// @notice updates the withdrawalQueue to match the addresses and order specified by `queue`.
  ///  There can be fewer strategies than the maximum, as well as fewer than
  ///  the total number of strategies active in the vault.
  ///  This may only be called by governance or management.
  /// @dev This is order sensitive, specify the addresses in the order in which
  ///  funds should be withdrawn (so `queue`[0] is the first Strategy withdrawn
  ///  from, `queue`[1] is the second, etc.)
  ///  This means that the least impactful Strategy (the Strategy that will have
  ///  its core positions impacted the least by having funds removed) should be
  ///  at `queue`[0], then the next least impactful at `queue`[1], and so on.
  /// @param _vault the address of the vault
  /// @param _queue The array of addresses to use as the new withdrawal queue. This is order sensitive.
  function setWithdrawQueue(address _vault, address[] calldata _queue) external {
    require(_vault != address(0), "invalid vault");
    require(_queue.length <= MAX_STRATEGIES_PER_VAULT, "invalid queue size");
    _onlyGovernanceOrVaultManager(_vault);
    _initConfigsIfNeeded(_vault);
    address[] storage withdrawQueue_ = configs[_vault].withdrawQueue;
    uint256 oldQueueSize = withdrawQueue_.length;
    for (uint256 i = 0; i < _queue.length; i++) {
      address temp = _queue[i];
      require(strategies[_vault][temp].activation > 0, "invalid queue");
      if (i > withdrawQueue_.length - 1) {
        withdrawQueue_.push(temp);
      } else {
        withdrawQueue_[i] = temp;
      }
    }
    if (oldQueueSize > _queue.length) {
      for (uint256 j = oldQueueSize; j > _queue.length; j--) {
        withdrawQueue_.pop();
      }
    }
    emit WithdrawQueueUpdated(_vault, _queue);
  }

  /// @notice add the strategy to the `withdrawQueue`
  /// @dev the strategy will only be appended to the `withdrawQueue`
  /// @param _vault the address of the vault
  /// @param _strategy the strategy to add
  function addStrategyToWithdrawQueue(address _vault, address _strategy) external {
    _validateVaultExists(_vault);
    _onlyGovernanceOrVaultManager(_vault);
    _validateStrategy(_vault, _strategy);
    VaultStrategyConfig storage config_ = configs[_vault];
    require(config_.withdrawQueue.length + 1 <= MAX_STRATEGIES_PER_VAULT, "too many strategies");
    for (uint256 i = 0; i < config_.withdrawQueue.length; i++) {
      require(config_.withdrawQueue[i] != _strategy, "strategy already exist");
    }
    config_.withdrawQueue.push(_strategy);
    emit StrategyAddedToQueue(_vault, _strategy);
  }

  /// @notice remove the strategy from the `withdrawQueue`
  /// @dev we don't do this with revokeStrategy because it should still be possible to withdraw from the Strategy if it's unwinding.
  /// @param _vault the address of the vault
  /// @param _strategy the strategy to remove
  function removeStrategyFromWithdrawQueue(address _vault, address _strategy) external {
    _validateVaultExists(_vault);
    _onlyGovernanceOrVaultManager(_vault);
    _validateStrategy(_vault, _strategy);
    VaultStrategyConfig storage config_ = configs[_vault];
    uint256 i = 0;
    for (i = 0; i < config_.withdrawQueue.length; i++) {
      if (config_.withdrawQueue[i] == _strategy) {
        break;
      }
    }
    require(i < config_.withdrawQueue.length, "strategy does not exist");
    for (uint256 j = i; j < config_.withdrawQueue.length - 1; j++) {
      config_.withdrawQueue[j] = config_.withdrawQueue[j + 1];
    }
    config_.withdrawQueue.pop();
    emit StrategyRemovedFromQueue(_vault, _strategy);
  }

  /// @notice Migrate a Strategy, including all assets from `oldVersion` to `newVersion`. This may only be called by governance.
  /// @dev Strategy must successfully migrate all capital and positions to new Strategy, or else this will upset the balance of the Vault.
  ///  The new Strategy should be "empty" e.g. have no prior commitments to
  ///  this Vault, otherwise it could have issues.
  /// @param _vault the address of the vault
  /// @param _oldStrategy the existing strategy to migrate from
  /// @param _newStrategy the new strategy to migrate to
  function migrateStrategy(
    address _vault,
    address _oldStrategy,
    address _newStrategy
  ) external onlyGovernance {
    _validateVaultExists(_vault);
    _validateStrategy(_vault, _oldStrategy);
    require(_newStrategy != address(0), "invalid new strategy");
    require(strategies[_vault][_newStrategy].activation == 0, "new strategy already exists");

    StrategyParams memory params = strategies[_vault][_oldStrategy];
    _revokeStrategy(_vault, _oldStrategy);
    // _revokeStrategy will reduce the debt ratio
    configs[_vault].totalDebtRatio += params.debtRatio;
    //vs_.strategies[_oldStrategy].totalDebt = 0;

    strategies[_vault][_newStrategy] = StrategyParams({
      performanceFee: params.performanceFee,
      activation: params.activation,
      debtRatio: params.debtRatio,
      minDebtPerHarvest: params.minDebtPerHarvest,
      maxDebtPerHarvest: params.maxDebtPerHarvest,
      vault: params.vault
    });

    require(IBaseVault(_vault).migrateStrategy(_oldStrategy, _newStrategy), "vault error");
    emit StrategyMigrated(_vault, _oldStrategy, _newStrategy);
    for (uint256 i = 0; i < configs[_vault].withdrawQueue.length; i++) {
      if (configs[_vault].withdrawQueue[i] == _oldStrategy) {
        configs[_vault].withdrawQueue[i] = _newStrategy;
      }
    }
    for (uint256 j = 0; j < configs[_vault].strategies.length; j++) {
      if (configs[_vault].strategies[j] == _oldStrategy) {
        configs[_vault].strategies[j] = _newStrategy;
      }
    }
  }

  /// @notice Revoke a Strategy, setting its debt limit to 0 and preventing any future deposits.
  ///  This function should only be used in the scenario where the Strategy is
  ///  being retired but no migration of the positions are possible, or in the
  ///  extreme scenario that the Strategy needs to be put into "Emergency Exit"
  ///  mode in order for it to exit as quickly as possible. The latter scenario
  ///  could be for any reason that is considered "critical" that the Strategy
  ///  exits its position as fast as possible, such as a sudden change in market
  ///  conditions leading to losses, or an imminent failure in an external
  ///  dependency.
  ///  This may only be called by governance, or the manager.
  ///
  /// @param _vault the address of the vault
  /// @param _strategy The Strategy to revoke.
  function revokeStrategy(address _vault, address _strategy) external {
    _onlyGovernanceOrVaultManager(_vault);
    if (strategies[_vault][_strategy].debtRatio != 0) {
      _revokeStrategy(_vault, _strategy);
    }
  }

  /// @notice Note that a Strategy will only revoke itself during emergency shutdown.
  ///  This function will be invoked the strategy by itself.
  ///  The Strategy will call the vault first and the vault will then forward the request to this contract.
  ///  This is to keep the Strategy interface compatible with Yearn's
  ///  This should only be called by the vault itself.
  /// @param _strategy the address of the strategy to revoke
  function revokeStrategyByStrategy(address _strategy) external {
    _validateVaultExists(_msgSender());
    _validateStrategy(_msgSender(), _strategy);
    if (strategies[_msgSender()][_strategy].debtRatio != 0) {
      _revokeStrategy(_msgSender(), _strategy);
    }
  }

  function _vaultExists(address _vault) internal view returns (bool) {
    if (configs[_vault].vault == _vault) {
      return true;
    }
    return false;
  }

  function _strategyExists(address _vault, address _strategy) internal view returns (bool) {
    if (strategies[_vault][_strategy].vault == _vault) {
      return true;
    }
    return false;
  }

  function _initConfigsIfNeeded(address _vault) internal {
    if (configs[_vault].vault != _vault) {
      configs[_vault] = VaultStrategyConfig({
        vault: _vault,
        manager: address(0),
        maxTotalDebtRatio: DEFAULT_MAX_TOTAL_DEBT_RATIO,
        totalDebtRatio: 0,
        withdrawQueue: new address[](0),
        strategies: new address[](0)
      });
    }
  }

  function _validateVaultExists(address _vault) internal view {
    require(_vault != address(0), "invalid vault");
    require(configs[_vault].vault == _vault, "no vault");
  }

  function _validateStrategy(address _vault, address _strategy) internal view {
    require(strategies[_vault][_strategy].activation > 0, "invalid strategy");
  }

  /// @dev make sure the valut exists and msg.send is either the governance or the manager of the vault
  ///   could be an modifier as well, but using internal functions to reduce the code size
  function _onlyGovernanceOrVaultManager(address _vault) internal view {
    require((governance == _msgSender()) || (configs[_vault].manager == _msgSender()), "not authorised");
  }

  function _onlyAdminOrVault(address _vault) internal view {
    require(
      (governance == _msgSender()) ||
        (configs[_vault].manager == _msgSender()) ||
        (configs[_msgSender()].vault == _vault),
      "not authorised"
    );
  }

  function _updateStrategyDebtRatio(
    address _vault,
    address _strategy,
    uint256 _debtRatio
  ) internal {
    VaultStrategyConfig storage config_ = configs[_vault];
    config_.totalDebtRatio = config_.totalDebtRatio - (strategies[_vault][_strategy].debtRatio);
    strategies[_vault][_strategy].debtRatio = _debtRatio;
    config_.totalDebtRatio = config_.totalDebtRatio + _debtRatio;
    require(config_.totalDebtRatio <= config_.maxTotalDebtRatio, "debtRatio over limit");
    emit StrategyDebtRatioUpdated(_vault, _strategy, _debtRatio);
  }

  function _revokeStrategy(address _vault, address _strategy) internal {
    configs[_vault].totalDebtRatio = configs[_vault].totalDebtRatio - strategies[_vault][_strategy].debtRatio;
    strategies[_vault][_strategy].debtRatio = 0;
    emit StrategyRevoked(_vault, _strategy);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStrategy {
  // *** Events *** //
  event Harvested(uint256 _profit, uint256 _loss, uint256 _debtPayment, uint256 _debtOutstanding);
  event StrategistUpdated(address _newStrategist);
  event KeeperUpdated(address _newKeeper);
  event RewardsUpdated(address _rewards);
  event MinReportDelayUpdated(uint256 _delay);
  event MaxReportDelayUpdated(uint256 _delay);
  event ProfitFactorUpdated(uint256 _profitFactor);
  event DebtThresholdUpdated(uint256 _debtThreshold);
  event EmergencyExitEnabled();

  // *** The following functions are used by the Vault *** //
  /// @notice returns the address of the token that the strategy wants
  function want() external view returns (IERC20);

  /// @notice the address of the Vault that the strategy belongs to
  function vault() external view returns (address);

  /// @notice if the strategy is active
  function isActive() external view returns (bool);

  /// @notice migrate the strategy to the new one
  function migrate(address _newStrategy) external;

  /// @notice withdraw the amount from the strategy
  function withdraw(uint256 _amount) external returns (uint256);

  /// @notice the amount of total assets managed by this strategy that should not acount towards the TVL of the strategy
  function delegatedAssets() external view returns (uint256);

  /// @notice the total assets that the strategy is managing
  function estimatedTotalAssets() external view returns (uint256);

  // *** public read functions that can be called by anyone *** //
  function name() external view returns (string memory);

  function keeper() external view returns (address);

  function strategist() external view returns (address);

  function tendTrigger(uint256 _callCost) external view returns (bool);

  function harvestTrigger(uint256 _callCost) external view returns (bool);

  // *** write functions that can be called by the govenance, the strategist or the keeper *** //
  function tend() external;

  function harvest() external;

  // *** write functions that can be called by the govenance or the strategist ***//
  function setStrategist(address _strategist) external;

  function setKeeper(address _keeper) external;

  function setRewards(address _rewards) external;

  function setVault(address _vault) external;

  /// @notice `minReportDelay` is the minimum number of blocks that should pass for `harvest()` to be called.
  function setMinReportDelay(uint256 _delay) external;

  function setMaxReportDelay(uint256 _delay) external;

  /// @notice `profitFactor` is used to determine if it's worthwhile to harvest, given gas costs.
  function setProfitFactor(uint256 _profitFactor) external;

  /// @notice Sets how far the Strategy can go into loss without a harvest and report being required.
  function setDebtThreshold(uint256 _debtThreshold) external;

  // *** write functions that can be called by the govenance, or the strategist, or the guardian, or the management *** //
  function setEmergencyExit() external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IVaultStrategyDataStore {
  function strategyPerformanceFee(address _vault, address _strategy) external view returns (uint256);

  function strategyActivation(address _vault, address _strategy) external view returns (uint256);

  function strategyDebtRatio(address _vault, address _strategy) external view returns (uint256);

  function strategyMinDebtPerHarvest(address _vault, address _strategy) external view returns (uint256);

  function strategyMaxDebtPerHarvest(address _vault, address _strategy) external view returns (uint256);

  function vaultTotalDebtRatio(address _vault) external view returns (uint256);

  function withdrawQueue(address _vault) external view returns (address[] memory);

  function revokeStrategyByStrategy(address _strategy) external;

  function setVaultManager(address _vault, address _manager) external;

  function setMaxTotalDebtRatio(address _vault, uint256 _maxTotalDebtRatio) external;

  function addStrategy(
    address _vault,
    address _strategy,
    uint256 _debtRatio,
    uint256 _minDebtPerHarvest,
    uint256 _maxDebtPerHarvest,
    uint256 _performanceFee
  ) external;

  function updateStrategyPerformanceFee(
    address _vault,
    address _strategy,
    uint256 _performanceFee
  ) external;

  function updateStrategyDebtRatio(
    address _vault,
    address _strategy,
    uint256 _debtRatio
  ) external;

  function updateStrategyMinDebtHarvest(
    address _vault,
    address _strategy,
    uint256 _minDebtPerHarvest
  ) external;

  function updateStrategyMaxDebtHarvest(
    address _vault,
    address _strategy,
    uint256 _maxDebtPerHarvest
  ) external;

  function migrateStrategy(
    address _vault,
    address _oldStrategy,
    address _newStrategy
  ) external;

  function revokeStrategy(address _vault, address _strategy) external;

  function setWithdrawQueue(address _vault, address[] calldata _queue) external;

  function addStrategyToWithdrawQueue(address _vault, address _strategy) external;

  function removeStrategyFromWithdrawQueue(address _vault, address _strategy) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

interface IGovernable {
  function proposeGovernance(address _pendingGovernance) external;

  function acceptGovernance() external;
}

abstract contract GovernableInternal {
  event GovenanceUpdated(address _govenance);
  event GovenanceProposed(address _pendingGovenance);

  /// @dev This contract is used as part of the Vault contract and it is upgradeable.
  ///  which means any changes to the state variables could corrupt the data. Do not modify these at all.
  /// @notice the address of the current governance
  address public governance;
  /// @notice the address of the pending governance
  address public pendingGovernance;

  /// @dev ensure msg.send is the governanace
  modifier onlyGovernance() {
    require(_getMsgSender() == governance, "governance only");
    _;
  }

  /// @dev ensure msg.send is the pendingGovernance
  modifier onlyPendingGovernance() {
    require(_getMsgSender() == pendingGovernance, "pending governance only");
    _;
  }

  /// @dev the deployer of the contract will be set as the initial governance
  // solhint-disable-next-line func-name-mixedcase
  function __Governable_init_unchained(address _governance) internal {
    require(_getMsgSender() != _governance, "invalid address");
    _updateGovernance(_governance);
  }

  ///@notice propose a new governance of the vault. Only can be called by the existing governance.
  ///@param _pendingGovernance the address of the pending governance
  function proposeGovernance(address _pendingGovernance) external onlyGovernance {
    require(_pendingGovernance != address(0), "invalid address");
    require(_pendingGovernance != governance, "already the governance");
    pendingGovernance = _pendingGovernance;
    emit GovenanceProposed(_pendingGovernance);
  }

  ///@notice accept the proposal to be the governance of the vault. Only can be called by the pending governance.
  function acceptGovernance() external onlyPendingGovernance {
    _updateGovernance(pendingGovernance);
  }

  function _updateGovernance(address _pendingGovernance) internal {
    governance = _pendingGovernance;
    emit GovenanceUpdated(governance);
  }

  /// @dev provides an internal function to allow reduce the contract size
  function _onlyGovernance() internal view {
    require(_getMsgSender() == governance, "governance only");
  }

  function _getMsgSender() internal view virtual returns (address);
}

/// @dev Add a `governance` and a `pendingGovernance` role to the contract, and implements a 2-phased nominatiom process to change the governance.
///   Also provides a modifier to allow controlling access to functions of the contract.
contract Governable is Context, GovernableInternal {
  constructor(address _governance) GovernableInternal() {
    __Governable_init_unchained(_governance);
  }

  function _getMsgSender() internal view override returns (address) {
    return _msgSender();
  }
}

/// @dev ungradeable version of the {Governable} contract. Can be used as part of an upgradeable contract.
abstract contract GovernableUpgradeable is ContextUpgradeable, GovernableInternal {
  // solhint-disable-next-line no-empty-blocks
  constructor() {}

  // solhint-disable-next-line func-name-mixedcase
  function __Governable_init(address _governance) internal {
    __Context_init();
    __Governable_init_unchained(_governance);
  }

  // solhint-disable-next-line func-name-mixedcase
  function _getMsgSender() internal view override returns (address) {
    return _msgSender();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IVaultStrategyDataStore.sol";
import "./VaultMetaDataStore.sol";

import {StrategyInfo} from "../interfaces/IVault.sol";

// the Vault itself also represents an ERC20 token, which means it also inherits all methods that are available on the ERC20 interface.
// This token is the shares that the users will get when they deposit money into the Vault
interface IBaseVault is IERC20Upgradeable, IERC20PermitUpgradeable {
  function addStrategy(address _strategy) external returns (bool);

  function migrateStrategy(address _oldVersion, address _newVersion) external returns (bool);

  function revokeStrategy() external;
}

/// @dev This contract is marked abstract to avoid being used directly.
///  NOTE: do not add any new state variables to this contract. If needed, see {VaultDataStorage.sol} instead.
abstract contract BaseVault is IBaseVault, ERC20PermitUpgradeable, VaultMetaDataStore {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event StrategyAdded(address indexed _strategy);
  event StrategyMigrated(address indexed _oldVersion, address indexed _newVersion);
  event StrategyRevoked(address indexed _strategy);

  // solhint-disable-next-line no-empty-blocks
  constructor() {}

  // solhint-disable-next-line
  function __BaseVault__init_unchained() internal {}

  // solhint-disable-next-line func-name-mixedcase
  function __BaseVault__init(
    string memory _name,
    string memory _symbol,
    address _governance,
    address _gatekeeper,
    address _rewards,
    address _strategyDataStoreAddress,
    address _accessManager,
    address _vaultRewards
  ) internal {
    __ERC20_init(_name, _symbol);
    __ERC20Permit_init(_name);
    __VaultMetaDataStore_init(
      _governance,
      _gatekeeper,
      _rewards,
      _strategyDataStoreAddress,
      _accessManager,
      _vaultRewards
    );
    __BaseVault__init_unchained();
  }

  /// @notice returns decimals value of the vault
  function decimals() public view override returns (uint8) {
    return vaultDecimals;
  }

  /// @notice Init a new strategy. This should only be called by the {VaultStrategyDataStore} and should not be invoked manually.
  ///   Use {VaultStrategyDataStore.addStrategy} to manually add a strategy to a Vault.
  /// @dev This will be called by the {VaultStrategyDataStore} when a strategy is added to a given Vault.
  function addStrategy(address _strategy) external virtual returns (bool) {
    _onlyNotEmergencyShutdown();
    _onlyStrategyDataStore();
    return _addStrategy(_strategy);
  }

  /// @notice Migrate a new strategy. This should only be called by the {VaultStrategyDataStore} and should not be invoked manually.
  ///   Use {VaultStrategyDataStore.migrateStrategy} to manually migrate a strategy for a Vault.
  /// @dev This will called be the {VaultStrategyDataStore} when a strategy is migrated.
  ///  This will then call the strategy to migrate (as the strategy only allows the vault to call the migrate function).
  function migrateStrategy(address _oldVersion, address _newVersion) external virtual returns (bool) {
    _onlyStrategyDataStore();
    return _migrateStrategy(_oldVersion, _newVersion);
  }

  /// @notice called by the strategy to revoke itself. Should not be called by any other means.
  ///  Use {VaultStrategyDataStore.revokeStrategy} to revoke a strategy manaully.
  /// @dev The strategy could talk to the {VaultStrategyDataStore} directly when revoking itself.
  ///  However, that means we will need to change the interfaces to Strategies and make them incompatible with Yearn's strategies.
  ///  To avoid that, the strategies will continue talking to the Vault and the Vault will then let the {VaultStrategyDataStore} know.
  function revokeStrategy() external {
    require(strategies[_msgSender()].activation > 0, "not authorised");
    _strategyDataStore().revokeStrategyByStrategy(_msgSender());
    emit StrategyRevoked(_msgSender());
  }

  function strategy(address _strategy) external view returns (StrategyInfo memory) {
    return strategies[_strategy];
  }

  function strategyDebtRatio(address _strategy) external view returns (uint256) {
    return _strategyDataStore().strategyDebtRatio(address(this), _strategy);
  }

  function _strategyDataStore() internal view returns (IVaultStrategyDataStore) {
    return IVaultStrategyDataStore(strategyDataStore);
  }

  function _onlyStrategyDataStore() internal view {
    require(_msgSender() == strategyDataStore, "only strategy store");
  }

  /// @dev ensure the vault is not in emergency shutdown mode
  function _onlyNotEmergencyShutdown() internal view {
    require(emergencyShutdown == false, "emergency shutdown");
  }

  function _validateStrategy(address _strategy) internal view {
    require(strategies[_strategy].activation > 0, "invalid strategy");
  }

  function _addStrategy(address _strategy) internal returns (bool) {
    /* solhint-disable not-rely-on-time */
    strategies[_strategy] = StrategyInfo({
      activation: block.timestamp,
      lastReport: block.timestamp,
      totalDebt: 0,
      totalGain: 0,
      totalLoss: 0
    });
    emit StrategyAdded(_strategy);
    return true;
    /* solhint-enable */
  }

  function _migrateStrategy(address _oldVersion, address _newVersion) internal returns (bool) {
    StrategyInfo memory info = strategies[_oldVersion];
    strategies[_oldVersion].totalDebt = 0;
    strategies[_newVersion] = StrategyInfo({
      activation: info.activation,
      lastReport: info.lastReport,
      totalDebt: info.lastReport,
      totalGain: 0,
      totalLoss: 0
    });
    IStrategy(_oldVersion).migrate(_newVersion);
    emit StrategyMigrated(_oldVersion, _newVersion);
    return true;
  }

  function _sweep(
    address _token,
    uint256 _amount,
    address _to
  ) internal {
    IERC20Upgradeable token_ = IERC20Upgradeable(_token);
    _amount = Math.min(_amount, token_.balanceOf(address(this)));
    token_.safeTransfer(_to, _amount);
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
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./draft-IERC20PermitUpgradeable.sol";
import "../ERC20Upgradeable.sol";
import "../../../utils/cryptography/draft-EIP712Upgradeable.sol";
import "../../../utils/cryptography/ECDSAUpgradeable.sol";
import "../../../utils/CountersUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20PermitUpgradeable is Initializable, ERC20Upgradeable, IERC20PermitUpgradeable, EIP712Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal initializer {
        __Context_init_unchained();
        __EIP712_init_unchained(name, "1");
        __ERC20Permit_init_unchained(name);
    }

    function __ERC20Permit_init_unchained(string memory name) internal initializer {
        _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
pragma solidity =0.8.9;

import "./roles/Governable.sol";
import "./roles/Gatekeeperable.sol";
import "./VaultDataStorage.sol";

///  @dev NOTE: do not add any new state variables to this contract. If needed, see {VaultDataStorage.sol} instead.
abstract contract VaultMetaDataStore is GovernableUpgradeable, Gatekeeperable, VaultDataStorage {
  event EmergencyShutdown(bool _active);
  event HealthCheckUpdated(address indexed _healthCheck);
  event RewardsUpdated(address indexed _rewards);
  event ManagementFeeUpdated(uint256 _managementFee);
  event StrategyDataStoreUpdated(address indexed _strategyDataStore);
  event DepositLimitUpdated(uint256 _limit);
  event LockedProfitDegradationUpdated(uint256 _degradation);
  event AccessManagerUpdated(address indexed _accessManager);
  event VaultRewardsContractUpdated(address indexed _vaultRewards);

  /// @notice The maximum basis points. 1 basis point is 0.01% and 100% is 10000 basis points
  uint256 internal constant MAX_BASIS_POINTS = 10_000;

  // solhint-disable-next-line no-empty-blocks
  constructor() {}

  // solhint-disable-next-line func-name-mixedcase
  function __VaultMetaDataStore_init(
    address _governance,
    address _gatekeeper,
    address _rewards,
    address _strategyDataStore,
    address _accessManager,
    address _vaultRewards
  ) internal {
    __Governable_init(_governance);
    __Gatekeeperable_init(_gatekeeper);
    __VaultDataStorage_init();
    __VaultMetaDataStore_init_unchained(_rewards, _strategyDataStore, _accessManager, _vaultRewards);
  }

  // solhint-disable-next-line func-name-mixedcase
  function __VaultMetaDataStore_init_unchained(
    address _rewards,
    address _strategyDataStore,
    address _accessManager,
    address _vaultRewards
  ) internal {
    _updateRewards(_rewards);
    _updateStrategyDataStore(_strategyDataStore);
    _updateAccessManager(_accessManager);
    _updateVaultRewardsContract(_vaultRewards);
  }

  /// @notice set the wallet address to send the collected fees to. Only can be called by the governance.
  /// @param _rewards the new wallet address to send the fees to.
  function setRewards(address _rewards) external {
    _onlyGovernance();
    _updateRewards(_rewards);
  }

  /// @notice set the management fee in basis points. 1 basis point is 0.01% and 100% is 10000 basis points.
  function setManagementFee(uint256 _managementFee) external {
    _onlyGovernance();
    _updateManagementFee(_managementFee);
  }

  function setGatekeeper(address _gatekeeper) external {
    _onlyGovernance();
    _updateGatekeeper(_gatekeeper);
  }

  function setHealthCheck(address _healthCheck) external {
    _onlyGovernanceOrGatekeeper();
    _updateHealthCheck(_healthCheck);
  }

  /// @notice Activates or deactivates Vault mode where all Strategies go into full withdrawal.
  /// During Emergency Shutdown:
  /// 1. No Users may deposit into the Vault (but may withdraw as usual.)
  /// 2. Governance may not add new Strategies.
  /// 3. Each Strategy must pay back their debt as quickly as reasonable to minimally affect their position.
  /// 4. Only Governance may undo Emergency Shutdown.
  ///
  /// See contract level note for further details.
  ///
  /// This may only be called by governance or the guardian.
  /// @param _active If true, the Vault goes into Emergency Shutdown. If false, the Vault goes back into Normal Operation.
  function setVaultEmergencyShutdown(bool _active) external {
    if (_active) {
      _onlyGovernanceOrGatekeeper();
    } else {
      _onlyGovernance();
    }
    if (emergencyShutdown != _active) {
      emergencyShutdown = _active;
      emit EmergencyShutdown(_active);
    }
  }

  /// @notice Changes the locked profit degradation.
  /// @param _degradation The rate of degradation in percent per second scaled to 1e18.
  function setLockedProfileDegradation(uint256 _degradation) external {
    _onlyGovernance();
    require(_degradation <= DEGRADATION_COEFFICIENT, "degradation value is too large");
    if (lockedProfitDegradation != _degradation) {
      lockedProfitDegradation = _degradation;
      emit LockedProfitDegradationUpdated(_degradation);
    }
  }

  function setDepositLimit(uint256 _limit) external {
    _onlyGovernanceOrGatekeeper();
    _updateDepositLimit(_limit);
  }

  function setAccessManager(address _accessManager) external {
    _onlyGovernanceOrGatekeeper();
    _updateAccessManager(_accessManager);
  }

  function _onlyGovernanceOrGatekeeper() internal view {
    require((_msgSender() == governance) || (gatekeeper != address(0) && gatekeeper == _msgSender()), "not authorised");
  }

  function _updateRewards(address _rewards) internal {
    require(_rewards != address(0), "invalid address");
    if (rewards != _rewards) {
      rewards = _rewards;
      emit RewardsUpdated(_rewards);
    }
  }

  function _updateManagementFee(uint256 _managementFee) internal {
    require(_managementFee < MAX_BASIS_POINTS, "invalid input");
    if (managementFee != _managementFee) {
      managementFee = _managementFee;
      emit ManagementFeeUpdated(_managementFee);
    }
  }

  function _updateHealthCheck(address _healthCheck) internal {
    if (healthCheck != _healthCheck) {
      healthCheck = _healthCheck;
      emit HealthCheckUpdated(_healthCheck);
    }
  }

  function _updateStrategyDataStore(address _strategyDataStore) internal {
    require(_strategyDataStore != address(0), "invalid input");
    if (strategyDataStore != _strategyDataStore) {
      strategyDataStore = _strategyDataStore;
      emit StrategyDataStoreUpdated(_strategyDataStore);
    }
  }

  function _updateDepositLimit(uint256 _depositLimit) internal {
    if (depositLimit != _depositLimit) {
      depositLimit = _depositLimit;
      emit DepositLimitUpdated(_depositLimit);
    }
  }

  function _updateAccessManager(address _accessManager) internal {
    if (accessManager != _accessManager) {
      accessManager = _accessManager;
      emit AccessManagerUpdated(_accessManager);
    }
  }

  function _updateVaultRewardsContract(address _vaultRewards) internal {
    if (vaultRewards != _vaultRewards) {
      vaultRewards = _vaultRewards;
      emit VaultRewardsContractUpdated(_vaultRewards);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

struct StrategyInfo {
  uint256 activation;
  uint256 lastReport;
  uint256 totalDebt;
  uint256 totalGain;
  uint256 totalLoss;
}

interface IVault is IERC20, IERC20Permit {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint256);

  function activation() external view returns (uint256);

  function rewards() external view returns (address);

  function managementFee() external view returns (uint256);

  function gatekeeper() external view returns (address);

  function governance() external view returns (address);

  function strategyDataStore() external view returns (address);

  function healthCheck() external view returns (address);

  function emergencyShutdown() external view returns (bool);

  function lockedProfitDegradation() external view returns (uint256);

  function depositLimit() external view returns (uint256);

  function lastReport() external view returns (uint256);

  function lockedProfit() external view returns (uint256);

  function totalDebt() external view returns (uint256);

  function token() external view returns (address);

  function totalAsset() external view returns (uint256);

  function availableDepositLimit() external view returns (uint256);

  function maxAvailableShares() external view returns (uint256);

  function pricePerShare() external view returns (uint256);

  function debtOutstanding(address _strategy) external view returns (uint256);

  function creditAvailable(address _strategy) external view returns (uint256);

  function expectedReturn(address _strategy) external view returns (uint256);

  function strategy(address _strategy) external view returns (StrategyInfo memory);

  function strategyDebtRatio(address _strategy) external view returns (uint256);

  function setRewards(address _rewards) external;

  function setManagementFee(uint256 _managementFee) external;

  function setGatekeeper(address _gatekeeper) external;

  function setStrategyDataStore(address _strategyDataStoreContract) external;

  function setHealthCheck(address _healthCheck) external;

  function setVaultEmergencyShutdown(bool _active) external;

  function setLockedProfileDegradation(uint256 _degradation) external;

  function setDepositLimit(uint256 _limit) external;

  function sweep(address _token, uint256 _amount) external;

  function addStrategy(address _strategy) external returns (bool);

  function migrateStrategy(address _oldVersion, address _newVersion) external returns (bool);

  function revokeStrategy() external;

  /// @notice deposit the given amount into the vault, and return the number of shares
  function deposit(uint256 _amount, address _recipient) external returns (uint256);

  /// @notice burn the given amount of shares from the vault, and return the number of underlying tokens recovered
  function withdraw(
    uint256 _shares,
    address _recipient,
    uint256 _maxLoss
  ) external returns (uint256);

  function report(
    uint256 _gain,
    uint256 _loss,
    uint256 _debtPayment
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
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
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
pragma solidity =0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/// @dev Add the `Gatekeeper` role.
///   Gatekeepers will help ensure the security of the vaults. They can set vault limits, pause deposits or withdraws.
///   For vaults that defined restricted access, they will be able to control the access to these vaults as well.
///   This contract also provides a `onlyGatekeeper` modifier to allow controlling access to functions of the contract.
abstract contract Gatekeeperable is ContextUpgradeable {
  event GatekeeperUpdated(address _guardian);

  /// @notice the address of the guardian for the vault
  /// @dev This contract is used as part of the Vault contract and it is upgradeable.
  ///  which means any changes to the state variables could corrupt the data. Do not modify this at all.
  address public gatekeeper;

  // /// @dev make sure msg.sender is the guardian or the governance
  // modifier onlyGovernanceOrGuardian() {
  //   require((_msgSender() == governance) || (_msgSender() == guardian), "governance or guardian only");
  //   _;
  // }
  // solhint-disable-next-line no-empty-blocks
  constructor() {}

  /// @dev set the initial value for the gatekeeper. The deployer can not be the gatekeeper.
  /// @param _gatekeeper the default address of the guardian
  // solhint-disable-next-line func-name-mixedcase
  function __Gatekeeperable_init_unchained(address _gatekeeper) internal {
    require(_msgSender() != _gatekeeper, "invalid address");
    _updateGatekeeper(_gatekeeper);
  }

  // solhint-disable-next-line func-name-mixedcase
  function __Gatekeeperable_init(address _gatekeeper) internal {
    __Context_init();
    __Gatekeeperable_init_unchained(_gatekeeper);
  }

  ///@dev this can be used internally to update the gatekeep. If you want to expose it, create an external function in the implementation contract and call this.
  function _updateGatekeeper(address _gatekeeper) internal {
    require(_gatekeeper != address(0), "address is not valid");
    require(_gatekeeper != gatekeeper, "already the gatekeeper");
    gatekeeper = _gatekeeper;
    emit GatekeeperUpdated(_gatekeeper);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {StrategyInfo} from "../interfaces/IVault.sol";

/// @dev this contract is used to declare all the state variables that will be used by a Vault.
///  Because the vault itself is upgradeable, changes to state variables could cause data corruption.
///  The only safe operation is to add new fields, or rename an existing one (still not recommended to rename a field).
///  To avoid any issues, if a new field is needed, we should create a new version of the data store and extend the previous version,
///  rather than modifying the state variables directly.
// solhint-disable-next-line max-states-count
contract VaultDataStorage {
  // ### Vault base properties
  uint8 internal vaultDecimals;
  bool public emergencyShutdown;
  /// @notice timestamp for when the vault is deployed
  uint256 internal activation;
  uint256 public managementFee;
  /// @notice degradation for locked profit per second
  /// @dev the value is based on 6-hour degradation period (1/(60*60*6) = 0.000046)
  ///   NOTE: This is being deprecated by Yearn. See https://github.com/yearn/yearn-vaults/pull/471
  uint256 public lockedProfitDegradation;
  uint256 public depositLimit;
  /// @notice the timestamp of the last report received from a strategy
  uint256 internal lastReport;
  /// @notice how much profit is locked and cant be withdrawn
  uint256 public lockedProfit;
  /// @notice total value borrowed by all the strategies
  uint256 public totalDebt;

  address public rewards;
  address public healthCheck;
  address public strategyDataStore;
  address public accessManager;

  IERC20Upgradeable public token;
  mapping(address => StrategyInfo) internal strategies;

  uint256 internal constant DEGRADATION_COEFFICIENT = 10**18;
  address public vaultRewards;

  /// @dev set the default values for the state variables here
  // solhint-disable-next-line func-name-mixedcase
  function __VaultDataStorage_init() internal {
    vaultDecimals = 18;
    lockedProfitDegradation = (DEGRADATION_COEFFICIENT * 46) / 10**6;
    depositLimit = type(uint256).max;
    /* solhint-disable  not-rely-on-time */
    activation = block.timestamp;
    lastReport = block.timestamp;
    /* solhint-enable */
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
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
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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