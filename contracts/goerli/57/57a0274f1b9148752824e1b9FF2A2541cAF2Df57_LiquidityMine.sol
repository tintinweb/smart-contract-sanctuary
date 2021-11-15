pragma solidity >=0.6.6;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "./interfaces/IDAO.sol";
import "./interfaces/IStabilizerNode.sol";
import "./libraries/UniswapV2Library.sol";


contract LPTokenWrapper is AccessControl {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  struct State {
    uint256 bonded;
    uint256 subsidizedLP;
    uint256 lastBlock; // flash loan attack protection
  }

  ERC20 public malt;
  ERC20 public rewardToken;
  ERC20 public stakeToken;
  address public uniswapV2Factory;

  State internal _globals;
  mapping(address => State) private _accounts;

  event Bond(address indexed account, uint256 value);
  event Unbond(address indexed account, uint256 value);
  event Withdraw(address indexed account, uint256 rewarded, uint256 maltReward);
  event Forfeit(address indexed account, address token, uint256 amount);

  function _bond(uint256 amount) internal notSameBlock {
    stakeToken.safeTransferFrom(msg.sender, address(this), amount);

    addToBonded(msg.sender, amount);

    balanceCheck();

    emit Bond(msg.sender, amount);
  }

  function _unbond(uint256 amountLPToken) internal notSameBlock {
    removeFromBonded(msg.sender, amountLPToken, "LP: Insufficient bonded balance");

    stakeToken.safeTransfer(msg.sender, amountLPToken);

    balanceCheck();

    emit Unbond(msg.sender, amountLPToken);
  }

  function _withdraw(uint256 amountReward, uint256 maltReward) internal notSameBlock {

    rewardToken.safeTransfer(msg.sender, amountReward);
    malt.safeTransfer(msg.sender, maltReward);

    balanceCheck();

    emit Withdraw(msg.sender, amountReward, maltReward);
  }

  /* Public view functions */

  function totalBonded() public view returns (uint256) {
    return _globals.bonded;
  }

  function balanceOfBonded(address account) public view returns (uint256) {
    return _accounts[account].bonded.sub(_accounts[account].subsidizedLP);
  }

  function balanceOfSubsidizedLP(address account) public view returns (uint256) {
    return _accounts[account].subsidizedLP;
  }

  function realValueOfLPToken(uint256 amount) public view returns (uint256, uint256) {
    (uint256 maltReserves, uint256 rewardReserves) = UniswapV2Library.getReserves(
      uniswapV2Factory,
      address(malt),
      address(rewardToken)
    );

    if (maltReserves == 0) {
      return (0, 0);
    }

    uint256 totalLPSupply = stakeToken.totalSupply();

    return (amount.mul(maltReserves).div(totalLPSupply), amount.mul(rewardReserves).div(totalLPSupply));
  }

  function realValueOfBonded(address account) public view returns (uint256, uint256) {
    (uint256 maltReserves, uint256 rewardReserves) = UniswapV2Library.getReserves(
      uniswapV2Factory,
      address(malt),
      address(rewardToken)
    );

    if (maltReserves == 0) {
      return (0, 0);
    }

    uint256 totalLPSupply = stakeToken.totalSupply();

    uint256 balance = balanceOfBonded(account);

    return (balance.mul(maltReserves).div(totalLPSupply), balance.mul(rewardReserves).div(totalLPSupply));
  }

  function realValueOfSubsidizedLP(address account) public view returns (uint256, uint256) {
    (uint256 maltReserves, uint256 rewardReserves) = UniswapV2Library.getReserves(
      uniswapV2Factory,
      address(malt),
      address(rewardToken)
    );

    if (maltReserves == 0) {
      return (0, 0);
    }

    uint256 totalLPSupply = stakeToken.totalSupply();

    uint256 balance = balanceOfSubsidizedLP(account);

    return (balance.mul(maltReserves).div(totalLPSupply), balance.mul(rewardReserves).div(totalLPSupply));
  }

  /* Internal helpers */
  function setRewardToken(address _rewardToken) internal {
    rewardToken = ERC20(_rewardToken);
  }

  function setStakeToken(address _token) internal {
    stakeToken = ERC20(_token);
  }

  function setMaltToken(address _maltToken) internal {
    malt = ERC20(_maltToken);
  }

  function setUniswapFactory(address _factory) internal {
    uniswapV2Factory = _factory;
  }

  function addToBonded(address account, uint256 amount) internal {
    _accounts[account].bonded = _accounts[account].bonded.add(amount);
    _globals.bonded = _globals.bonded.add(amount);
  }

  function addToSubsidizedLP(address account, uint256 amount) internal {
    _accounts[account].subsidizedLP = _accounts[account].subsidizedLP.add(amount);
    _globals.subsidizedLP = _globals.subsidizedLP.add(amount);
  }

  function removeFromBonded(address account, uint256 amount, string memory reason) internal {
    _accounts[account].bonded = _accounts[account].bonded.sub(amount, reason);
    _globals.bonded = _globals.bonded.sub(amount, reason);
  }

  function removeFromSubsidizedLP(address account, uint256 amount, string memory reason) internal {
    _accounts[account].subsidizedLP = _accounts[account].subsidizedLP.sub(amount, reason);
    _globals.subsidizedLP = _globals.subsidizedLP.sub(amount, reason);
  }

  function balanceCheck() internal view {
    require(stakeToken.balanceOf(address(this)) >= totalBonded(), "Balance inconsistency");
  }

  modifier notSameBlock() {
    require(
      block.number > _accounts[_msgSender()].lastBlock,
      "Can't carry out actions in the same block"
    );
    _accounts[_msgSender()].lastBlock = block.number;
    _;
  }
}


contract LiquidityMine is Initializable, AccessControl, LPTokenWrapper {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  struct Pair {
    uint256 reward;
    uint256 malt;
  }
  struct SignedPair {
    uint256 reward;
    uint256 malt;
  }

  struct Totals {
    Pair withdraws;
    Pair earned;
    Pair forfeited;
    Pair allocated;
    Pair stakePadding;
  }

  struct UserState {
    uint256 stakePadding;
    uint256 maltStakePadding;
    uint256 bondedEpoch;
    uint256 unbondedBalance;
    uint256 unbondedMaltBalance;
    uint256[] bondEpochs;
    uint256[] unbondEpochs;
    uint256[] withdrawEpochs;
    mapping(uint256 => uint256) epochBonds;
    mapping(uint256 => uint256) epochUnbonds;
    mapping(uint256 => Pair) epochWithdraws;
    mapping(uint256 => Pair) epochForfeits;
    mapping(uint256 => SignedPair) epochStakePadding;
  }

  struct EpochRewards {
    uint256 reward;
    uint256 maltReward;
    uint256 totalReward;
    uint256 totalMaltReward;
    uint256 stakePadding;
    uint256 maltStakePadding;
    uint256 completionTime;
    uint256 totalBonded;
    uint256 valueOfBondedMalt;
    uint256 valueOfBondedReward;
    bool advanced;
  }

  struct UnlockData {
    uint256 totalReward;
    uint256 unlockedReward;
    uint256 totalMalt;
    uint256 unlockedMalt;
    uint256 userBondedTotal;
  }

  struct ReinvestRebalance {
    uint256 rewardRemoval;
    uint256 maltRemoval;
    uint256 excess;
    uint256 minMalt;
    uint256 minReward;
  }

  bytes32 public constant REWARDER_ROLE = keccak256("REWARDER_ROLE");
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  address public treasuryMultisig;
  uint256 public INITIAL_STAKE_SHARE_MULTIPLE;
  string public mineName;
  uint256 public payoutDuration;
  uint256 public startTime;
  IDAO public dao;

  uint256 internal _globalStakePadding;
  uint256 internal _globalMaltStakePadding;
  uint256 internal _declaredBalance;
  uint256 internal _declaredMaltBalance;

  // These are the parts of declared balances that are yet unclaimed after unbonding
  uint256 internal _unbondedBalance;
  uint256 internal _unbondedMaltBalance;

  IUniswapV2Router02 public router;
  IStabilizerNode public stabilizerNode;

  // TODO methods to fetch the values / mappings in this struct Wed 24 Mar 2021 01:29:07 GMT
  mapping(address => UserState) private userState;
  mapping(uint256 => EpochRewards) public epochRewards;

  function initialize(
    string calldata _mineName,
    address _rewardToken,
    address _stakeToken,
    address _maltToken,
    uint256 duration,
    uint256 _startTime,
    address _dao,
    address rewarder,
    uint256 stakePaddingMultiple,
    address _uniswapV2Factory,
    address _treasuryMultisig,
    address _router,
    address _stabilizerNode,
    address _timelock
  ) external initializer {
    setRewardToken(_rewardToken);
    setStakeToken(_stakeToken);
    setMaltToken(_maltToken);
    setUniswapFactory(_uniswapV2Factory);

    treasuryMultisig = _treasuryMultisig;
    router = IUniswapV2Router02(_router);
    stabilizerNode = IStabilizerNode(_stabilizerNode);

    mineName = _mineName;
    payoutDuration = duration; // In epochs
    startTime = _startTime;
    INITIAL_STAKE_SHARE_MULTIPLE = stakePaddingMultiple;
    dao = IDAO(_dao);

    _setupRole(REWARDER_ROLE, rewarder);
    _setupRole(ADMIN_ROLE, _timelock);

    _setRoleAdmin(REWARDER_ROLE, ADMIN_ROLE);
    _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
  }

  function declareReward(uint256 amount) external onlyRewarder {
    _declaredBalance = _declaredBalance.add(amount);
    require(_declaredBalance <= rewardToken.balanceOf(address(this)), "Insufficient balance to declare reward");
    require(amount > 0, "Cannot declare zero reward");

    if (totalBonded() == 0) {
      // There is no accounts to distribute the rewards to so forfeit it to the dao
      _forfeit(amount);
      updateCurrentEpochTotalRewards();
      return;
    } 

    uint256 currentEpoch = epoch();

    epochRewards[currentEpoch].reward = epochRewards[currentEpoch].reward + amount;

    updateCurrentEpochTotalRewards();

    if (epochRewards[currentEpoch].completionTime == 0) {
      epochRewards[currentEpoch].completionTime = getEpochStartTime(
        currentEpoch.add(payoutDuration)
      );
    }

    advance();
  }

  function declareMaltReward(uint256 amount) external onlyRewarder {
    _declaredMaltBalance = _declaredMaltBalance.add(amount);
    require(_declaredMaltBalance <= malt.balanceOf(address(this)), "Insufficient balance to declare reward");
    require(amount > 0, "Cannot declare zero reward");

    if (totalBonded() == 0) {
      // There is no accounts to distribute the rewards to so forfeit it to the dao
      _forfeitMalt(amount);
      updateCurrentEpochTotalRewards();
      return;
    } 

    uint256 currentEpoch = epoch();

    epochRewards[currentEpoch].maltReward = epochRewards[currentEpoch].maltReward + amount;

    updateCurrentEpochTotalRewards();

    if (epochRewards[currentEpoch].completionTime == 0) {
      epochRewards[currentEpoch].completionTime = getEpochStartTime(
        currentEpoch.add(payoutDuration)
      );
    }

    advance();
  }

  function advance() public {
    uint256 currentEpoch = epoch();
    // TODO should this check completionTime instead Mon 29 Mar 2021 18:10:25 BST
    if (!epochRewards[currentEpoch].advanced) {
      uint256 bonded = totalBonded();
      (uint256 maltValue, uint256 rewardValue) = realValueOfLPToken(bonded);
      epochRewards[currentEpoch].totalBonded = bonded;
      epochRewards[currentEpoch].advanced = true;
      epochRewards[currentEpoch].valueOfBondedMalt = maltValue;
      epochRewards[currentEpoch].valueOfBondedReward = rewardValue;
      epochRewards[currentEpoch].stakePadding = _globalStakePadding;
      epochRewards[currentEpoch].maltStakePadding = _globalMaltStakePadding;

      updateCurrentEpochTotalRewards();
    }
  }

  /* Core external functions */
  function bond(uint256 amount)
    public
    checkStart
    updateReward(msg.sender)
  {
    require(amount > 0, "Cannot bond 0");

    _handleStakePadding(msg.sender, amount);
    _bond(amount);

    uint256 currentEpoch = epoch();

    epochRewards[currentEpoch].totalBonded = _globals.bonded;
  }

  function unbond(uint256 amount)
    external
    checkStart
    updateReward(msg.sender)
    bondingValidityCheck(amount)
  {
    uint256 bondedBalance = balanceOfBonded(msg.sender);
    require(bondedBalance > 0, "Insufficient bonded balance");
    require(amount <= bondedBalance, "Insufficient bonded balance");

    _checkForForfeit(amount, bondedBalance);

    removeFromEpochBonding(msg.sender, amount);

    uint256 lessStakePadding = balanceOfStakePadding(msg.sender).mul(amount).div(bondedBalance);
    uint256 lessMaltStakePadding = balanceOfMaltStakePadding(msg.sender).mul(amount).div(bondedBalance);

    removeFromStakePadding(msg.sender, lessStakePadding, lessMaltStakePadding, "Insufficient stake padding");

    updateCurrentEpochTotalRewards();

    _clearSubsidizedLP(msg.sender, bondedBalance);

    _unbond(amount);

    uint256 currentEpoch = epoch();

    epochRewards[currentEpoch].totalBonded = _globals.bonded;
  }

  function withdraw(uint256 rewardAmount, uint256 maltAmount)
    external
    checkStart
    updateReward(msg.sender)
  {
    (uint256 rewardEarned, uint256 maltEarned) = earned(msg.sender);

    require(rewardAmount <= rewardEarned, "Cannot withdraw more reward than earned");
    require(maltAmount <= maltEarned, "Cannot withdraw more malt reward than earned");

    // Remove from reward and add equivalent to stake padding.
    // Conservation of reward space volume
    addToStakePadding(msg.sender, rewardAmount, maltAmount);
    _declaredBalance = _declaredBalance.sub(rewardAmount);
    _declaredMaltBalance = _declaredMaltBalance.sub(maltAmount);

    updateCurrentEpochTotalRewards();

    uint256 currentEpoch = epoch();

    addToEpochWithdraw(msg.sender, rewardAmount, maltAmount);

    removeFromUnbondedBalance(msg.sender, rewardEarned, maltEarned);

    _withdraw(rewardAmount, maltAmount);
  }

  function reinvestReward(uint256 rewardLiquidity, uint256 desiredMalt) external {
    require(rewardLiquidity > 0, "Cannot reinvest zero");
    _verifyReinvest(desiredMalt, rewardLiquidity);

    uint256 maltLiquidity = _getOptimalLiquidity(address(malt), address(rewardToken), rewardLiquidity);

    if (maltLiquidity > desiredMalt) {
      malt.safeTransferFrom(msg.sender, address(this), maltLiquidity.sub(desiredMalt));
    }

    _addLiquidity(maltLiquidity, rewardLiquidity, true, desiredMalt);
  }

  function reinvestMalt(uint256 maltLiquidity, uint256 desiredReward) external {
    require(maltLiquidity > 0, "Cannot reinvest zero");
    _verifyReinvest(maltLiquidity, desiredReward);

    uint256 rewardLiquidity = _getOptimalLiquidity(address(rewardToken), address(malt), maltLiquidity);

    if (rewardLiquidity > desiredReward) {
      rewardToken.safeTransferFrom(msg.sender, address(this), rewardLiquidity.sub(desiredReward));
    }

    _addLiquidity(maltLiquidity, rewardLiquidity, false, desiredReward);
  }

  function compoundReinvest(uint256 rewardLiquidity) external {
    require(rewardLiquidity > 0, "Cannot reinvest zero");
    _verifyReinvest(0, rewardLiquidity);

    rewardToken.approve(address(router), rewardLiquidity.div(2));

    address[] memory path = new address[](2);
    path[0] = address(rewardToken);
    path[1] = address(malt);

    uint256 initialBalance = malt.balanceOf(address(this));

    router.swapExactTokensForTokens(
      rewardLiquidity.div(2),
      0, 
      path,
      address(this),
      now
    );

    uint256 finalBalance = malt.balanceOf(address(this));
    uint256 maltLiquidity = finalBalance - initialBalance;

    malt.approve(address(router), maltLiquidity);
    rewardToken.approve(address(router), rewardLiquidity.div(2));

    ReinvestRebalance memory rebalance = ReinvestRebalance({
      rewardRemoval: rewardLiquidity,
      maltRemoval: 0,
      excess: 0,
      minMalt: maltLiquidity.mul(95).div(100),
      minReward: rewardLiquidity.div(2).mul(95).div(100)
    });

    (
      uint256 amountMalt,
      uint256 amountReward,
      uint256 liquidity
    ) = router.addLiquidity(
      address(malt),
      address(rewardToken),
      maltLiquidity,
      rewardLiquidity.div(2),
      rebalance.minMalt,
      rebalance.minReward,
      address(this),
      now
    );

    _updateBond(rebalance.rewardRemoval, 0, liquidity);
  }

  function subsidizedReinvest(uint256 rewardLiquidity) external {
    // This can only be called in the first week after launch
    require(epoch() <= 336, "Can only use subsidizedReinvest during the first 336 epochs");

    _verifyReinvest(0, rewardLiquidity);

    uint256 maltLiquidity = _getOptimalLiquidity(address(malt), address(rewardToken), rewardLiquidity);

    stabilizerNode.requestMint(maltLiquidity);

    malt.approve(address(router), maltLiquidity);
    rewardToken.approve(address(router), rewardLiquidity);

    (
      uint256 amountReward,
      uint256 amountMalt,
      uint256 liquidity
    ) = router.addLiquidity(
      address(rewardToken),
      address(malt),
      rewardLiquidity,
      maltLiquidity,
      rewardLiquidity.mul(95).div(100), // 5% slippage
      maltLiquidity.mul(95).div(100), // 5% slippage
      address(this),
      now
    );

    if (amountMalt < maltLiquidity) {
      uint256 burnAmount = maltLiquidity.sub(amountMalt);
      malt.transfer(address(stabilizerNode), burnAmount);
      stabilizerNode.requestBurn(burnAmount);
    }

    // Remove from reward and add equivalent to stake padding.
    // This reward now exists in LP tokens instead
    addToStakePadding(msg.sender, amountReward, 0);
    _declaredBalance = _declaredBalance.sub(amountReward);

    updateCurrentEpochTotalRewards();

    uint256 currentEpoch = epoch();

    addToEpochWithdraw(msg.sender, amountReward, 0);

    _handleStakePadding(msg.sender, liquidity);

    addToBonded(msg.sender, liquidity);
    addToSubsidizedLP(msg.sender, liquidity.div(2));

    epochRewards[currentEpoch].totalBonded = _globals.bonded;

    balanceCheck();

    emit Bond(msg.sender, liquidity);
  }

  function earned(address account) public view returns (uint256 earnedReward, uint256 earnedMalt) {
    uint256 currentEpoch = epoch();

    if (userState[account].bondedEpoch == currentEpoch) {
      return (0, 0);
    }

    Totals memory accountTotals;

    uint256 initialEpoch = 0;
    if (currentEpoch > payoutDuration) {
      initialEpoch = currentEpoch - payoutDuration;
    }
    if (initialEpoch < userState[account].bondedEpoch) {
      initialEpoch = userState[account].bondedEpoch;
    }
    uint256 previousEpoch = currentEpoch > 0 ? currentEpoch - 1 : 0;

    uint256 bondedBalance = balanceOfBonded(account) + balanceOfSubsidizedLP(account);

    accountTotals.stakePadding.reward = balanceOfStakePadding(account);
    accountTotals.stakePadding.malt = balanceOfMaltStakePadding(account);

    uint256 earned = 0;
    uint256 allocated = 0;

    for (uint256 i = currentEpoch; i > initialEpoch; i -= 1) {
      bondedBalance = bondedBalance - userState[account].epochBonds[i] + userState[account].epochUnbonds[i];

      accountTotals.stakePadding.reward = accountTotals.stakePadding.reward - userState[account].epochStakePadding[i].reward;
      accountTotals.stakePadding.malt = accountTotals.stakePadding.malt - userState[account].epochStakePadding[i].malt;

      accountTotals.withdraws.reward = accountTotals.withdraws.reward + userState[account].epochWithdraws[i].reward;
      accountTotals.withdraws.malt = accountTotals.withdraws.malt + userState[account].epochWithdraws[i].malt;

      (earned, allocated) = _epochEarnedRewards(account, i, accountTotals.stakePadding.reward, bondedBalance);
      accountTotals.earned.reward = accountTotals.earned.reward + earned;
      accountTotals.allocated.reward = accountTotals.allocated.reward + allocated;

      (earned, allocated) = _epochEarnedMaltRewards(account, i, accountTotals.stakePadding.malt, bondedBalance);
      accountTotals.earned.malt = accountTotals.earned.malt + earned;
      accountTotals.allocated.malt = accountTotals.allocated.malt + allocated;

      accountTotals.forfeited.reward = accountTotals.forfeited.reward + userState[account].epochForfeits[i].reward;
      accountTotals.forfeited.malt = accountTotals.forfeited.malt + userState[account].epochForfeits[i].malt;
    }

    // TODO go through anywhere we can use a conditional to avoid writing a new value to storage Tue 30 Mar 2021 12:34:03 BST

    // Add full rewards from initialEpoch
    if (initialEpoch > userState[account].bondedEpoch) {
      bondedBalance = bondedBalance - userState[account].epochBonds[initialEpoch] + userState[account].epochUnbonds[initialEpoch];
      accountTotals.stakePadding.reward = accountTotals.stakePadding.reward - userState[account].epochStakePadding[initialEpoch].reward;
      accountTotals.stakePadding.malt = accountTotals.stakePadding.malt - userState[account].epochStakePadding[initialEpoch].malt;

      allocated = _epochBalanceOfRewards(account, initialEpoch, accountTotals.stakePadding.reward, bondedBalance);
      accountTotals.earned.reward = accountTotals.earned.reward + allocated;
      accountTotals.allocated.reward = accountTotals.allocated.reward + allocated;

      allocated = _epochBalanceOfMaltRewards(account, initialEpoch, accountTotals.stakePadding.malt, bondedBalance);
      accountTotals.earned.malt = accountTotals.earned.malt + allocated;
      accountTotals.allocated.malt = accountTotals.allocated.malt + allocated;
    }

    // Subtract totalWithdraws
    if (accountTotals.withdraws.reward >= accountTotals.earned.reward) {
      accountTotals.earned.reward = 0;
    } else {
      accountTotals.earned.reward = accountTotals.earned.reward - accountTotals.withdraws.reward;
    }

    if (accountTotals.withdraws.malt >= accountTotals.earned.malt) {
      accountTotals.earned.malt = 0;
    } else {
      accountTotals.earned.malt = accountTotals.earned.malt - accountTotals.withdraws.malt;
    }

    if (accountTotals.earned.reward > accountTotals.allocated.reward.sub(accountTotals.forfeited.reward)) {
      accountTotals.earned.reward = accountTotals.allocated.reward.sub(accountTotals.forfeited.reward);
    }

    if (accountTotals.earned.malt > accountTotals.allocated.malt.sub(accountTotals.forfeited.malt)) {
      accountTotals.earned.malt = accountTotals.allocated.malt.sub(accountTotals.forfeited.malt);
    }

    return (accountTotals.earned.reward, accountTotals.earned.malt);
  }

  function balanceOfRewards(address account) public view returns (uint256) {
    /*
     * This represents the rewards allocated to a given account but does not
     * mean all these rewards are unlocked yet. The earned method will
     * fetch the balance that is unlocked for an account
     */
    uint256 globalBondedTotal = totalBonded();
    if (globalBondedTotal == 0) {
      return 0;
    }

    uint256 totalRewardedWithStakePadding = totalBondedRewarded().add(totalStakePadding());
    uint256 balanceOfRewardedWithStakePadding = totalRewardedWithStakePadding
      .mul(balanceOfBonded(account).add(balanceOfSubsidizedLP(account)))
      .div(globalBondedTotal);

    uint256 stakePaddingBalance = balanceOfStakePadding(account);

    if (balanceOfRewardedWithStakePadding > stakePaddingBalance) {
      return balanceOfRewardedWithStakePadding - stakePaddingBalance;
    }
    return 0;
  }

  function balanceOfMaltRewards(address account) public view returns (uint256) {
    /*
     * This represents the malt rewards allocated to a given account but does not
     * mean all these rewards are unlocked yet. The earned method will
     * fetch the balance that is unlocked for an account
     */
    uint256 globalBondedTotal = totalBonded();
    if (globalBondedTotal == 0) {
      return 0;
    }

    uint256 totalRewardedWithStakePadding = totalBondedMaltRewarded().add(totalMaltStakePadding());
    uint256 balanceOfRewardedWithStakePadding = totalRewardedWithStakePadding
      .mul(balanceOfBonded(account).add(balanceOfSubsidizedLP(account)))
      .div(globalBondedTotal);

    uint256 stakePaddingBalance = balanceOfMaltStakePadding(account);
    if (balanceOfRewardedWithStakePadding > stakePaddingBalance) {
      return balanceOfRewardedWithStakePadding.sub(stakePaddingBalance);
    }
    return 0;
  }

  function getEpochStartTime(uint256 epochNumber) internal view returns (uint256) {
    return dao.getEpochStartTime(epochNumber);
  }

  function totalStakePadding() public view returns(uint256) {
    return _globalStakePadding;  
  }

  function totalMaltStakePadding() public view returns(uint256) {
    return _globalMaltStakePadding;  
  }

  function totalBondedAtEpoch(uint256 epoch) public view returns(uint256) {
    return epochRewards[epoch].totalBonded;
  }

  function totalRewardedAtEpoch(uint256 epoch) public view returns(uint256) {
    return epochRewards[epoch].reward;
  }

  function balanceOfStakePadding(address account) public view returns (uint256) {
    return userState[account].stakePadding;
  }

  function balanceOfMaltStakePadding(address account) public view returns (uint256) {
    return userState[account].maltStakePadding;
  }

  function epoch() public view returns (uint256) {
    return dao.epoch();
  }

  function epochLength() public view returns (uint256) {
    return dao.epochLength();
  }

  function totalRewarded() public view returns (uint256) {
    return _declaredBalance;
  }

  function totalMaltRewarded() public view returns (uint256) {
    return _declaredMaltBalance;
  }

  function totalBondedRewarded() public view returns (uint256) {
    return _declaredBalance.sub(_unbondedBalance);
  }

  function totalBondedMaltRewarded() public view returns (uint256) {
    return _declaredMaltBalance.sub(_unbondedMaltBalance);
  }

  /* Timelock only methods */
  function setNewRewarder(address rewarder) external onlyTimelock {
    _setupRole(REWARDER_ROLE, rewarder);
  }

  function removeRewarder(address rewarder) external onlyTimelock {
    revokeRole(REWARDER_ROLE, rewarder);
  }

  /* Internal helpers */
  function _addLiquidity(
    uint256 liquidityMalt,
    uint256 liquidityReward,
    bool rebalanceMalt,
    uint256 otherQuantity
  ) internal {
    // rebalanceMalt defines whether we may need to transfer back malt or reward tokens to the caller
    // otherQuantity is how much of the other token's rewards is used to make up the liquidity.
    // As opposed to being transfered in by the user.
    ReinvestRebalance memory rebalance = ReinvestRebalance({
      rewardRemoval: 0,
      maltRemoval: 0,
      excess: 0,
      minMalt: liquidityMalt.mul(95).div(100),
      minReward: liquidityReward.mul(95).div(100)
    });

    malt.approve(address(router), liquidityMalt);
    rewardToken.approve(address(router), liquidityReward);

    (
      uint256 amountMalt,
      uint256 amountReward,
      uint256 liquidity
    ) = router.addLiquidity(
      address(malt),
      address(rewardToken),
      liquidityMalt,
      liquidityReward,
      rebalance.minMalt, // 5% slippage
      rebalance.minReward, // 5% slippage
      address(this),
      now
    );

    if (rebalanceMalt) {
      rebalance.rewardRemoval = amountReward;
      rebalance.maltRemoval = otherQuantity;

      if (amountMalt < liquidityMalt) {
        rebalance.excess = liquidityMalt.sub(amountMalt);

        if (amountMalt > otherQuantity) {
          // Transfer excess back
          malt.safeTransfer(msg.sender, rebalance.excess);
        } else {
          // Not all of otherQuantity was used so don't remove it all
          rebalance.maltRemoval = amountMalt;
          malt.safeTransfer(msg.sender, liquidityMalt.sub(otherQuantity));
        }
      }
    } else {
      rebalance.rewardRemoval = otherQuantity;
      rebalance.maltRemoval = amountMalt;

      if (amountReward < liquidityReward) {
        rebalance.excess = liquidityReward.sub(amountReward);

        if (amountReward > otherQuantity) {
          // Transfer excess back
          rewardToken.safeTransfer(msg.sender, rebalance.excess);
        } else {
          // Not all of desiredReward was used so don't remove it all
          rebalance.rewardRemoval = amountReward;
          rewardToken.safeTransfer(msg.sender, liquidityReward.sub(otherQuantity));
        }
      }
    }

    _updateBond(rebalance.rewardRemoval, rebalance.maltRemoval, liquidity);
  }

  function _clearSubsidizedLP(address account, uint256 bondedBalance) internal {
    uint256 subsidies = balanceOfSubsidizedLP(account);

    if (subsidies > 0) {
      removeFromEpochBonding(account, subsidies);

      uint256 lessStakePadding = balanceOfStakePadding(account).mul(subsidies).div(bondedBalance.add(subsidies));
      uint256 lessMaltStakePadding = balanceOfMaltStakePadding(account).mul(subsidies).div(bondedBalance.add(subsidies));

      removeFromStakePadding(account, lessStakePadding, lessMaltStakePadding, "Insufficient stake padding");

      removeFromBonded(account, subsidies, "LP: Insufficient bonded balance");
      removeFromSubsidizedLP(account, subsidies, "Subsidized LP: Insufficient balance");

      stakeToken.safeTransfer(treasuryMultisig, subsidies);
      balanceCheck();
    }
  }

  function _verifyReinvest(uint256 maltAmount, uint256 rewardAmount) internal {
    // rewardLiquidity is the amount of reward to reinvest
    // desiredMalt is the amount of malt rewards to also put towards the reinvest.
    // The rest of the malt will need to be transfered from the accounts wallet
    (uint256 rewardEarned, uint256 maltEarned) = earned(msg.sender);

    require(rewardAmount <= rewardEarned, "Cannot reinvest more than you have earned");
    require(maltAmount <= maltEarned, "Cannot reinvest more than you have earned");
  }

  function _getOptimalLiquidity(address tokenA, address tokenB, uint256 liquidityB) internal returns (uint256 liquidityA){
    (uint256 reservesA, uint256 reservesB) = UniswapV2Library.getReserves(
      uniswapV2Factory,
      tokenA,
      tokenB
    );

    liquidityA = UniswapV2Library.quote(
      liquidityB,
      reservesB,
      reservesA
    );
  }

  function _updateBond(uint256 amountReward, uint256 maltRemoval, uint256 liquidity) internal {
    // Remove from reward and add equivalent to stake padding.
    // Conservation of reward space volume
    // This reward now exists in LP tokens instead
    addToStakePadding(msg.sender, amountReward, maltRemoval);
    _declaredBalance = _declaredBalance.sub(amountReward);
    _declaredMaltBalance = _declaredMaltBalance.sub(maltRemoval);

    updateCurrentEpochTotalRewards();

    uint256 currentEpoch = epoch();

    addToEpochWithdraw(msg.sender, amountReward, maltRemoval);

    _handleStakePadding(msg.sender, liquidity);

    addToBonded(msg.sender, liquidity);

    epochRewards[currentEpoch].totalBonded = _globals.bonded;

    balanceCheck();

    emit Bond(msg.sender, liquidity);
  }

  function _handleStakePadding(address account, uint256 amount) internal {
    // Bond the new LP tokens to the user
    addToEpochBonding(account, amount);
    
    uint256 totalRewardedWithStakePadding = totalRewarded().add(totalStakePadding());
    uint256 totalMaltWithStakePadding = totalMaltRewarded().add(totalMaltStakePadding());

    uint256 newStakePadding = totalBonded() == 0 ?
      totalRewarded() == 0 ? amount.mul(INITIAL_STAKE_SHARE_MULTIPLE) : 0 :
      totalRewardedWithStakePadding.mul(amount).div(totalBonded());

    uint256 newMaltStakePadding = totalBonded() == 0 ?
      totalMaltRewarded() == 0 ? amount.mul(INITIAL_STAKE_SHARE_MULTIPLE) : 0 :
      totalMaltWithStakePadding.mul(amount).div(totalBonded());
    
    addToStakePadding(account, newStakePadding, newMaltStakePadding);

    if (balanceOfBonded(account) == 0) {
      userState[account].bondedEpoch = epoch();
    }
  }

  function addToStakePadding(address account, uint256 amount, uint256 amountMalt) internal {
    userState[account].stakePadding = userState[account].stakePadding.add(amount);
    userState[account].maltStakePadding = userState[account].maltStakePadding.add(amountMalt);
    _globalStakePadding = _globalStakePadding.add(amount);
    _globalMaltStakePadding = _globalMaltStakePadding.add(amountMalt);

    uint256 currentEpoch = epoch();

    epochRewards[currentEpoch].stakePadding = _globalStakePadding;
    epochRewards[currentEpoch].maltStakePadding = _globalMaltStakePadding;

    userState[account].epochStakePadding[currentEpoch].reward = userState[account].epochStakePadding[currentEpoch].reward + amount;
    userState[account].epochStakePadding[currentEpoch].malt = userState[account].epochStakePadding[currentEpoch].malt + amountMalt;
  }

  function removeFromStakePadding(address account, uint256 amount, uint256 amountMalt, string memory reason) internal {
    userState[account].stakePadding = userState[account].stakePadding.sub(amount, reason);
    userState[account].maltStakePadding = userState[account].maltStakePadding.sub(amountMalt, reason);
    _globalStakePadding = _globalStakePadding.sub(amount, reason);
    _globalMaltStakePadding = _globalMaltStakePadding.sub(amountMalt, reason);

    uint256 currentEpoch = epoch();

    epochRewards[currentEpoch].stakePadding = _globalStakePadding;
    epochRewards[currentEpoch].maltStakePadding = _globalMaltStakePadding;

    // These are signed ints. It should be allowed to go negative
    userState[account].epochStakePadding[currentEpoch].reward = userState[account].epochStakePadding[currentEpoch].reward - amount;
    userState[account].epochStakePadding[currentEpoch].malt = userState[account].epochStakePadding[currentEpoch].malt - amountMalt;
  }

  function addToEpochBonding(address account, uint256 amount) internal {
    uint256 currentEpoch = epoch();
    userState[account].bondEpochs.push(currentEpoch);
    userState[account].epochBonds[currentEpoch] = userState[account].epochBonds[currentEpoch].add(amount);
  }

  function removeFromEpochBonding(address account, uint256 amount) internal {
    uint256 currentEpoch = epoch();
    userState[account].unbondEpochs.push(currentEpoch);
    userState[account].epochUnbonds[currentEpoch] = userState[account].epochUnbonds[currentEpoch].add(amount);
  }

  function updateCurrentEpochTotalRewards() internal {
    uint256 currentEpoch = epoch();

    epochRewards[currentEpoch].totalReward = _declaredBalance;
    epochRewards[currentEpoch].totalMaltReward = _declaredMaltBalance;
  }

  function addToEpochWithdraw(address account, uint256 amountReward, uint256 amountMalt) internal {
    uint256 currentEpoch = epoch();
    userState[account].withdrawEpochs.push(currentEpoch);
    userState[account].epochWithdraws[currentEpoch].reward = userState[account].epochWithdraws[currentEpoch].reward.add(amountReward);
    userState[account].epochWithdraws[currentEpoch].malt = userState[account].epochWithdraws[currentEpoch].malt.add(amountMalt);
  }

  function _forfeit(uint256 forfeited) internal {
    _declaredBalance = _declaredBalance.sub(forfeited);

    rewardToken.safeTransfer(treasuryMultisig, forfeited);

    emit Forfeit(msg.sender, address(rewardToken), forfeited);
  }

  function _forfeitMalt(uint256 forfeited) internal {
    _declaredMaltBalance = _declaredMaltBalance.sub(forfeited);

    malt.safeTransfer(treasuryMultisig, forfeited);

    emit Forfeit(msg.sender, address(malt), forfeited);
  }
  
  function _checkForForfeit(uint256 amount, uint256 bondedBalance) internal {
    (uint256 rewardEarned, uint256 maltEarned) = earned(msg.sender);
    uint256 amountClaimable = rewardEarned.mul(amount).div(bondedBalance).sub(userState[msg.sender].unbondedBalance);
    uint256 maltClaimable = maltEarned.mul(amount).div(bondedBalance).sub(userState[msg.sender].unbondedMaltBalance);
    uint256 currentEpoch = epoch();

    uint256 allocation = balanceOfRewards(msg.sender).mul(amount).div(bondedBalance);
    uint256 maltAllocation = balanceOfMaltRewards(msg.sender).mul(amount).div(bondedBalance);

    uint256 forfeited = allocation.sub(amountClaimable);

    if (forfeited > 0) {
      _forfeit(forfeited);
      userState[msg.sender].epochForfeits[currentEpoch].reward = userState[msg.sender].epochForfeits[currentEpoch].reward + forfeited;
    }

    uint256 forfeitedMalt = maltAllocation.sub(maltClaimable);

    if (forfeitedMalt > 0) {
      _forfeitMalt(forfeitedMalt);
      userState[msg.sender].epochForfeits[currentEpoch].malt = userState[msg.sender].epochForfeits[currentEpoch].malt + forfeitedMalt;
    }

    if (forfeited > 0 || forfeitedMalt > 0) {
      addToStakePadding(msg.sender, forfeited, forfeitedMalt);
    }

    addToUnbondedBalance(msg.sender, amountClaimable, maltClaimable);

    updateCurrentEpochTotalRewards();
  }

  function _epochEarnedRewards(
    address account,
    uint256 epoch,
    uint256 stakePadding,
    uint256 bondedBalance
  ) private view returns (uint256, uint256) {
    if (epochRewards[epoch].reward == 0 || bondedBalance == 0) {
      return (0, 0);
    }

    uint256 previousEpoch = epoch > 0 ? epoch - 1 : 0;
    uint256 epochMaturity = block.timestamp - getEpochStartTime(epoch);

    uint256 globalBondedTotal = epochRewards[previousEpoch].totalBonded;
    if (globalBondedTotal == 0) {
      return (0, 0);
    }

    uint256 balanceOfRewards = epochRewards[epoch].reward.mul(bondedBalance).div(globalBondedTotal);

    return (balanceOfRewards.mul(epochMaturity).div(payoutDuration * epochLength()), balanceOfRewards);
  }

  function _epochBalanceOfRewards(
    address account,
    uint256 epoch,
    uint256 stakePadding,
    uint256 bondedBalance
  ) private view returns (uint256) {
    if (epochRewards[epoch].totalReward == 0 || bondedBalance == 0) {
      return 0;
    }

    uint256 previousEpoch = epoch > 0 ? epoch - 1 : 0;

    uint256 globalBondedTotal = epochRewards[previousEpoch].totalBonded;
    if (globalBondedTotal == 0) {
      return 0;
    }

    uint256 totalRewardedWithStakePadding = epochRewards[epoch].totalReward + epochRewards[previousEpoch].stakePadding;
    uint256 balanceOfRewardedWithStakePadding = totalRewardedWithStakePadding
      .mul(bondedBalance)
      .div(globalBondedTotal);
    
    if (balanceOfRewardedWithStakePadding > stakePadding) {
      return balanceOfRewardedWithStakePadding - stakePadding;
    }

    return 0;
  }

  function _epochEarnedMaltRewards(
    address account,
    uint256 epoch,
    uint256 stakePadding,
    uint256 bondedBalance
  ) private view returns (uint256, uint256) {
    if (epochRewards[epoch].maltReward == 0 || bondedBalance == 0) {
      return (0, 0);
    }

    uint256 previousEpoch = epoch > 0 ? epoch - 1 : 0;
    uint256 epochMaturity = block.timestamp - getEpochStartTime(epoch);

    uint256 globalBondedTotal = epochRewards[previousEpoch].totalBonded;
    if (globalBondedTotal == 0) {
      return (0, 0);
    }

    uint256 balanceOfRewards = epochRewards[epoch].maltReward.mul(bondedBalance).div(globalBondedTotal);

    return (balanceOfRewards.mul(epochMaturity).div(payoutDuration * epochLength()), balanceOfRewards);
  }

  function addToUnbondedBalance(address account, uint256 amount, uint256 amountMalt) internal {
    _unbondedBalance = _unbondedBalance + amount;
    _unbondedMaltBalance = _unbondedMaltBalance + amountMalt;

    userState[account].unbondedBalance = userState[account].unbondedBalance + amount;
    userState[account].unbondedMaltBalance = userState[account].unbondedMaltBalance + amountMalt;
  }

  function removeFromUnbondedBalance(address account, uint256 amount, uint256 amountMalt) internal {
    uint256 rewardRemoval = 0;
    uint256 maltRemoval = 0;

    if (amount > userState[account].unbondedBalance) {
      rewardRemoval = userState[account].unbondedBalance;
      userState[account].unbondedBalance = 0;
    } else {
      rewardRemoval = amount;
      userState[account].unbondedBalance = userState[account].unbondedBalance.sub(amount);
    }

    if (amountMalt > userState[account].unbondedMaltBalance) {
      maltRemoval = userState[account].unbondedMaltBalance;
      userState[account].unbondedMaltBalance = 0;
    } else {
      maltRemoval = amountMalt;
      userState[account].unbondedMaltBalance = userState[account].unbondedMaltBalance.sub(amountMalt);
    }

    _unbondedBalance = _unbondedBalance.sub(rewardRemoval);
    _unbondedMaltBalance = _unbondedMaltBalance.sub(maltRemoval);
  }

  function _epochBalanceOfMaltRewards(
    address account,
    uint256 epoch,
    uint256 stakePadding,
    uint256 bondedBalance
  ) private view returns (uint256) {
    if (epochRewards[epoch].totalMaltReward == 0 || bondedBalance == 0) {
      return 0;
    }

    uint256 previousEpoch = epoch > 0 ? epoch - 1 : 0;

    uint256 globalBondedTotal = epochRewards[previousEpoch].totalBonded;
    if (globalBondedTotal == 0) {
      return 0;
    }

    uint256 totalMaltRewardedWithStakePadding = epochRewards[epoch].totalMaltReward + epochRewards[previousEpoch].maltStakePadding;
    uint256 balanceOfMaltRewardedWithStakePadding = totalMaltRewardedWithStakePadding
      .mul(bondedBalance)
      .div(globalBondedTotal);

    if (balanceOfMaltRewardedWithStakePadding > stakePadding) {
      return balanceOfMaltRewardedWithStakePadding - stakePadding;
    }

    return 0;
  }
  
  modifier bondingValidityCheck(uint256 amount) {
    require(amount > 0, "Cannot unbond 0");

    // Check if the user has any malt locked due to governance voting
    uint256 lockedMalt = dao.getLockedMalt(msg.sender);
    (uint256 accountTotalBondedValue,) = realValueOfBonded(msg.sender);
    (uint256 realMaltValue,) = realValueOfLPToken(amount);

    // Users total available balance must be gte the value they are trying to withdraw
    require(accountTotalBondedValue.sub(lockedMalt) >= realMaltValue, "Insufficient balance to unbond");

    _;
  }

  modifier updateReward(address account) {
    advance();
    _;
  }

  modifier checkStart() {
    require(
      block.timestamp >= startTime,
      "Can't use pool before start time"
    );
    _;
  }

  modifier onlyRewarder() {
    require(
      hasRole(
        REWARDER_ROLE,
        _msgSender()
      ),
      "Must have rewarder role"
    );
    _;
  }

  modifier onlyTimelock() {
    require(
      hasRole(
        ADMIN_ROLE,
        _msgSender()
      ),
      "Must have admin role"
    );
    _;
  }
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
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

pragma solidity >=0.6.0 <0.8.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

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
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
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
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function _setupDecimals(uint8 decimals_) internal {
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.6;

interface IDAO {
  function epoch() external view returns (uint256);
  function epochLength() external view returns (uint256);
  function genesisTime() external view returns (uint256);
  function getEpochStartTime(uint256 _epoch) external view returns (uint256);
  function getLockedMalt(address account) external view returns (uint256);
}

pragma solidity >=0.6.6;

interface IStabilizerNode {
  function initialize(address dao) external;
  function requiredMint() external;
  function distributeSupply(uint256 amount) external;
  function liquidityMine() external view returns (address);
  function requestMint(uint256 amount) external;
  function requestBurn(uint256 amount) external;
  function currentAuctionId() external view returns (uint256);
  function claimableArbitrageRewards() external view returns (uint256);
  function auctionPreBurn(
    uint256 maxSpend,
    uint256 rRatio,
    uint256 decimals
  ) external returns (
    uint256 initialReservePledge,
    uint256 initialBurn
  );
  function getAuctionCommitments(uint256 _id) external view returns (uint256 commitments, uint256 maxCommitments);
}

pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

import "@openzeppelin/contracts/math/SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

