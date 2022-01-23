// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/
pragma solidity 0.8.4;

import "../../openzeppelin/SafeERC20.sol";
import "../../openzeppelin/Math.sol";
import "../../openzeppelin/ReentrancyGuard.sol";
import "../governance/Controllable.sol";
import "../interface/IStrategy.sol";
import "../interface/ISmartVault.sol";
import "../interface/IStrategySplitter.sol";
import "./StrategySplitterStorage.sol";
import "../ArrayLib.sol";

/// @title Proxy solution for connection a vault with multiple strategies
/// @dev Should be used with TetuProxyControlled.sol
/// @author belbix
contract StrategySplitter is Controllable, IStrategy, StrategySplitterStorage, IStrategySplitter, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using ArrayLib for address[];

  // ************ VARIABLES **********************
  /// @notice Strategy type for statistical purposes
  string public constant override STRATEGY_NAME = "StrategySplitter";
  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant VERSION = "1.0.0";
  uint internal constant _PRECISION = 1e18;
  uint public constant STRATEGY_RATIO_DENOMINATOR = 100;
  uint public constant WITHDRAW_REQUEST_TIMEOUT = 1 hours;
  uint internal constant _MIN_OP = 1;

  address[] public override strategies;
  mapping(address => uint) public override strategiesRatios;
  mapping(address => uint) public override withdrawRequestsCalls;

  // ***************** EVENTS ********************
  event StrategyAdded(address strategy);
  event StrategyRemoved(address strategy);
  event StrategyRatioChanged(address strategy, uint ratio);
  event RequestWithdraw(address user, uint amount, uint time);
  event Salvage(address recipient, address token, uint256 amount);
  event RebalanceAll(uint underlyingBalance, uint strategiesBalancesSum);
  event Rebalance(address strategy);

  /// @notice Initialize contract after setup it as proxy implementation
  /// @dev Use it only once after first logic setup
  ///      Initialize Controllable with sender address
  function initialize(
    address _controller,
    address _underlying,
    address __vault
  ) external initializer {
    Controllable.initializeControllable(_controller);
    _setUnderlying(_underlying);
    _setVault(__vault);
  }

  // ******************** MODIFIERS ****************************

  /// @dev Only for linked Vault or Governance/Controller.
  ///      Use for functions that should have strict access.
  modifier restricted() {
    require(msg.sender == _vault()
    || msg.sender == address(controller())
      || isGovernance(msg.sender),
      "SS: Not Gov or Vault");
    _;
  }

  /// @dev Extended strict access with including HardWorkers addresses
  ///      Use for functions that should be called by HardWorkers
  modifier hardWorkers() {
    require(msg.sender == _vault()
    || msg.sender == address(controller())
    || IController(controller()).isHardWorker(msg.sender)
      || isGovernance(msg.sender),
      "SS: Not HW or Gov or Vault");
    _;
  }

  // ******************** SPLITTER SPECIFIC LOGIC ****************************

  /// @dev Add new managed strategy. Should be an uniq address.
  ///      Strategy should have the same underlying with current contract.
  ///      The new strategy will have zero rate. Need to setup correct rate later.
  function addStrategy(address _strategy) external override onlyController {
    _addStrategy(_strategy);
  }

  function _addStrategy(address _strategy) internal {
    require(IStrategy(_strategy).underlying() == _underlying(), "SS: Wrong underlying");
    strategies.addUnique(_strategy);
    emit StrategyAdded(_strategy);
  }

  /// @dev Remove given strategy, reset the ratio and withdraw all underlying to this contract
  function removeStrategy(address _strategy) external override onlyControllerOrGovernance {
    require(strategies.length > 1, "SS: Can't remove last strategy");
    strategies.findAndRemove(_strategy, true);
    uint ratio = strategiesRatios[_strategy];
    strategiesRatios[_strategy] = 0;
    if (ratio != 0) {
      address strategyWithHighestRatio = strategies[0];
      strategiesRatios[strategyWithHighestRatio] = ratio + strategiesRatios[strategyWithHighestRatio];
      strategies.sortAddressesByUintReverted(strategiesRatios);
    }
    IERC20(_underlying()).safeApprove(_strategy, 0);
    // for expensive strategies should be called before removing
    IStrategy(_strategy).withdrawAllToVault();
    emit StrategyRemoved(_strategy);
  }

  function setStrategyRatios(address[] memory _strategies, uint[] memory _ratios) external override hardWorkers {
    require(_strategies.length == strategies.length, "SS: Wrong input strategies");
    require(_strategies.length == _ratios.length, "SS: Wrong input arrays");
    uint sum;
    for (uint i; i < _strategies.length; i++) {
      bool exist = false;
      for (uint j; j < strategies.length; j++) {
        if (strategies[j] == _strategies[i]) {
          exist = true;
          break;
        }
      }
      require(exist, "SS: Strategy not exist");
      sum += _ratios[i];
      strategiesRatios[_strategies[i]] = _ratios[i];
      emit StrategyRatioChanged(_strategies[i], _ratios[i]);
    }
    require(sum == STRATEGY_RATIO_DENOMINATOR, "SS: Wrong sum");

    // sorting strategies by ratios
    strategies.sortAddressesByUintReverted(strategiesRatios);
  }

  /// @dev It is a little trick how to determinate was strategy fully initialized or not.
  ///      When we add strategies we don't setup ratios immediately.
  ///      Strategy ratios if setup once the sum must be equal to denominator.
  ///      It means zero sum of ratios will indicate that this contract was never initialized.
  ///      Until we setup ratios we able to add strategies without time-lock.
  function strategiesInited() external view override returns (bool) {
    uint sum;
    for (uint i; i < strategies.length; i++) {
      sum = strategiesRatios[strategies[i]];
    }
    return sum == STRATEGY_RATIO_DENOMINATOR;
  }

  // *************** STRATEGY GOVERNANCE ACTIONS **************

  /// @dev Try to withdraw all from all strategies. May be too expensive to handle in one tx
  function withdrawAllToVault() external override hardWorkers {
    for (uint i = 0; i < strategies.length; i++) {
      IStrategy(strategies[i]).withdrawAllToVault();
    }
    transferAllUnderlyingToVault();
  }

  /// @dev We can't call emergency exit on strategies
  ///      Transfer all available tokens to the vault
  function emergencyExit() external override restricted {
    transferAllUnderlyingToVault();
    _setOnPause(1);
  }

  /// @dev Cascade withdraw from strategies start from with higher ratio until reach the target amount.
  ///      For large amounts with multiple strategies may not be possible to process this function.
  function withdrawToVault(uint256 amount) external override hardWorkers {
    uint uBalance = IERC20(_underlying()).balanceOf(address(this));
    if (uBalance < amount) {
      for (uint i; i < strategies.length; i++) {
        IStrategy strategy = IStrategy(strategies[i]);
        uint strategyBalance = strategy.investedUnderlyingBalance();
        if (strategyBalance <= amount) {
          strategy.withdrawAllToVault();
        } else {
          if (amount > _MIN_OP) {
            strategy.withdrawToVault(amount);
          }
        }
        uBalance = IERC20(_underlying()).balanceOf(address(this));
        if (uBalance >= amount) {
          break;
        }
      }
    }
    transferAllUnderlyingToVault();
  }

  /// @dev User may indicate that he wants to withdraw given amount
  ///      We will try to transfer given amount to this contract in a separate transaction
  function requestWithdraw(uint _amount) external nonReentrant {
    uint lastRequest = withdrawRequestsCalls[msg.sender];
    if (lastRequest != 0) {
      // anti-spam protection
      require(lastRequest + WITHDRAW_REQUEST_TIMEOUT < block.timestamp, "SS: Request timeout");
    }
    uint userBalance = ISmartVault(_vault()).underlyingBalanceWithInvestmentForHolder(msg.sender);
    // add 10 for avoid rounding troubles
    require(_amount <= userBalance + 10, "SS: You want too much");
    uint want = _wantToWithdraw() + _amount;
    // add 10 for avoid rounding troubles
    require(want <= _investedUnderlyingBalance() + 10, "SS: Want more than balance");
    _setWantToWithdraw(want);

    withdrawRequestsCalls[msg.sender] = block.timestamp;
    emit RequestWithdraw(msg.sender, _amount, block.timestamp);
  }

  /// @dev User can try to withdraw requested amount from the first eligible strategy.
  ///      In case of big request should be called multiple time
  function processWithdrawRequests() external nonReentrant {
    uint balance = IERC20(_underlying()).balanceOf(address(this));
    uint want = _wantToWithdraw();
    if (balance >= want) {
      // already have enough balance
      _setWantToWithdraw(0);
      return;
    }
    // we should not want to withdraw more than we have
    // _investedUnderlyingBalance always higher than balance
    uint wantAdjusted = Math.min(want, _investedUnderlyingBalance()) - balance;
    for (uint i; i < strategies.length; i++) {
      IStrategy _strategy = IStrategy(strategies[i]);
      uint strategyBalance = _strategy.investedUnderlyingBalance();
      if (strategyBalance == 0) {
        // suppose we withdrew all in previous calls
        continue;
      }
      if (strategyBalance > wantAdjusted) {
        if (wantAdjusted > _MIN_OP) {
          _strategy.withdrawToVault(wantAdjusted);
        }
      } else {
        // we don't have enough amount in this strategy
        // withdraw all and call this function again
        _strategy.withdrawAllToVault();
      }
      // withdraw only from 1 eligible strategy
      break;
    }

    // update want to withdraw
    if (IERC20(_underlying()).balanceOf(address(this)) >= want) {
      _setWantToWithdraw(0);
    }
  }

  /// @dev Transfer token to recipient if it is not in forbidden list
  function salvage(address recipient, address token, uint256 amount) external override onlyController {
    require(token != _underlying(), "SS: Not salvageable");
    // To make sure that governance cannot come in and take away the coins
    for (uint i = 0; i < strategies.length; i++) {
      require(!IStrategy(strategies[i]).unsalvageableTokens(token), "SS: Not salvageable");
    }
    IERC20(token).safeTransfer(recipient, amount);
    emit Salvage(recipient, token, amount);
  }

  /// @dev Expensive call, probably will need to call each strategy in separated txs
  function doHardWork() external override hardWorkers {
    for (uint i = 0; i < strategies.length; i++) {
      IStrategy(strategies[i]).doHardWork();
    }
  }

  /// @dev Don't invest for keeping tx cost cheap
  ///      Need to call rebalance after this
  function investAllUnderlying() external override hardWorkers {
    _setNeedRebalance(1);
  }

  /// @dev Rebalance all strategies in one tx
  ///      Require a lot of gas and should be used carefully
  ///      In case of huge gas cost use rebalance for each strategy separately
  function rebalanceAll() external hardWorkers {
    require(_onPause() == 0, "SS: Paused");
    _setNeedRebalance(0);
    // collect balances sum
    uint _underlyingBalance = IERC20(_underlying()).balanceOf(address(this));
    uint _strategiesBalancesSum = _underlyingBalance;
    for (uint i = 0; i < strategies.length; i++) {
      _strategiesBalancesSum += IStrategy(strategies[i]).investedUnderlyingBalance();
    }
    if (_strategiesBalancesSum == 0) {
      return;
    }
    // rebalance only strategies requires withdraw
    // it will move necessary amount to this contract
    for (uint i = 0; i < strategies.length; i++) {
      uint _ratio = strategiesRatios[strategies[i]] * _PRECISION;
      if (_ratio == 0) {
        continue;
      }
      uint _strategyBalance = IStrategy(strategies[i]).investedUnderlyingBalance();
      uint _currentRatio = _strategyBalance * _PRECISION * STRATEGY_RATIO_DENOMINATOR / _strategiesBalancesSum;
      if (_currentRatio > _ratio) {
        // not necessary update underlying balance for withdraw
        _rebalanceCall(strategies[i], _strategiesBalancesSum, _strategyBalance, _ratio);
      }
    }

    // rebalance only strategies requires deposit
    for (uint i = 0; i < strategies.length; i++) {
      uint _ratio = strategiesRatios[strategies[i]] * _PRECISION;
      if (_ratio == 0) {
        continue;
      }
      uint _strategyBalance = IStrategy(strategies[i]).investedUnderlyingBalance();
      uint _currentRatio = _strategyBalance * _PRECISION * STRATEGY_RATIO_DENOMINATOR / _strategiesBalancesSum;
      if (_currentRatio < _ratio) {
        _rebalanceCall(
          strategies[i],
          _strategiesBalancesSum,
          _strategyBalance,
          _ratio
        );
      }
    }
    emit RebalanceAll(_underlyingBalance, _strategiesBalancesSum);
  }

  /// @dev External function for calling rebalance for exact strategy
  ///      Strategies that need withdraw action should be called first
  function rebalance(address _strategy) external hardWorkers {
    require(_onPause() == 0, "SS: Paused");
    _setNeedRebalance(0);
    _rebalance(_strategy);
    emit Rebalance(_strategy);
  }

  /// @dev Deposit or withdraw from given strategy according the strategy ratio
  ///      Should be called from EAO with multiple off-chain steps
  function _rebalance(address _strategy) internal {
    // normalize ratio to 18 decimals
    uint _ratio = strategiesRatios[_strategy] * _PRECISION;
    // in case of unknown strategy will be reverted here
    require(_ratio != 0, "SS: Zero ratio strategy");
    uint _strategyBalance;
    uint _strategiesBalancesSum = IERC20(_underlying()).balanceOf(address(this));
    // collect strategies balances sum with some tricks for gas optimisation
    for (uint i = 0; i < strategies.length; i++) {
      uint balance = IStrategy(strategies[i]).investedUnderlyingBalance();
      if (strategies[i] == _strategy) {
        _strategyBalance = balance;
      }
      _strategiesBalancesSum += balance;
    }

    _rebalanceCall(_strategy, _strategiesBalancesSum, _strategyBalance, _ratio);
  }

  ///@dev Deposit or withdraw from strategy
  function _rebalanceCall(
    address _strategy,
    uint _strategiesBalancesSum,
    uint _strategyBalance,
    uint _ratio
  ) internal {
    uint _currentRatio = _strategyBalance * _PRECISION * STRATEGY_RATIO_DENOMINATOR / _strategiesBalancesSum;
    if (_currentRatio < _ratio) {
      // Need to deposit to the strategy.
      // We are calling investAllUnderlying() because we anyway will spend similar gas
      // in case of withdraw, and we can't predict what will need.
      uint needToDeposit = _strategiesBalancesSum * (_ratio - _currentRatio) / (STRATEGY_RATIO_DENOMINATOR * _PRECISION);
      uint _underlyingBalance = IERC20(_underlying()).balanceOf(address(this));
      needToDeposit = Math.min(needToDeposit, _underlyingBalance);
      //      require(_underlyingBalance >= needToDeposit, "SS: Not enough splitter balance");
      if (needToDeposit > _MIN_OP) {
        IERC20(_underlying()).safeTransfer(_strategy, needToDeposit);
        IStrategy(_strategy).investAllUnderlying();
      }
    } else if (_currentRatio > _ratio) {
      // withdraw from strategy excess value
      uint needToWithdraw = _strategiesBalancesSum * (_currentRatio - _ratio) / (STRATEGY_RATIO_DENOMINATOR * _PRECISION);
      needToWithdraw = Math.min(needToWithdraw, _strategyBalance);
      //      require(_strategyBalance >= needToWithdraw, "SS: Not enough strat balance");
      if (needToWithdraw > _MIN_OP) {
        IStrategy(_strategy).withdrawToVault(needToWithdraw);
      }
    }
  }

  /// @dev Change rebalance marker
  function setNeedRebalance(uint _value) external hardWorkers {
    require(_value < 2, "SS: Wrong value");
    _setNeedRebalance(_value);
  }

  /// @dev Stop deposit to strategies
  function pauseInvesting() external override restricted {
    _setOnPause(1);
  }

  /// @dev Continue deposit to strategies
  function continueInvesting() external override restricted {
    _setOnPause(0);
  }

  function transferAllUnderlyingToVault() internal {
    uint balance = IERC20(_underlying()).balanceOf(address(this));
    if (balance > 0) {
      IERC20(_underlying()).safeTransfer(_vault(), balance);
    }
  }

  // **************** VIEWS ***************

  /// @dev Return array of reward tokens collected across all strategies.
  ///      Has random sorting
  function strategyRewardTokens() external view override returns (address[] memory) {
    return _strategyRewardTokens();
  }

  function _strategyRewardTokens() internal view returns (address[] memory) {
    address[] memory rts = new address[](20);
    uint size = 0;
    for (uint i = 0; i < strategies.length; i++) {
      address[] memory strategyRts;
      if (IStrategy(strategies[i]).platform() == IStrategy.Platform.STRATEGY_SPLITTER) {
        strategyRts = IStrategySplitter(strategies[i]).strategyRewardTokens();
      } else {
        strategyRts = IStrategy(strategies[i]).rewardTokens();
      }
      for (uint j = 0; j < strategyRts.length; j++) {
        address rt = strategyRts[j];
        bool exist = false;
        for (uint k = 0; k < rts.length; k++) {
          if (rts[k] == rt) {
            exist = true;
            break;
          }
        }
        if (!exist) {
          rts[size] = rt;
          size++;
        }
      }
    }
    address[] memory result = new address[](size);
    for (uint i = 0; i < size; i++) {
      result[i] = rts[i];
    }
    return result;
  }

  /// @dev Underlying token. Should be the same for all controlled strategies
  function underlying() external view override returns (address) {
    return _underlying();
  }

  /// @dev Splitter underlying balance
  function underlyingBalance() external view override returns (uint256){
    return IERC20(_underlying()).balanceOf(address(this));
  }

  /// @dev Return strategies balances. Doesn't include splitter underlying balance
  function rewardPoolBalance() external view override returns (uint256) {
    uint balance;
    for (uint i = 0; i < strategies.length; i++) {
      balance += IStrategy(strategies[i]).investedUnderlyingBalance();
    }
    return balance;
  }

  /// @dev Return average buyback ratio
  function buyBackRatio() external view override returns (uint256) {
    uint bbRatio = 0;
    for (uint i = 0; i < strategies.length; i++) {
      bbRatio += IStrategy(strategies[i]).buyBackRatio();
    }
    bbRatio = bbRatio / strategies.length;
    return bbRatio;
  }

  /// @dev Check unsalvageable tokens across all strategies
  function unsalvageableTokens(address token) external view override returns (bool) {
    for (uint i = 0; i < strategies.length; i++) {
      if (IStrategy(strategies[i]).unsalvageableTokens(token)) {
        return true;
      }
    }
    return false;
  }

  /// @dev Connected vault to this splitter
  function vault() external view override returns (address) {
    return _vault();
  }

  /// @dev Return a sum of all balances under control. Should be accurate - it will be used in the vault
  function investedUnderlyingBalance() external view override returns (uint256) {
    return _investedUnderlyingBalance();
  }

  function _investedUnderlyingBalance() internal view returns (uint256) {
    uint balance = IERC20(_underlying()).balanceOf(address(this));
    for (uint i = 0; i < strategies.length; i++) {
      balance += IStrategy(strategies[i]).investedUnderlyingBalance();
    }
    return balance;
  }

  /// @dev Splitter has specific hardcoded platform
  function platform() external pure override returns (Platform) {
    return Platform.STRATEGY_SPLITTER;
  }

  /// @dev Assume that we will use this contract only for single token vaults
  function assets() external view override returns (address[] memory) {
    address[] memory result = new address[](1);
    result[0] = _underlying();
    return result;
  }

  /// @dev Paused investing in strategies
  function pausedInvesting() external view override returns (bool) {
    return _onPause() == 1;
  }

  /// @dev Return ready to claim rewards array
  function readyToClaim() external view override returns (uint256[] memory) {
    uint[] memory rewards = new uint[](20);
    address[] memory rts = new address[](20);
    uint size = 0;
    for (uint i = 0; i < strategies.length; i++) {
      address[] memory strategyRts;
      if (IStrategy(strategies[i]).platform() == IStrategy.Platform.STRATEGY_SPLITTER) {
        strategyRts = IStrategySplitter(strategies[i]).strategyRewardTokens();
      } else {
        strategyRts = IStrategy(strategies[i]).rewardTokens();
      }

      uint[] memory strategyReadyToClaim = IStrategy(strategies[i]).readyToClaim();
      // don't count, better to skip than ruin
      if (strategyRts.length != strategyReadyToClaim.length) {
        continue;
      }
      for (uint j = 0; j < strategyRts.length; j++) {
        address rt = strategyRts[j];
        bool exist = false;
        for (uint k = 0; k < rts.length; k++) {
          if (rts[k] == rt) {
            exist = true;
            rewards[k] += strategyReadyToClaim[j];
            break;
          }
        }
        if (!exist) {
          rts[size] = rt;
          rewards[size] = strategyReadyToClaim[j];
          size++;
        }
      }
    }
    uint[] memory result = new uint[](size);
    for (uint i = 0; i < size; i++) {
      result[i] = rewards[i];
    }
    return result;
  }

  /// @dev Return sum of strategies poolTotalAmount values
  function poolTotalAmount() external view override returns (uint256) {
    uint balance = 0;
    for (uint i = 0; i < strategies.length; i++) {
      balance += IStrategy(strategies[i]).poolTotalAmount();
    }
    return balance;
  }

  /// @dev Positive value indicate that this splitter should be rebalanced.
  function needRebalance() external view override returns (uint) {
    return _needRebalance();
  }

  /// @dev Sum of users requested values
  function wantToWithdraw() external view override returns (uint) {
    return _wantToWithdraw();
  }

  /// @dev Return maximum available balance to withdraw without calling more than 1 strategy
  function maxCheapWithdraw() external view override returns (uint) {
    uint strategyBalance;
    if (strategies.length != 0) {
      if (IStrategy(strategies[0]).platform() == IStrategy.Platform.STRATEGY_SPLITTER) {
        strategyBalance = IStrategySplitter(strategies[0]).maxCheapWithdraw();
      } else {
        strategyBalance = IStrategy(strategies[0]).investedUnderlyingBalance();
      }
    }
    return strategyBalance
    + IERC20(_underlying()).balanceOf(address(this))
    + IERC20(_underlying()).balanceOf(_vault());
  }

  /// @dev Length of strategy array
  function strategiesLength() external view override returns (uint) {
    return strategies.length;
  }

  /// @dev Returns strategy array
  function allStrategies() external view override returns (address[] memory) {
    return strategies;
  }

  // **********************************************
  // *********** VAULT FUNCTIONS ******************
  // ****** Simulate vault behaviour **************
  // **********************************************

  /// @dev Transfer tokens from sender and call the vault notify function.
  function notifyTargetRewardAmount(address _rewardToken, uint _amount) external {
    require(IController(controller()).isRewardDistributor(msg.sender), "SS: Only distributor");
    IERC20(_rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
    IERC20(_rewardToken).safeApprove(_vault(), 0);
    IERC20(_rewardToken).safeApprove(_vault(), _amount);
    return ISmartVault(_vault()).notifyTargetRewardAmount(_rewardToken, _amount);
  }

  /// @dev Simulate vault behaviour - returns PPFS for of the vault
  function getPricePerFullShare() external view returns (uint256) {
    return ISmartVault(_vault()).getPricePerFullShare();
  }

  /// @dev Simulate vault behaviour - returns vault underlying uint
  function underlyingUnit() external view returns (uint256) {
    return ISmartVault(_vault()).underlyingUnit();
  }

  /// @dev Simulate vault behaviour - returns vault total supply
  function totalSupply() external view returns (uint256) {
    return IERC20(_vault()).totalSupply();
  }

  /// @dev !!! THIS FUNCTION HAS CONFLICT WITH STRATEGY INTERFACE !!!
  ///      We are implementing vault functionality. Don't use strategy rewardTokens() anywhere
  function rewardTokens() external view override returns (address[] memory) {
    return ISmartVault(_vault()).rewardTokens();
  }

  /// @dev Simulate vault behaviour - returns the whole balance of the vault
  function underlyingBalanceWithInvestment() external view returns (uint256) {
    return ISmartVault(_vault()).underlyingBalanceWithInvestment();
  }

  /// @dev Simulate vault behaviour - returns the whole user balance in underlying units
  function underlyingBalanceWithInvestmentForHolder(address holder)
  external view returns (uint256) {
    return ISmartVault(_vault()).underlyingBalanceWithInvestmentForHolder(holder);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

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

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/IController.sol";
import "../interface/IControllable.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call initializeControllable() in any case.
/// @author belbix
abstract contract Controllable is Initializable, IControllable {
  bytes32 internal constant _CONTROLLER_SLOT = 0x5165972ef41194f06c5007493031d0b927c20741adcb74403b954009fd2c3617;
  bytes32 internal constant _CREATED_SLOT = 0x6f55f470bdc9cb5f04223fd822021061668e4dccb43e8727b295106dc9769c8a;

  /// @notice Controller address changed
  event UpdateController(address oldValue, address newValue);

  constructor() {
    assert(_CONTROLLER_SLOT == bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1));
    assert(_CREATED_SLOT == bytes32(uint256(keccak256("eip1967.controllable.created")) - 1));
  }

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param _controller Controller address
  function initializeControllable(address _controller) public initializer {
    setController(_controller);
    setCreated(block.timestamp);
  }

  function isController(address _adr) public override view returns (bool) {
    return _adr == controller();
  }

  /// @notice Return true is given address is setup as governance in Controller
  /// @param _adr Address for check
  /// @return true if given address is governance
  function isGovernance(address _adr) public override view returns (bool) {
    return IController(controller()).governance() == _adr;
  }

  // ************ MODIFIERS **********************

  /// @dev Allow operation only for Controller
  modifier onlyController() {
    require(controller() == msg.sender, "not controller");
    _;
  }

  /// @dev Allow operation only for Controller or Governance
  modifier onlyControllerOrGovernance() {
    require(isController(msg.sender) || isGovernance(msg.sender), "not controller or gov");
    _;
  }

  /// @dev Only smart contracts will be affected by this modifier
  ///      If it is a contract it should be whitelisted
  modifier onlyAllowedUsers() {
    require(IController(controller()).isAllowedUser(msg.sender), "not allowed");
    _;
  }

  /// @dev Only Reward Distributor allowed. Governance is Reward Distributor by default.
  modifier onlyRewardDistribution() {
    require(IController(controller()).isRewardDistributor(msg.sender), "only distr");
    _;
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  /// @return adr Controller address
  function controller() public view returns (address adr) {
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      adr := sload(slot)
    }
  }

  /// @dev Set a controller address to contract slot
  /// @param _newController Controller address
  function setController(address _newController) internal {
    require(_newController != address(0), "zero address");
    emit UpdateController(controller(), _newController);
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      sstore(slot, _newController)
    }
  }

  /// @notice Return creation timestamp
  /// @return ts Creation timestamp
  function created() external view returns (uint256 ts) {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      ts := sload(slot)
    }
  }

  /// @dev Filled only once when contract initialized
  /// @param _created block.timestamp
  function setCreated(uint256 _created) private {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      sstore(slot, _created)
    }
  }

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IStrategy {

  enum Platform {
    UNKNOWN, // 0
    TETU, // 1
    QUICK, // 2
    SUSHI, // 3
    WAULT, // 4
    IRON, // 5
    COSMIC, // 6
    CURVE, // 7
    DINO, // 8
    IRON_LEND, // 9
    HERMES, // 10
    CAFE, // 11
    TETU_SWAP, // 12
    SPOOKY, // 13
    AAVE_LEND, //14
    AAVE_MAI_BAL, // 15
    GEIST, //16
    HARVEST, //17
    SCREAM_LEND, //18
    KLIMA, //19
    VESQ, //20
    QIDAO, //21
    SUNFLOWER, //22
    NACHO, //23
    STRATEGY_SPLITTER, //24
    TOMB, //25
    TAROT //26
  }

  // *************** GOVERNANCE ACTIONS **************
  function STRATEGY_NAME() external view returns (string memory);

  function withdrawAllToVault() external;

  function withdrawToVault(uint256 amount) external;

  function salvage(address recipient, address token, uint256 amount) external;

  function doHardWork() external;

  function investAllUnderlying() external;

  function emergencyExit() external;

  function pauseInvesting() external;

  function continueInvesting() external;

  // **************** VIEWS ***************
  function rewardTokens() external view returns (address[] memory);

  function underlying() external view returns (address);

  function underlyingBalance() external view returns (uint256);

  function rewardPoolBalance() external view returns (uint256);

  function buyBackRatio() external view returns (uint256);

  function unsalvageableTokens(address token) external view returns (bool);

  function vault() external view returns (address);

  function investedUnderlyingBalance() external view returns (uint256);

  function platform() external view returns (Platform);

  function assets() external view returns (address[] memory);

  function pausedInvesting() external view returns (bool);

  function readyToClaim() external view returns (uint256[] memory);

  function poolTotalAmount() external view returns (uint256);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface ISmartVault {

  function setStrategy(address _strategy) external;

  function changeActivityStatus(bool _active) external;

  function changeProtectionMode(bool _active) external;

  function changePpfsDecreaseAllowed(bool _value) external;

  function setLockPeriod(uint256 _value) external;

  function setLockPenalty(uint256 _value) external;

  function setToInvest(uint256 _value) external;

  function doHardWork() external;

  function rebalance() external;

  function disableLock() external;

  function notifyTargetRewardAmount(address _rewardToken, uint256 reward) external;

  function notifyRewardWithoutPeriodChange(address _rewardToken, uint256 reward) external;

  function deposit(uint256 amount) external;

  function depositAndInvest(uint256 amount) external;

  function depositFor(uint256 amount, address holder) external;

  function withdraw(uint256 numberOfShares) external;

  function exit() external;

  function getAllRewards() external;

  function getReward(address rt) external;

  function underlying() external view returns (address);

  function strategy() external view returns (address);

  function getRewardTokenIndex(address rt) external view returns (uint256);

  function getPricePerFullShare() external view returns (uint256);

  function underlyingUnit() external view returns (uint256);

  function duration() external view returns (uint256);

  function underlyingBalanceInVault() external view returns (uint256);

  function underlyingBalanceWithInvestment() external view returns (uint256);

  function underlyingBalanceWithInvestmentForHolder(address holder) external view returns (uint256);

  function availableToInvestOut() external view returns (uint256);

  function earned(address rt, address account) external view returns (uint256);

  function earnedWithBoost(address rt, address account) external view returns (uint256);

  function rewardPerToken(address rt) external view returns (uint256);

  function lastTimeRewardApplicable(address rt) external view returns (uint256);

  function rewardTokensLength() external view returns (uint256);

  function active() external view returns (bool);

  function rewardTokens() external view returns (address[] memory);

  function periodFinishForToken(address _rt) external view returns (uint256);

  function rewardRateForToken(address _rt) external view returns (uint256);

  function lastUpdateTimeForToken(address _rt) external view returns (uint256);

  function rewardPerTokenStoredForToken(address _rt) external view returns (uint256);

  function userRewardPerTokenPaidForToken(address _rt, address account) external view returns (uint256);

  function rewardsForToken(address _rt, address account) external view returns (uint256);

  function userLastWithdrawTs(address _user) external view returns (uint256);

  function userLastDepositTs(address _user) external view returns (uint256);

  function userBoostTs(address _user) external view returns (uint256);

  function userLockTs(address _user) external view returns (uint256);

  function addRewardToken(address rt) external;

  function removeRewardToken(address rt) external;

  function stop() external;

  function ppfsDecreaseAllowed() external view returns (bool);

  function lockPeriod() external view returns (uint256);

  function lockPenalty() external view returns (uint256);

  function toInvest() external view returns (uint256);

  function depositFeeNumerator() external view returns (uint256);

  function lockAllowed() external view returns (bool);

  function protectionMode() external view returns (bool);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IStrategySplitter {

  function strategies(uint idx) external view returns (address);

  function strategiesRatios(address strategy) external view returns (uint);

  function withdrawRequestsCalls(address user) external view returns (uint);

  function addStrategy(address _strategy) external;

  function removeStrategy(address _strategy) external;

  function setStrategyRatios(address[] memory _strategies, uint[] memory _ratios) external;

  function strategiesInited() external view returns (bool);

  function needRebalance() external view returns (uint);

  function wantToWithdraw() external view returns (uint);

  function maxCheapWithdraw() external view returns (uint);

  function strategiesLength() external view returns (uint);

  function allStrategies() external view returns (address[] memory);

  function strategyRewardTokens() external view returns (address[] memory);

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title Eternal storage + getters and setters pattern
/// @dev If you will change a key value it will require setup it again
/// @author belbix
abstract contract StrategySplitterStorage is Initializable {

  // don't change names or ordering!
  mapping(bytes32 => uint256) private uintStorage;
  mapping(bytes32 => address) private addressStorage;

  /// @notice Address changed the variable with `name`
  event UpdatedAddressSlot(string name, address oldValue, address newValue);
  /// @notice Value changed the variable with `name`
  event UpdatedUint256Slot(string name, uint256 oldValue, uint256 newValue);

  // ******************* SETTERS AND GETTERS **********************

  function _setUnderlying(address _address) internal {
    emit UpdatedAddressSlot("underlying", _underlying(), _address);
    setAddress("underlying", _address);
  }

  function _underlying() internal view returns (address) {
    return getAddress("underlying");
  }

  function _setVault(address _address) internal {
    emit UpdatedAddressSlot("vault", _vault(), _address);
    setAddress("vault", _address);
  }

  function _vault() internal view returns (address) {
    return getAddress("vault");
  }

  function _strategiesRatioSum() internal view returns (uint) {
    return getUint256("rSum");
  }

  function _setNeedRebalance(uint _value) internal {
    emit UpdatedUint256Slot("needRebalance", _needRebalance(), _value);
    setUint256("needRebalance", _value);
  }

  function _needRebalance() internal view returns (uint) {
    return getUint256("needRebalance");
  }

  function _setWantToWithdraw(uint _value) internal {
    emit UpdatedUint256Slot("wantToWithdraw", _wantToWithdraw(), _value);
    setUint256("wantToWithdraw", _value);
  }

  function _wantToWithdraw() internal view returns (uint) {
    return getUint256("wantToWithdraw");
  }

  function _setOnPause(uint _value) internal {
    emit UpdatedUint256Slot("onPause", _onPause(), _value);
    setUint256("onPause", _value);
  }

  function _onPause() internal view returns (uint) {
    return getUint256("onPause");
  }

  // ******************** STORAGE INTERNAL FUNCTIONS ********************

  function setAddress(string memory key, address _address) private {
    addressStorage[keccak256(abi.encodePacked(key))] = _address;
  }

  function getAddress(string memory key) private view returns (address) {
    return addressStorage[keccak256(abi.encodePacked(key))];
  }

  function setUint256(string memory key, uint256 _value) private {
    uintStorage[keccak256(abi.encodePacked(key))] = _value;
  }

  function getUint256(string memory key) private view returns (uint256) {
    return uintStorage[keccak256(abi.encodePacked(key))];
  }

  //slither-disable-next-line unused-state
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

/// @title Library for useful functions for address and uin256 arrays
/// @author bogdoslav, belbix
library ArrayLib {

  string constant INDEX_OUT_OF_BOUND = "ArrayLib: Index out of bounds";
  string constant NOT_UNIQUE_ITEM = "ArrayLib: Not unique item";
  string constant ITEM_NOT_FOUND = "ArrayLib: Item not found";

  /// @dev Return true if given item found in address array
  function contains(address[] storage array, address _item) internal view returns (bool) {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == _item) return true;
    }
    return false;
  }

  /// @dev Return true if given item found in uin256 array
  function contains(uint256[] storage array, uint256 _item) internal view returns (bool) {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == _item) return true;
    }
    return false;
  }

  // -----------------------------------

  /// @dev If token not exist in the array push it, otherwise throw an error
  function addUnique(address[] storage array, address _item) internal {
    require(!contains(array, _item), NOT_UNIQUE_ITEM);
    array.push(_item);
  }

  /// @dev If token not exist in the array push it, otherwise throw an error
  function addUnique(uint256[] storage array, uint256 _item) internal {
    require(!contains(array, _item), NOT_UNIQUE_ITEM);
    array.push(_item);
  }

  // -----------------------------------

  /// @dev Call addUnique for the given items array
  function addUniqueArray(address[] storage array, address[] memory _items) internal {
    for (uint256 i = 0; i < _items.length; i++) {
      addUnique(array, _items[i]);
    }
  }

  /// @dev Call addUnique for the given items array
  function addUniqueArray(uint256[] storage array, uint256[] memory _items) internal {
    for (uint i = 0; i < _items.length; i++) {
      addUnique(array, _items[i]);
    }
  }

  // -----------------------------------

  /// @dev Remove an item by given index.
  /// @param keepSorting If true the function will shift elements to the place of removed item
  ///                    If false will move the last element on the place of removed item
  function removeByIndex(address[] storage array, uint256 index, bool keepSorting) internal {
    require(index < array.length, INDEX_OUT_OF_BOUND);

    if (keepSorting) {
      // shift all elements to the place of removed item
      // the loop must not include the last element
      for (uint256 i = index; i < array.length - 1; i++) {
        array[i] = array[i + 1];
      }
    } else {
      // copy the last address in the array
      array[index] = array[array.length - 1];
    }
    array.pop();
  }

  /// @dev Remove an item by given index.
  /// @param keepSorting If true the function will shift elements to the place of removed item
  ///                    If false will move the last element on the place of removed item
  function removeByIndex(uint256[] storage array, uint256 index, bool keepSorting) internal {
    require(index < array.length, INDEX_OUT_OF_BOUND);

    if (keepSorting) {
      // shift all elements to the place of removed item
      // the loop must not include the last element
      for (uint256 i = index; i < array.length - 1; i++) {
        array[i] = array[i + 1];
      }
    } else {
      // copy the last address in the array
      array[index] = array[array.length - 1];
    }
    array.pop();
  }

  // -----------------------------------

  /// @dev Find given item in the array and call removeByIndex function if exist. If not throw an error
  function findAndRemove(address[] storage array, address _item, bool keepSorting) internal {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == _item) {
        removeByIndex(array, i, keepSorting);
        return;
      }
    }
    revert(ITEM_NOT_FOUND);
  }

  /// @dev Find given item in the array and call removeByIndex function if exist. If not throw an error
  function findAndRemove(uint256[] storage array, uint256 _item, bool keepSorting) internal {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == _item) {
        removeByIndex(array, i, keepSorting);
        return;
      }
    }
    revert(ITEM_NOT_FOUND);
  }

  // -----------------------------------

  /// @dev Call findAndRemove function for given item array
  function findAndRemoveArray(address[] storage array, address[] memory _items, bool keepSorting) internal {
    for (uint256 i = 0; i < _items.length; i++) {
      findAndRemove(array, _items[i], keepSorting);
    }
  }

  /// @dev Call findAndRemove function for given item array
  function findAndRemoveArray(uint256[] storage array, uint256[] memory _items, bool keepSorting) internal {
    for (uint256 i = 0; i < _items.length; i++) {
      findAndRemove(array, _items[i], keepSorting);
    }
  }

  // -----------------------------------

  /// @dev Remove from array the item with given id and move the last item on it place
  ///      Use with mapping for keeping indexes in correct ordering
  function removeIndexed(
    uint256[] storage array,
    mapping(uint256 => uint256) storage indexes,
    uint256 id
  ) internal {
    uint256 lastId = array[array.length - 1];
    uint256 index = indexes[id];
    indexes[lastId] = index;
    indexes[id] = type(uint256).max;
    array[index] = lastId;
    array.pop();
  }

  // ************* SORTING *******************

  /// @dev Insertion sorting algorithm for using with arrays fewer than 10 elements
  ///      Based on https://medium.com/coinmonks/sorting-in-solidity-without-comparison-4eb47e04ff0d
  function sortAddressesByUint(address[] storage addressArray, mapping(address => uint) storage uintMap) internal {
    for (uint i = 1; i < addressArray.length; i++) {
      address key = addressArray[i];
      uint j = i - 1;
      while ((int(j) >= 0) && uintMap[addressArray[j]] > uintMap[key]) {
        addressArray[j + 1] = addressArray[j];
      unchecked {j--;}
      }
    unchecked {
      addressArray[j + 1] = key;
    }
    }
  }

  /// @dev Insertion sorting algorithm for using with arrays fewer than 10 elements
  ///      Based on https://medium.com/coinmonks/sorting-in-solidity-without-comparison-4eb47e04ff0d
  function sortAddressesByUintReverted(address[] storage addressArray, mapping(address => uint) storage uintMap) internal {
    for (uint i = 1; i < addressArray.length; i++) {
      address key = addressArray[i];
      uint j = i - 1;
      while ((int(j) >= 0) && uintMap[addressArray[j]] < uintMap[key]) {
        addressArray[j + 1] = addressArray[j];
      unchecked {j--;}
      }
    unchecked {
      addressArray[j + 1] = key;
    }
    }
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

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IController {

  function addVaultsAndStrategies(address[] memory _vaults, address[] memory _strategies) external;

  function addStrategy(address _strategy) external;

  function governance() external view returns (address);

  function dao() external view returns (address);

  function bookkeeper() external view returns (address);

  function feeRewardForwarder() external view returns (address);

  function mintHelper() external view returns (address);

  function rewardToken() external view returns (address);

  function fundToken() external view returns (address);

  function psVault() external view returns (address);

  function fund() external view returns (address);

  function distributor() external view returns (address);

  function announcer() external view returns (address);

  function vaultController() external view returns (address);

  function whiteList(address _target) external view returns (bool);

  function vaults(address _target) external view returns (bool);

  function strategies(address _target) external view returns (bool);

  function psNumerator() external view returns (uint256);

  function psDenominator() external view returns (uint256);

  function fundNumerator() external view returns (uint256);

  function fundDenominator() external view returns (uint256);

  function isAllowedUser(address _adr) external view returns (bool);

  function isDao(address _adr) external view returns (bool);

  function isHardWorker(address _adr) external view returns (bool);

  function isRewardDistributor(address _adr) external view returns (bool);

  function isPoorRewardConsumer(address _adr) external view returns (bool);

  function isValidVault(address _vault) external view returns (bool);

  function isValidStrategy(address _strategy) external view returns (bool);

  function rebalance(address _strategy) external;

  // ************ DAO ACTIONS *************
  function setPSNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function setFundNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function changeWhiteListStatus(address[] calldata _targets, bool status) external;
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

}