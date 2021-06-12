//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "../interface/IStrategy.sol";
import "../interface/ISmartVault.sol";
import "../interface/IController.sol";
import "../interface/IUpgradeSource.sol";
import "../interface/ISmartVault.sol";
import "./VaultStorage.sol";
import "../governance/Controllable.sol";

/**
Use number error codes for reducing the contract size:
100 - _toInvestNumerator is higher then _toInvestDenominator in initializeSmartVault
101 - _toInvestDenominator must not be zero
102 - strategy no defined
104 - only for addresses included in reward distribution
105 - the strategy exists and switch timelock did not elapse yet
106 - new strategy cannot be empty
107 - vault underlying must match Strategy underlying
108 - the strategy does not belong to this vault
109 - new denominator must be greater than 0
110 - new denominator must be greater than or equal to the numerator
111 - Reward token already exists
112 - Reward token does not exists
113 - Can only remove when the reward period has passed
114 - Cannot remove the last reward token
115 - the notified reward cannot invoke multiplication overflow
116 - rewardTokenIndex not found
117 - Vault has no shares
118 - numberOfShares must be greater than 0
119 - Cannot deposit 0
120 - holder must be defined
121 - Too much arb
122 - Share price should not decrease
123 - Vault deactivated
*/
contract SmartVault is Initializable, ERC20Upgradeable, VaultStorage, IUpgradeSource, Controllable {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeMathUpgradeable for uint256;

  // ************* CONSTANTS ********************
  string public constant VERSION = "0";

  // ********************* VARIABLES *****************
  //in upgradable contracts you can skip storage ONLY for mapping and dynamically-sized array types
  //https://docs.soliditylang.org/en/v0.4.21/miscellaneous.html#layout-of-state-variables-in-storage
  //use VaultStorage for primitive variables
  address[] public rewardTokens;
  mapping(address => uint256) public periodFinishForToken;
  mapping(address => uint256) public rewardRateForToken;
  mapping(address => uint256) public lastUpdateTimeForToken;
  mapping(address => uint256) public rewardPerTokenStoredForToken;
  mapping(address => mapping(address => uint256)) public userRewardPerTokenPaidForToken;
  mapping(address => mapping(address => uint256)) public rewardsForToken;

  function initializeSmartVault(
    string memory _name,
    string memory _symbol,
    address _controller,
    address _underlying,
    uint256 _toInvestNumerator,
    uint256 _toInvestDenominator,
    uint256 _duration
  ) public initializer {
    require(_toInvestNumerator <= _toInvestDenominator, "100");
    require(_toInvestDenominator != 0, "101");

    __ERC20_init(_name, _symbol);
    //    _setupDecimals(ERC20Upgradeable(_underlying).decimals());

    Controllable.initializeControllable(_controller);
    VaultStorage.initializeVaultStorage(
      _underlying,
      _toInvestNumerator,
      _toInvestDenominator,
      10 ** uint256(ERC20Upgradeable(address(_underlying)).decimals()),
      24 hours,
      24 hours,
      _duration
    );
  }

  // *************** EVENTS ***************************
  event Withdraw(address indexed beneficiary, uint256 amount);
  event Deposit(address indexed beneficiary, uint256 amount);
  event Invest(uint256 amount);
  event StrategyAnnounced(address newStrategy, uint256 time);
  event StrategyChanged(address newStrategy, address oldStrategy);
  event RewardAdded(address rewardToken, uint256 reward);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, address rewardToken, uint256 reward);
  event RewardDenied(address indexed user, address rewardToken, uint256 reward);
  event AddedRewardToken(address indexed token);
  event RemovedRewardToken(address indexed token);

  function decimals() public view override returns (uint8) {
    return ERC20Upgradeable(underlying()).decimals();
  }


  // *************** MODIFIERS ***************************

  /**
   *  Strategy should not be a zero address
   */
  modifier whenStrategyDefined() {
    require(address(strategy()) != address(0), "102");
    _;
  }

  modifier isActive() {
    require(active(), "123");
    _;
  }

  // ************ GOVERNANCE ACTIONS ******************

  /**
   * Change the active state marker
   */
  function changeActivityStatus(bool active) external onlyGovernance {
    _setActive(active);
  }

  /**
   * Chooses the best strategy and re-invests. If the strategy did not change, it just calls
   * doHardWork on the current strategy. Call this through controller to claim hard rewards.
   */
  function doHardWork() external whenStrategyDefined onlyControllerOrGovernance isActive override {
    uint256 sharePriceBeforeHardWork = getPricePerFullShare();
    if (withdrawBeforeReinvesting()) {
      IStrategy(strategy()).withdrawAllToVault();
    }
    // ensure that new funds are invested too
    invest();
    IStrategy(strategy()).doHardWork();
    if (!allowSharePriceDecrease()) {
      require(sharePriceBeforeHardWork <= getPricePerFullShare(), "122");
    }
  }

  /**
   * Change the vault fraction to invest
   */
  function setVaultFractionToInvest(uint256 numerator, uint256 denominator) external onlyGovernance {
    require(denominator > 0, "109");
    require(numerator <= denominator, "110");
    _setVaultFractionToInvestNumerator(numerator);
    _setVaultFractionToInvestDenominator(denominator);
    // we have an event in the vault storage
  }

  /**
   * A push mechanism for accounts that have not claimed their rewards for a long time.
   * The implementation is semantically analogous to getReward(), but uses a push pattern
   * instead of pull pattern.
   */
  function pushAllRewards(address recipient) public onlyGovernance {
    updateRewards(recipient);
    for (uint256 i = 0; i < rewardTokens.length; i++) {
      uint256 reward = earned(rewardTokens[i], recipient);
      if (reward > 0) {
        rewardsForToken[rewardTokens[i]][recipient] = 0;
        IERC20Upgradeable(rewardTokens[i]).safeTransfer(recipient, reward);
        emit RewardPaid(recipient, rewardTokens[i], reward);
      }
    }
  }

  /**
   * Add a reward token to the internal array
   */
  function addRewardToken(address rt) public onlyGovernance {
    require(getRewardTokenIndex(rt) == uint256(- 1), "111");
    rewardTokens.push(rt);
    emit AddedRewardToken(rt);
  }

  /**
   * Remove reward token. Last token removal is not allowed
   */
  function removeRewardToken(address rt) public onlyGovernance {
    uint256 i = getRewardTokenIndex(rt);
    require(i != uint256(- 1), "112");
    require(periodFinishForToken[rewardTokens[i]] < block.timestamp, "113");
    require(rewardTokens.length > 1, "114");
    uint256 lastIndex = rewardTokens.length - 1;
    // swap
    rewardTokens[i] = rewardTokens[lastIndex];
    // delete last element
    rewardTokens.pop();
    emit RemovedRewardToken(rt);
  }

  /**
   * Withdraw all from strategy to the vault and invest again
   */
  function rebalance() external onlyGovernance {
    withdrawAllToVault();
    invest();
  }

  /**
   * Withdraw all from strategy to the vault
   */
  function withdrawAllToVault() public onlyGovernance whenStrategyDefined {
    IStrategy(strategy()).withdrawAllToVault();
  }

  //****************** USER ACTIONS ********************

  /**
   * Allows for depositing the underlying asset in exchange for shares.
   * Approval is assumed.
   */
  function deposit(uint256 amount) external override onlyAllowedUsers isActive {
    _deposit(amount, msg.sender, msg.sender);
  }

  /**
   * Allows for depositing the underlying asset in exchange for shares.
   * Approval is assumed. Immediately invests the asset to the strategy
   */
  function depositAndInvest(uint256 amount) external onlyAllowedUsers isActive {
    _deposit(amount, msg.sender, msg.sender);
    invest();
  }

  /**
   * Allows for depositing the underlying asset in exchange for shares
   * assigned to the holder.
   * This facilitates depositing for someone else (using DepositHelper)
   */
  function depositFor(uint256 amount, address holder) public onlyAllowedUsers isActive {
    _deposit(amount, msg.sender, holder);
  }

  /**
   * Withdraw shares partially without touching rewards
   */
  function withdraw(uint256 numberOfShares) external onlyAllowedUsers {
    _withdraw(numberOfShares);
  }

  /**
   * Withdraw all and claim rewards
   */
  function exit() external onlyAllowedUsers {
    _withdraw(balanceOf(msg.sender));
    getAllRewards();
  }

  /**
   * Update and Claim all rewards
   */
  function getAllRewards() public onlyAllowedUsers {
    updateRewards(msg.sender);
    for (uint256 i = 0; i < rewardTokens.length; i++) {
      _payReward(rewardTokens[i]);
    }
  }

  /**
   *  Update and Claim rewards for specific token
   */
  function getReward(address rt) public onlyAllowedUsers {
    updateReward(msg.sender, rt);
    _payReward(rt);
  }

  //**************** UNDERLYING MANAGEMENT FUNCTIONALITY ***********************

  /*
   * Returns the cash balance across all users in this contract.
   */
  function underlyingBalanceInVault() public view returns (uint256) {
    return IERC20Upgradeable(underlying()).balanceOf(address(this));
  }

  /* Returns the current underlying (e.g., DAI's) balance together with
   * the invested amount (if DAI is invested elsewhere by the strategy).
   */
  function underlyingBalanceWithInvestment() public view returns (uint256) {
    if (address(strategy()) == address(0)) {
      // initial state, when not set
      return underlyingBalanceInVault();
    }
    return underlyingBalanceInVault()
    .add(IStrategy(strategy()).investedUnderlyingBalance());
  }

  /**
   * Get the user's share (in underlying)
   * underlyingBalanceWithInvestment() * balanceOf(holder) / totalSupply()
   */
  function underlyingBalanceWithInvestmentForHolder(address holder)
  external view returns (uint256) {
    if (totalSupply() == 0) {
      return 0;
    }
    return underlyingBalanceWithInvestment()
    .mul(balanceOf(holder))
    .div(totalSupply());
  }

  /**
   * Price per full share (PPFS)
   * Vaults with 100% buybacks have a value of 1 constantly
   * (underlyingUnit() * underlyingBalanceWithInvestment()) / totalSupply()
   */
  function getPricePerFullShare() public view override returns (uint256) {
    return totalSupply() == 0
    ? underlyingUnit()
    : underlyingUnit().mul(underlyingBalanceWithInvestment()).div(totalSupply());
  }

  /**
   * Return amount of the underlying asset ready to invest to the strategy
   * (underlyingBalanceWithInvestment() * vaultFractionToInvestNumerator()
   *              * vaultFractionToInvestDenominator()) - alreadyInvested
   */
  function availableToInvestOut() public view returns (uint256) {
    uint256 wantInvestInTotal = underlyingBalanceWithInvestment()
    .mul(vaultFractionToInvestNumerator())
    .div(vaultFractionToInvestDenominator());
    uint256 alreadyInvested = IStrategy(strategy()).investedUnderlyingBalance();
    if (alreadyInvested >= wantInvestInTotal) {
      return 0;
    } else {
      uint256 remainingToInvest = wantInvestInTotal.sub(alreadyInvested);
      return remainingToInvest <= underlyingBalanceInVault()
      ? remainingToInvest : underlyingBalanceInVault();
    }
  }

  /**
   * Burn shares, withdraw underlying from strategy
   * and send back to the user the underlying asset
   */
  function _withdraw(uint256 numberOfShares) internal {
    require(totalSupply() > 0, "117");
    require(numberOfShares > 0, "118");
    uint256 totalSupply = totalSupply();
    _burn(msg.sender, numberOfShares);

    uint256 underlyingAmountToWithdraw = underlyingBalanceWithInvestment()
    .mul(numberOfShares)
    .div(totalSupply);
    if (underlyingAmountToWithdraw > underlyingBalanceInVault()) {
      // withdraw everything from the strategy to accurately check the share value
      if (numberOfShares == totalSupply) {
        IStrategy(strategy()).withdrawAllToVault();
      } else {
        uint256 missing = underlyingAmountToWithdraw.sub(underlyingBalanceInVault());
        IStrategy(strategy()).withdrawToVault(missing);
      }
      // recalculate to improve accuracy
      underlyingAmountToWithdraw = MathUpgradeable.min(underlyingBalanceWithInvestment()
      .mul(numberOfShares)
      .div(totalSupply), underlyingBalanceInVault());
    }

    IERC20Upgradeable(underlying()).safeTransfer(msg.sender, underlyingAmountToWithdraw);

    // update the withdrawal amount for the holder
    emit Withdraw(msg.sender, underlyingAmountToWithdraw);
  }

  /**
   * Mint shares and transfer underlying from user to the vault
   * New shares = (invested amount * total supply) / underlyingBalanceWithInvestment()
   */
  function _deposit(uint256 amount, address sender, address beneficiary) internal {
    require(amount > 0, "119");
    require(beneficiary != address(0), "120");

    uint256 toMint = totalSupply() == 0
    ? amount
    : amount.mul(totalSupply()).div(underlyingBalanceWithInvestment());
    _mint(beneficiary, toMint);

    IERC20Upgradeable(underlying()).safeTransferFrom(sender, address(this), amount);

    // update the contribution amount for the beneficiary
    emit Deposit(beneficiary, amount);
  }

  /**
   * Transfer underlying to the strategy
   */
  function invest() internal whenStrategyDefined {
    uint256 availableAmount = availableToInvestOut();
    if (availableAmount > 0) {
      IERC20Upgradeable(underlying()).safeTransfer(address(strategy()), availableAmount);
      IStrategy(strategy()).investAllUnderlying();
      emit Invest(availableAmount);
    }
  }

  //**************** REWARDS FUNCTIONALITY ***********************

  /**
   *  Return earned rewards for specific token and account
   *  Accurate value returns only after updateRewards call
   *  ((balanceOf(account)
   *    * (rewardPerToken - userRewardPerTokenPaidForToken)) / 10**18) + rewardsForToken
   */
  function earned(address rt, address account) public view returns (uint256) {
    return
    balanceOf(account)
    .mul(rewardPerToken(rt).sub(userRewardPerTokenPaidForToken[rt][account]))
    .div(1e18)
    .add(rewardsForToken[rt][account]);
  }

  /**
   * Return reward per token ratio by reward token address
   * rewardPerTokenStoredForToken + (
   * (lastTimeRewardApplicable - lastUpdateTimeForToken) * rewardRateForToken * 10**18 / totalSupply)
   */
  function rewardPerToken(address rt) public view returns (uint256) {
    if (totalSupply() == 0) {
      return rewardPerTokenStoredForToken[rt];
    }
    return
    rewardPerTokenStoredForToken[rt].add(
      lastTimeRewardApplicable(rt)
      .sub(lastUpdateTimeForToken[rt])
      .mul(rewardRateForToken[rt])
      .mul(1e18)
      .div(totalSupply())
    );
  }

  /**
   * Return periodFinishForToken or block.timestamp by reward token address
   */
  function lastTimeRewardApplicable(address rt) public view returns (uint256) {
    return MathUpgradeable.min(block.timestamp, periodFinishForToken[rt]);
  }

  /**
   * Return reward token array length
   */
  function rewardTokensLength() public view returns (uint256){
    return rewardTokens.length;
  }

  /**
   * Return reward token index
   * If the return value is MAX_UINT256, it means that
   * the specified reward token is not in the list
   */
  function getRewardTokenIndex(address rt) public override view returns (uint256) {
    for (uint i = 0; i < rewardTokens.length; i++) {
      if (rewardTokens[i] == rt)
        return i;
    }
    return uint256(- 1);
  }

  /**
   * Update rewardRateForToken
   * If period ended: reward / duration
   * else add leftover to the reward amount and refresh the period
   * (reward + ((periodFinishForToken - block.timestamp) * rewardRateForToken)) / duration
   */
  function notifyTargetRewardAmount(address _rewardToken, uint256 reward)
  public override
  onlyRewardDistribution
  {
    updateRewards(address(0));
    // overflow fix according to https://sips.synthetix.io/sips/sip-77
    require(reward < uint(- 1) / 1e18, "115");

    uint256 i = getRewardTokenIndex(_rewardToken);
    require(i != uint256(- 1), "116");

    if (block.timestamp >= periodFinishForToken[_rewardToken]) {
      rewardRateForToken[_rewardToken] = reward.div(duration());
    } else {
      uint256 remaining = periodFinishForToken[_rewardToken].sub(block.timestamp);
      uint256 leftover = remaining.mul(rewardRateForToken[_rewardToken]);
      rewardRateForToken[_rewardToken] = reward.add(leftover).div(duration());
    }
    lastUpdateTimeForToken[_rewardToken] = block.timestamp;
    periodFinishForToken[_rewardToken] = block.timestamp.add(duration());
    emit RewardAdded(_rewardToken, reward);
  }

  /**
   * Transfer earned rewards to caller
   */
  function _payReward(address rt) internal {
    uint256 reward = earned(rt, msg.sender);
    if (reward > 0 && IERC20Upgradeable(rt).balanceOf(address(this)) >= reward) {
      rewardsForToken[rt][msg.sender] = 0;
      IERC20Upgradeable(rt).safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, rt, reward);
    }
  }

  /**
   * Update account rewards for each reward token
   */
  function updateRewards(address account) public {
    for (uint256 i = 0; i < rewardTokens.length; i++) {
      address rt = rewardTokens[i];
      updateReward(account, rt);
    }
  }

  /**
   * Update reward data for given account and reward token
   */
  function updateReward(address account, address rt) internal {
    rewardPerTokenStoredForToken[rt] = rewardPerToken(rt);
    lastUpdateTimeForToken[rt] = lastTimeRewardApplicable(rt);
    if (account != address(0)) {
      rewardsForToken[rt][account] = earned(rt, account);
      userRewardPerTokenPaidForToken[rt][account] = rewardPerTokenStoredForToken[rt];
    }
  }

  //**************** VAULT UPDATE FUNCTIONALITY ***********************

  /**
   * Schedules an upgrade for this vault's proxy.
   */
  function scheduleUpgrade(address impl) public onlyGovernance {
    _setNextImplementation(impl);
    _setNextImplementationTimestamp(block.timestamp.add(nextImplementationDelay()));
  }

  /**
   *  Finalizes (or cancels) the vault update by resetting the data
   */
  function finalizeUpgrade() external override onlyGovernance {
    _setNextImplementation(address(0));
    _setNextImplementationTimestamp(0);
  }

  /**
   * Return ready state for the vault update and next implementation address
   * Use it in a proxy contract for checking availability to update this contract
   */
  function shouldUpgrade() external view override returns (bool, address) {
    return (
    nextImplementationTimestamp() != 0
    && block.timestamp > nextImplementationTimestamp()
    && nextImplementation() != address(0),
    nextImplementation()
    );
  }

  //**************** STRATEGY UPDATE FUNCTIONALITY ***********************

  /**
   * Return ready state for the strategy update
   */
  function canUpdateStrategy(address _strategy) public view returns (bool) {
    return strategy() == address(0) // no strategy was set yet
    || (_strategy == futureStrategy() // or the timelock has passed
    && block.timestamp > strategyUpdateTime()
    && strategyUpdateTime() > 0);
  }

  /**
   * Indicates that the strategy update will happen in the future
   */
  function announceStrategyUpdate(address _strategy) public onlyControllerOrGovernance {
    // records a new timestamp
    uint256 when = block.timestamp.add(strategyTimeLock());
    _setStrategyUpdateTime(when);
    _setFutureStrategy(_strategy);
    emit StrategyAnnounced(_strategy, when);
  }

  /**
   * Finalizes (or cancels) the strategy update by resetting the data
   */
  function finalizeStrategyUpdate() public onlyControllerOrGovernance {
    _setStrategyUpdateTime(0);
    _setFutureStrategy(address(0));
  }

  /**
   * Check the strategy time lock, withdraw all to the vault and change the strategy
   * Should be called via controller
   */
  function setStrategy(address _strategy) public override onlyControllerOrGovernance {
    require(canUpdateStrategy(_strategy), "105");
    require(_strategy != address(0), "106");
    require(IStrategy(_strategy).underlying() == address(underlying()), "107");
    require(IStrategy(_strategy).vault() == address(this), "108");

    emit StrategyChanged(_strategy, strategy());
    if (address(_strategy) != address(strategy())) {
      if (address(strategy()) != address(0)) {// if the original strategy (no underscore) is defined
        IERC20Upgradeable(underlying()).safeApprove(address(strategy()), 0);
        IStrategy(strategy()).withdrawAllToVault();
      }
      _setStrategy(_strategy);
      IERC20Upgradeable(underlying()).safeApprove(address(strategy()), 0);
      IERC20Upgradeable(underlying()).safeApprove(address(strategy()), uint256(~0));
    }
    finalizeStrategyUpdate();
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
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
library SafeMathUpgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

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
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

interface IStrategy {

  // *************** GOVERNANCE ACTIONS **************
  function withdrawAllToVault() external;

  function withdrawToVault(uint256 amount) external;

  // should only be called by controller
  function salvage(address recipient, address token, uint256 amount) external;

  function doHardWork() external;

  function investAllUnderlying() external;

  // **************** VIEWS ***************
  function underlying() external view returns (address);

  function underlyingBalance() external view returns (uint256);

  function vault() external view returns (address);

  function investedUnderlyingBalance() external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

interface ISmartVault {

  function setStrategy(address _strategy) external;

  function doHardWork() external;

  function notifyTargetRewardAmount(address _rewardToken, uint256 reward) external;

  function deposit(uint256 amount) external;

  function underlying() external view returns (address);

  function strategy() external view returns (address);

  function getRewardTokenIndex(address rt) external view returns (uint256);

  function getPricePerFullShare() external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

interface IController {

  function whiteList(address _target) external view returns (bool);

  function vaults(address _target) external view returns (bool);

  function strategies(address _target) external view returns (bool);

  function profitSharingNumerator() external view returns (uint256);

  function profitSharingDenominator() external view returns (uint256);

  function feeRewardForwarder() external view returns (address);

  function governance() external view returns (address);

  function bookkeeper() external view returns (address);

  function isAllowedUser(address _adr) external view returns (bool);

  function isGovernance(address _adr) external view returns (bool);

  function isHardWorker(address _adr) external view returns (bool);

  function isRewardDistributor(address _adr) external view returns (bool);

  function isValidVault(address _vault) external view returns (bool);
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

interface IUpgradeSource {

  function finalizeUpgrade() external;

  function shouldUpgrade() external view returns (bool, address);

}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "../interface/ISmartVault.sol";

// Eternal storage + getters and setters pattern
// If you will change a key value it will require setup it again
// Implements IVault interface for reducing code base
abstract contract VaultStorage is Initializable, ISmartVault {

  // don't change names or ordering!
  mapping(bytes32 => uint256) private uintStorage;
  mapping(bytes32 => address) private addressStorage;
  mapping(bytes32 => bool) private boolStorage;

  event UpdatedBoolSlot(string name, bool oldValue, bool newValue);
  event UpdatedAddressSlot(string name, address oldValue, address newValue);
  event UpdatedUint256Slot(string name, uint256 oldValue, uint256 newValue);

  function initializeVaultStorage(
    address _underlyingToken,
    uint256 _toInvestNumerator,
    uint256 _toInvestDenominator,
    uint256 _underlyingUnitValue,
    uint256 _implementationChangeDelay,
    uint256 _strategyChangeDelay,
    uint256 _durationValue
  ) public initializer {
    _setUnderlying(_underlyingToken);
    _setVaultFractionToInvestNumerator(_toInvestNumerator);
    _setVaultFractionToInvestDenominator(_toInvestDenominator);
    _setUnderlyingUnit(_underlyingUnitValue);
    _setNextImplementationDelay(_implementationChangeDelay);
    _setStrategyTimeLock(_strategyChangeDelay);
    _setStrategyUpdateTime(0);
    _setFutureStrategy(address(0));
    _setAllowSharePriceDecrease(false);
    _setWithdrawBeforeReinvesting(false);
    _setDuration(_durationValue);
    _setActive(true);
  }

  // ******************* SETTERS AND GETTERS **********************

  function _setStrategy(address _address) internal {
    emit UpdatedAddressSlot("strategy", strategy(), _address);
    setAddress("strategy", _address);
  }

  function strategy() public override view returns (address) {
    return getAddress("strategy");
  }

  function _setUnderlying(address _address) private {
    emit UpdatedAddressSlot("underlying", strategy(), _address);
    setAddress("underlying", _address);
  }

  function underlying() public view override returns (address) {
    return getAddress("underlying");
  }

  function _setUnderlyingUnit(uint256 _value) internal {
    emit UpdatedUint256Slot("underlyingUnit", underlyingUnit(), _value);
    setUint256("underlyingUnit", _value);
  }

  function underlyingUnit() public view returns (uint256) {
    return getUint256("underlyingUnit");
  }

  function _setVaultFractionToInvestNumerator(uint256 _value) internal {
    emit UpdatedUint256Slot("vaultFractionToInvestNumerator",
      vaultFractionToInvestNumerator(), _value);
    setUint256("vaultFractionToInvestNumerator", _value);
  }

  function vaultFractionToInvestNumerator() public view returns (uint256) {
    return getUint256("vaultFractionToInvestNumerator");
  }

  function _setVaultFractionToInvestDenominator(uint256 _value) internal {
    emit UpdatedUint256Slot("vaultFractionToInvestDenominator",
      vaultFractionToInvestDenominator(), _value);
    setUint256("vaultFractionToInvestDenominator", _value);
  }

  function vaultFractionToInvestDenominator() public view returns (uint256) {
    return getUint256("vaultFractionToInvestDenominator");
  }

  function _setAllowSharePriceDecrease(bool _value) internal {
    emit UpdatedBoolSlot("allowSharePriceDecrease", allowSharePriceDecrease(), _value);
    setBoolean("allowSharePriceDecrease", _value);
  }

  function allowSharePriceDecrease() public view returns (bool) {
    return getBoolean("allowSharePriceDecrease");
  }

  function _setWithdrawBeforeReinvesting(bool _value) internal {
    emit UpdatedBoolSlot("withdrawBeforeReinvesting", withdrawBeforeReinvesting(), _value);
    setBoolean("withdrawBeforeReinvesting", _value);
  }

  function withdrawBeforeReinvesting() public view returns (bool) {
    return getBoolean("withdrawBeforeReinvesting");
  }

  function _setNextImplementation(address _address) internal {
    emit UpdatedAddressSlot("nextImplementation", nextImplementation(), _address);
    setAddress("nextImplementation", _address);
  }

  function nextImplementation() public view returns (address) {
    return getAddress("nextImplementation");
  }

  function _setNextImplementationTimestamp(uint256 _value) internal {
    emit UpdatedUint256Slot("nextImplementationTimestamp", nextImplementationTimestamp(), _value);
    setUint256("nextImplementationTimestamp", _value);
  }

  function nextImplementationTimestamp() public view returns (uint256) {
    return getUint256("nextImplementationTimestamp");
  }

  function _setNextImplementationDelay(uint256 _value) internal {
    emit UpdatedUint256Slot("nextImplementationDelay", nextImplementationDelay(), _value);
    setUint256("nextImplementationDelay", _value);
  }

  function nextImplementationDelay() public view returns (uint256) {
    return getUint256("nextImplementationDelay");
  }

  function _setStrategyTimeLock(uint256 _value) internal {
    emit UpdatedUint256Slot("strategyTimeLock", strategyTimeLock(), _value);
    setUint256("strategyTimeLock", _value);
  }

  function strategyTimeLock() public view returns (uint256) {
    return getUint256("strategyTimeLock");
  }

  function _setFutureStrategy(address _value) internal {
    emit UpdatedAddressSlot("futureStrategy", futureStrategy(), _value);
    setAddress("futureStrategy", _value);
  }

  function futureStrategy() public view returns (address) {
    return getAddress("futureStrategy");
  }

  function _setStrategyUpdateTime(uint256 _value) internal {
    emit UpdatedUint256Slot("strategyUpdateTime", strategyUpdateTime(), _value);
    setUint256("strategyUpdateTime", _value);
  }

  function strategyUpdateTime() public view returns (uint256) {
    return getUint256("strategyUpdateTime");
  }

  function _setDuration(uint256 _value) internal {
    emit UpdatedUint256Slot("duration", duration(), _value);
    setUint256("duration", _value);
  }

  function duration() public view returns (uint256) {
    return getUint256("duration");
  }

  function _setActive(bool _value) internal {
    emit UpdatedBoolSlot("active", active(), _value);
    setBoolean("active", _value);
  }

  function active() public view returns (bool) {
    return getBoolean("active");
  }

  // ******************** STORAGE INTERNAL FUNCTIONS ********************

  function setBoolean(string memory key, bool _value) internal {
    boolStorage[keccak256(abi.encodePacked(key))] = _value;
  }

  function getBoolean(string memory key) internal view returns (bool) {
    return boolStorage[keccak256(abi.encodePacked(key))];
  }

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

}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "../interface/IController.sol";

/**
* 200 - vault does not exist
* 201 - only hard worker or governance can call this
* 202 - Not governance
* 203 - message sender is a contract and have not added to the white list
* 204 - Not reward distributor
* 205 - empty address
* 206 - Not controller
*/
abstract contract Controllable is Initializable {
  bytes32 internal constant _CONTROLLER_SLOT = 0x5165972ef41194f06c5007493031d0b927c20741adcb74403b954009fd2c3617;
  bytes32 internal constant _CREATED_SLOT = 0x6f55f470bdc9cb5f04223fd822021061668e4dccb43e8727b295106dc9769c8a;

  event UpdateController(address oldValue, address newValue);

  function initializeControllable(address _controller) public initializer {
    assert(_CONTROLLER_SLOT == bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1));
    assert(_CREATED_SLOT == bytes32(uint256(keccak256("eip1967.controllable.created")) - 1));
    setController(_controller);
    setCreated(block.timestamp);
  }

  // ************ MODIFIERS **********************

  modifier validVault(address _vault){
    require(IController(controller()).isValidVault(_vault), "200");
    _;
  }

  modifier onlyHardWorkerOrGovernance() {
    require(IController(controller()).isHardWorker(msg.sender)
      || IController(controller()).isGovernance(msg.sender), "201");
    _;
  }

  modifier onlyGovernance() {
    require(IController(controller()).isGovernance(msg.sender), "202");
    _;
  }

  modifier onlyControllerOrGovernance() {
    require(controller() == msg.sender || IController(controller()).isGovernance(msg.sender), "206");
    _;
  }

  /**
 *  Only smart contracts will be affected by this modifier
 *  If it is a contract it should be whitelisted
 */
  modifier onlyAllowedUsers() {
    require(IController(controller()).isAllowedUser(msg.sender), "203");
    _;
  }

  modifier onlyRewardDistribution() {
    require(IController(controller()).isRewardDistributor(msg.sender), "204");
    _;
  }

  // ************* SETTERS/GETTERS *******************

  function controller() public view returns (address str) {
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      str := sload(slot)
    }
  }

  function setController(address _newController) internal {
    require(_newController != address(0), "205");
    emit UpdateController(controller(), _newController);
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      sstore(slot, _newController)
    }
  }

  function created() public view returns (uint256 str) {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      str := sload(slot)
    }
  }

  function setCreated(uint256 _created) private {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      sstore(slot, _created)
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
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