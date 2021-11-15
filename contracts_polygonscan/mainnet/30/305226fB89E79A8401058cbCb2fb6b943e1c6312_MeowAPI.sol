pragma solidity 0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "./IUniswapV2Router02.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IVaultConfig.sol";
import "../../token/interfaces/IMeowMining.sol";
import "../interfaces/IWorker.sol";
import "../interfaces/ISushiWorker.sol";
import "../interfaces/IQuickWorker.sol";
import "../interfaces/ITripleSlopeModel.sol";
import "../interfaces/IMiniChefV2.sol";
import "../interfaces/IRewarder.sol";
import "../interfaces/IStakingRewardsFactory.sol";
import "../interfaces/IStakingRewards.sol";
import "../../utils/Math.sol";

contract MeowAPI {
  using SafeMath for uint256;
  address public meowToken;
  address public usdcToken;
  address public wMatic;
  IUniswapV2Router02 public sushiRouter;
  IUniswapV2Factory public sushiFactory;
  IMiniChefV2 public miniChef;
  IUniswapV2Router02 public quickRouter;
  IUniswapV2Factory public quickFactory;
  IStakingRewardsFactory public stakingRewardsFactory;
  IMeowMining public meowMining;
  ITripleSlopeModel public interest;

  constructor(
    IMeowMining _meowMining,
    ITripleSlopeModel _interest,
    IUniswapV2Router02 _sushiRouter,
    IMiniChefV2 _miniChef,
    IUniswapV2Router02 _quickRouter,
    IStakingRewardsFactory _stakingRewardsFactory,
    address _meowToken,
    address _usdcToken
  ) public {
    meowMining = _meowMining;
    interest = _interest;
    sushiRouter = _sushiRouter;
    sushiFactory = IUniswapV2Factory(_sushiRouter.factory());
    miniChef = _miniChef;
    quickRouter = _quickRouter;
    quickFactory = IUniswapV2Factory(_quickRouter.factory());
    stakingRewardsFactory = _stakingRewardsFactory;
    wMatic = _sushiRouter.WETH();
    meowToken = _meowToken;
    usdcToken = _usdcToken;
  }

  // ===== Vault function ===== //

  // Return MATIC balance for the given user.
  function getMaticBalance(address _user) public view returns (uint256) {
    return address(_user).balance;
  }

  // Return the given Token balance for the given user.
  function getTokenBalance(address _vault, address _user) public view returns (uint256) {
    if (IVault(_vault).token() == IVaultConfig(IVault(_vault).config()).getWrappedNativeAddr())
      return getMaticBalance(_user);
    return IERC20(IVault(_vault).token()).balanceOf(_user);
  }

  // Return interest bearing token balance for the given user.
  function balanceOf(address _vault, address _user) public view returns (uint256) {
    return IERC20(_vault).balanceOf(_user);
  }

  // Return ibToken price for the given Station.
  function ibTokenPrice(address _vault) public view returns (uint256) {
    uint256 decimals = uint256(IERC20(_vault).decimals());
    if (totalSupply(_vault) == 0) return 0;
    return totalToken(_vault).mul(10**decimals).div(totalSupply(_vault));
  }

  // Return total debt for the given Vault.
  function vaultDebtVal(address _vault) public view returns (uint256) {
    return IVault(_vault).vaultDebtVal();
  }

  // Return the total token entitled to the token holders. Be careful of unaccrued interests.
  function totalToken(address _vault) public view returns (uint256) {
    return IVault(_vault).totalToken();
  }

  // Return total supply for the given Vault.
  function totalSupply(address _vault) public view returns (uint256) {
    return IERC20(_vault).totalSupply();
  }

  // Return utilization for the given Vault.
  function utilization(address _vault) public view returns (uint256) {
    uint256 debt = vaultDebtVal(_vault);
    if (debt == 0) return 0;
    address token = IVault(_vault).token();
    uint256 balance = IERC20(token).balanceOf(_vault).sub(IVault(_vault).reservePool());
    return interest.getUtilization(debt, balance);
  }

  // Return interest rate per year for the given Vault.
  function getInterestRate(address _vault) public view returns (uint256) {
    uint256 debt = vaultDebtVal(_vault);
    if (debt == 0) return 0;
    address token = IVault(_vault).token();
    uint256 balance = IERC20(token).balanceOf(_vault).sub(IVault(_vault).reservePool());
    uint8 decimals = IERC20(_vault).decimals();
    return interest.getInterestRate(debt, balance, decimals).div(1e18);
  }

  // Return ibToken APY for the given Vault.
  function ibTokenApy(address _vault) public view returns (uint256) {
    uint256 decimals = uint256(IERC20(_vault).decimals());
    return getInterestRate(_vault).mul(utilization(_vault)).div(10**decimals);
  }

  // Return total Token value for the given user.
  function totalTokenValue(address _vault, address _user) public view returns (uint256) {
    if (totalSupply(_vault) == 0) return 0;
    return balanceOf(_vault, _user).mul(totalToken(_vault)).div(totalSupply(_vault));
  }

  // Return MeowMining pool id for borrower.
  function getMeowMiningPoolId(address _vault) public view returns (uint256) {
    return IVault(_vault).meowMiningPoolId();
  }

  // Return next position id for the given Vault.
  function nextPositionID(address _vault) public view returns (uint256) {
    return IVault(_vault).nextPositionID();
  }

  // Return position info for the given Vault and position id.
  function positions(address _vault, uint256 _id)
    public
    view
    returns (
      address,
      address,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return IVault(_vault).positions(_id);
  }

  // Return Token value and debt of the given position.
  function positionInfo(address _vault, uint256 _id) public view returns (uint256, uint256) {
    return IVault(_vault).positionInfo(_id);
  }

  // Return reward for kill position.
  function getKillBps(address _vault) public view returns (uint256) {
    return IVaultConfig(IVault(_vault).config()).getKillBps();
  }

  // Return killFactor for the given worker.
  function killFactor(address _worker, uint256 _debt) public view returns (uint256) {
    return IVaultConfig(IVault(IWorker(_worker).operator()).config()).killFactor(_worker, _debt);
  }

  // Return total debt for the given user on the given Vault.
  function myPositionDebt(address _vault, address _user) public view returns (uint256) {
    uint256 myDebt = 0;
    uint256 length = nextPositionID(_vault).sub(1);
    for (uint256 i = 1; i <= length; i++) {
      (, uint256 _totalDebt) = positionInfo(_vault, i);
      (, address _owner, , , , , , , ) = positions(_vault, i);
      if (_owner == _user) {
        myDebt += _totalDebt;
      }
    }
    return myDebt;
  }

  // Return percent debt of the given user on the given Vault.
  function myPercentDebt(address _vault, address _user) public view returns (uint256) {
    uint256 myDebt = myPositionDebt(_vault, _user);
    uint256 totalDebt = vaultDebtVal(_vault);
    if (totalDebt == 0) return 0;
    return myDebt.mul(uint256(100)).mul(1e18).div(totalDebt);
  }

  // =============================== //

  // ===== MeowMining function ===== //

  // Return MEOW per second.
  function meowPerSecond() public view returns (uint256) {
    return meowMining.meowPerSecond();
  }

  // Return total allocation point.
  function totalAllocPoint() public view returns (uint256) {
    return meowMining.totalAllocPoint();
  }

  // Return userInfo.
  function userInfo(uint256 _pid, address _user)
    public
    view
    returns (
      uint256,
      uint256,
      address,
      uint256,
      uint256,
      uint256
    )
  {
    return meowMining.userInfo(_pid, _user);
  }

  // Return pool info.
  function poolInfo(uint256 _pid)
    public
    view
    returns (
      address,
      uint256,
      uint256,
      uint256
    )
  {
    return meowMining.poolInfo(_pid);
  }

  // Return total stake token for given pool.
  function totalStake(uint256 _pid) public view returns (uint256) {
    (address stakeToken, , , ) = poolInfo(_pid);
    return IERC20(stakeToken).balanceOf(address(meowMining));
  }

  // Return allocation point for given pool.
  function _allocPoint(uint256 _pid) public view returns (uint256) {
    (, uint256 allocPoint, , ) = poolInfo(_pid);
    return allocPoint;
  }

  // Return stake token amount of the given user.
  function userStake(uint256 _pid, address _user) public view returns (uint256) {
    (uint256 amount, , , , , ) = userInfo(_pid, _user);
    return amount;
  }

  // Return percent stake amount of the given user.
  function percentStake(uint256 _pid, address _user) public view returns (uint256) {
    uint256 _userStake = userStake(_pid, _user);
    uint256 _totalStake = totalStake(_pid);
    if (_totalStake == 0) return uint256(0);
    return _userStake.mul(uint256(100)).mul(1e18).div(_totalStake);
  }

  // Return pending MeowToken for the given user.
  function pendingMeow(uint256 _pid, address _user) public view returns (uint256) {
    return meowMining.pendingMeow(_pid, _user);
  }

  // Return MEOW lockedAmount.
  function meowLockedAmount(uint256 _pid, address _user) public view returns (uint256) {
    (, , , uint256 lockedAmount, , ) = userInfo(_pid, _user);
    return lockedAmount;
  }

  // Return pending release MEOW for the given user.
  function availableUnlock(uint256 _pid, address _user) public view returns (uint256) {
    return meowMining.availableUnlock(_pid, _user);
  }

  // Return meowPerSecond for given pool
  function meowPerSecondInPool(uint256 _pid) public view returns (uint256) {
    uint256 total = totalAllocPoint();
    if (total == 0) return 0;
    return _allocPoint(_pid).mul(1e18).mul(1e18).div(total.mul(1e18)).mul(meowPerSecond()).div(1e18);
  }

  // Return reward per year for given pool.
  function rewardPerYear(uint256 _pid) public view returns (uint256) {
    return meowPerSecondInPool(_pid).mul(365 days);
  }

  // Return reward APY.
  function rewardAPY(address _vault, uint256 _pid) public view returns (uint256) {
    uint256 decimals;
    address meowLp = quickFactory.getPair(wMatic, meowToken);
    (address stakeToken, , , ) = meowMining.poolInfo(_pid);
    if (stakeToken == meowLp) {
      decimals = uint256(IERC20(meowLp).decimals());
    } else {
      decimals = uint256(IERC20(_vault).decimals());
    }
    uint256 numerator = rewardPerYear(_pid).mul(meowPrice()).mul(uint256(100));
    uint256 price = getTokenPrice(_vault, _pid);
    uint256 denominator = totalStake(_pid).mul(price).div(10**decimals);
    return denominator == 0 ? 0 : numerator.div(denominator);
  }

  // Return reward APY of borrower for the given Vault.
  function borrowerRewardAPY(address _vault) public view returns (uint256) {
    uint256 _pid = IVault(_vault).meowMiningPoolId();
    uint256 decimals = uint256(IERC20(_vault).decimals());
    uint256 numerator = rewardPerYear(_pid).mul(meowPrice()).mul(uint256(100));
    uint256 price = baseTokenPrice(_vault);
    uint256 denominator = vaultDebtVal(_vault).mul(price).div(10**decimals);
    return denominator == 0 ? 0 : numerator.div(denominator);
  }

  // ========================== //

  // ===== Price function ===== //

  // Return Token per MATIC.
  function getTokenPerMatic(address _lp) public view returns (uint256) {
    (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(_lp).getReserves();
    string memory symbol = IERC20(IUniswapV2Pair(_lp).token0()).symbol();
    return
      keccak256(bytes(symbol)) == keccak256(bytes("WMATIC"))
        ? uint256(reserve1).mul(1e18).div(uint256(reserve0))
        : uint256(reserve0).mul(1e18).div(uint256(reserve1));
  }

  // Return MATIC per Token.
  function getMaticPerToken(address _lp) public view returns (uint256) {
    (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(_lp).getReserves();
    string memory symbol = IERC20(IUniswapV2Pair(_lp).token0()).symbol();
    return
      keccak256(bytes(symbol)) == keccak256(bytes("WMATIC"))
        ? uint256(reserve0).mul(10**uint256(IERC20(IUniswapV2Pair(_lp).token1()).decimals())).div(uint256(reserve1))
        : uint256(reserve1).mul(10**uint256(IERC20(IUniswapV2Pair(_lp).token0()).decimals())).div(uint256(reserve0));
  }

  // Return MeowToken price in USDC.
  function meowPrice() public view returns (uint256) {
    if (quickFactory.getPair(wMatic, meowToken) == address(0)) return 0;
    uint256 meowPerMatic = getTokenPerMatic(quickFactory.getPair(wMatic, meowToken));
    uint256 usdcPerMatic = getTokenPerMatic(quickFactory.getPair(wMatic, usdcToken));
    return usdcPerMatic.mul(1e18).div(meowPerMatic);
  }

  // Return BaseToken price in USDC for the given Vault.
  function baseTokenPrice(address _vault) public view returns (uint256) {
    address baseToken = IVault(_vault).token();
    uint256 decimals = uint256(IERC20(_vault).decimals());
    uint256 usdcPerMaticQuick = getTokenPerMatic(quickFactory.getPair(wMatic, usdcToken));
    uint256 usdcPerMaticSushi = getTokenPerMatic(sushiFactory.getPair(wMatic, usdcToken));
    address baseTokenLPQuick;
    address baseTokenLPSushi;
    if (baseToken == wMatic) return (usdcPerMaticQuick + usdcPerMaticSushi) / 2;
    baseTokenLPQuick = quickFactory.getPair(baseToken, wMatic);
    baseTokenLPSushi = sushiFactory.getPair(baseToken, wMatic);
    uint256 tokenPerMaticQuick = getTokenPerMatic(baseTokenLPQuick);
    uint256 tokenPerMaticSushi = getTokenPerMatic(baseTokenLPSushi);
    return
      ((usdcPerMaticQuick.mul(10**decimals).div(tokenPerMaticQuick)) +
        (usdcPerMaticSushi.mul(10**decimals).div(tokenPerMaticSushi))) / 2;
  }

  // Return token value.
  function getTokenPrice(address _vault, uint256 _pid) public view returns (uint256) {
    uint256 price;
    uint256 decimals = uint256(IERC20(_vault).decimals());
    uint256 usdcPerMatic = getTokenPerMatic(quickFactory.getPair(wMatic, usdcToken));
    address meowLp = quickFactory.getPair(wMatic, meowToken);
    (address stakeToken, , , ) = meowMining.poolInfo(_pid);
    if (stakeToken == meowLp) return IERC20(wMatic).balanceOf(meowLp).mul(uint256(2)).mul(usdcPerMatic).div(1e18);
    price = ibTokenPrice(_vault).mul(baseTokenPrice(_vault)).div(10**decimals);
    return price;
  }

  // =========================== //

  // ===== Worker function ===== //

  // Return LP Token of the given worker.
  function getLpToken(address _worker) public view returns (address) {
    return address(IWorker(_worker).lpToken());
  }

  // Return BaseToken of the given  worker.
  function getBaseToken(address _worker) public view returns (address) {
    return IWorker(_worker).baseToken();
  }

  // Return FarmingToken of the given  worker.
  function getFarmingToken(address _worker) public view returns (address) {
    return IWorker(_worker).farmingToken();
  }

  // Return the reward bounty for calling reinvest operation of the given worker.
  function getReinvestBounty(address _worker) public view returns (uint256) {
    return IWorker(_worker).reinvestBountyBps();
  }

  // Return BaseToken amount in the LP of the given worker.
  function getLPValue(address _worker) public view returns (uint256) {
    address baseToken = IWorker(_worker).baseToken();
    address vault = IWorker(_worker).operator();
    uint256 decimals = uint256(IERC20(vault).decimals());
    return
      (IERC20(baseToken).balanceOf(getLpToken(_worker))).mul(uint256(2)).mul(baseTokenPrice(vault)).div(10**decimals);
  }

  // ===== Sushi Worker function ===== //

  // Return pool id on MasterChef of the given Sushi worker.
  function getPoolIdSushi(address _worker) public view returns (uint256) {
    return ISushiWorker(_worker).pid();
  }

  // Return MasterChef of the given Sushi worker.
  function getMasterChef(address _worker) public view returns (address) {
    return address(ISushiWorker(_worker).masterChef());
  }

  // Return Reward token address of MasterChef for the given Sushi worker.
  function getSushiAddr(address _worker) public view returns (address) {
    return ISushiWorker(_worker).sushi();
  }

  // Return StakeToken amount of the given Sushi worker on MasterChef.
  function getWorkerStakeAmountSushi(address _worker) public view returns (uint256) {
    (uint256 amount, ) = miniChef.userInfo(getPoolIdSushi(_worker), _worker);
    return amount;
  }

  // Return rewarder of the given worker.
  function getRewarder(address _worker) public view returns (address) {
    return miniChef.rewarder(getPoolIdSushi(_worker));
  }

  // Return pending Token from rewarder for the given Sushi worker.
  function getPendingToken(address _worker) public view returns (address) {
    (IERC20[] memory _rewardTokens, ) = IRewarder(getRewarder(_worker)).pendingTokens(
      getPoolIdSushi(_worker),
      _worker,
      0
    );
    return address(_rewardTokens[0]);
  }

  // Return pending reward from rewarder for the given Sushi worker.
  function getPendingReward(address _worker) public view returns (uint256) {
    (, uint256[] memory rewardAmounts) = IRewarder(getRewarder(_worker)).pendingTokens(
      getPoolIdSushi(_worker),
      _worker,
      0
    );
    return rewardAmounts[0];
  }

  // Return pending Sushi value.
  function getPendingSushiValue(address _worker) public view returns (uint256) {
    return
      (miniChef.pendingSushi(getPoolIdSushi(_worker), _worker).add(IERC20(getSushiAddr(_worker)).balanceOf(_worker)))
        .mul(getSushiPrice())
        .div(1e18);
  }

  // Return pending reward value.
  function getPendingRewardValue(address _worker) public view returns (uint256) {
    uint256 pid = getPoolIdSushi(_worker);
    return
      (getPendingReward(_worker).add(IERC20(getPendingToken(_worker)).balanceOf(_worker))).mul(getRewardPrice(pid)).div(
        10**rewardTokenDecimals(pid)
      );
  }

  // Return portion LP value of given Sushi worker.
  function getPortionLPValueSushi(address _workewr) public view returns (uint256) {
    return
      getWorkerStakeAmountSushi(_workewr)
        .mul(1e18)
        .div(IUniswapV2Pair(getLpToken(_workewr)).totalSupply())
        .mul(getLPValue(_workewr))
        .div(1e18);
  }

  // ================================= //

  // ===== Quick Worker function ===== //

  // Return Reward token address for the given Quick worker.
  function getQuickAddr(address _worker) public view returns (address) {
    return IQuickWorker(_worker).quick();
  }

  // Return address of StakingRewards contract for the given Quick worker.
  function getStakingRewards(address _worker) public view returns (address) {
    return address(IQuickWorker(_worker).stakingRewards());
  }

  // Return StakeToken amount of the given Quick worker on StakingRewards.
  function getWorkerStakeAmountQuick(address _worker) public view returns (uint256) {
    return IStakingRewards(getStakingRewards(_worker)).balanceOf(_worker);
  }

  // Return pending Quick value.
  function getPendingQuickValue(address _worker) public view returns (uint256) {
    return IStakingRewards(getStakingRewards(_worker)).earned(_worker).mul(getQuickPrice()).div(1e18);
  }

  // Return portion LP value of given Quick worker.
  function getPortionLPValueQuick(address _workewr) public view returns (uint256) {
    return
      getWorkerStakeAmountQuick(_workewr)
        .mul(1e18)
        .div(IUniswapV2Pair(getLpToken(_workewr)).totalSupply())
        .mul(getLPValue(_workewr))
        .div(1e18);
  }

  // ================================= //

  // ================================= //

  // ===== Sushiswap function ===== //

  // Return Sushi price in USDC.
  function getSushiPrice() public view returns (uint256) {
    address sushi = miniChef.SUSHI();
    uint256 sushiPerMatic = getTokenPerMatic(sushiFactory.getPair(wMatic, sushi));
    uint256 usdcPerMatic = getTokenPerMatic(sushiFactory.getPair(wMatic, usdcToken));
    return usdcPerMatic.mul(1e18).div(sushiPerMatic);
  }

  // Return Sushi per second.
  function sushiPerSecond() public view returns (uint256) {
    return miniChef.sushiPerSecond();
  }

  // Return total allocation point of miniChef.
  function totalAllocPointSushi() public view returns (uint256) {
    return miniChef.totalAllocPoint();
  }

  // Return poolInfo of given pool in MiniChef.
  function poolInfoSushi(uint256 _pid)
    public
    view
    returns (
      uint128,
      uint64,
      uint64
    )
  {
    return miniChef.poolInfo(_pid);
  }

  // Return allocation point for given pool in miniChef.
  function allocPointSushi(uint256 _pid) public view returns (uint256) {
    (, , uint64 allocPoint) = poolInfoSushi(_pid);
    return uint256(allocPoint);
  }

  // Return sushiPerSecond for given pool
  function sushiPerSecondInPool(uint256 _pid) public view returns (uint256) {
    uint256 total = totalAllocPointSushi();
    if (total == 0) return 0;
    return allocPointSushi(_pid).mul(1e18).mul(1e18).div(total.mul(1e18)).mul(sushiPerSecond()).div(1e18);
  }

  // Return reward per year for given Sushi pool.
  function sushiPerYear(uint256 _pid) public view returns (uint256) {
    return sushiPerSecondInPool(_pid).mul(365 days);
  }

  // Return rewarder address of the given pool.
  function getRewarderAddress(uint256 _pid) public view returns (address) {
    return miniChef.rewarder(_pid);
  }

  // Retrn reward token for given pool.
  function getRewardToken(uint256 _pid) public view returns (address) {
    (IERC20[] memory rewardTokens, ) = IRewarder(getRewarderAddress(_pid)).pendingTokens(_pid, address(0), 0);
    return address(rewardTokens[0]);
  }

  // Return reward per second.
  function getRewardPerSecond(uint256 _pid) public view returns (uint256) {
    return IRewarder(getRewarderAddress(_pid)).rewardPerSecond();
  }

  // Return reward per second for given pool.
  function getRewardPerSecondInPool(uint256 _pid) public view returns (uint256) {
    uint256 total = totalAllocPointSushi();
    if (total == 0) return 0;
    return allocPointSushi(_pid).mul(1e18).mul(1e18).div(total.mul(1e18)).mul(getRewardPerSecond(_pid)).div(1e18);
  }

  // Return reward peryear for given pool.
  function getRewardPerYearSushi(uint256 _pid) public view returns (uint256) {
    return getRewardPerSecondInPool(_pid).mul(365 days);
  }

  // Return reward price of the given pool.
  function getRewardPrice(uint256 _pid) public view returns (uint256) {
    address rewardToken = getRewardToken(_pid);
    uint256 decimals = uint256(IERC20(rewardToken).decimals());
    uint256 usdcPerMatic = getTokenPerMatic(sushiFactory.getPair(wMatic, usdcToken));
    if (rewardToken == wMatic) return usdcPerMatic;
    uint256 tokenPerMatic = getTokenPerMatic(sushiFactory.getPair(wMatic, rewardToken));
    return usdcPerMatic.mul(10**decimals).div(tokenPerMatic);
  }

  // Return reward token decimals for given pool.

  function rewardTokenDecimals(uint256 _pid) public view returns (uint256) {
    return uint256(IERC20(getRewardToken(_pid)).decimals());
  }

  // =============================== //

  // ===== Quickswap function ===== //

  // Return Quick price in USDC.
  function getQuickPrice() public view returns (uint256) {
    address quick = stakingRewardsFactory.rewardsToken();
    uint256 quickPerMatic = getTokenPerMatic(quickFactory.getPair(wMatic, quick));
    uint256 usdcPerMatic = getTokenPerMatic(quickFactory.getPair(wMatic, usdcToken));
    return usdcPerMatic.mul(1e18).div(quickPerMatic);
  }

  // Return reward rate for given staking rewards.
  function getRewardRate(address _stakingRewards) public view returns (uint256) {
    return IStakingRewards(_stakingRewards).rewardRate();
  }

  // Return reward per year for given Quick stakingRewards.
  function quickPerYear(address _stakingRewards) public view returns (uint256) {
    return IStakingRewards(_stakingRewards).rewardRate().mul(365 days);
  }

  // ============================== //

  // ===== Frontend function ===== //

  // ===== Page Farm ===== //

  // Return all position info in the given range for the given Vault.
  function getRangePosition(
    address _vaultAddr,
    uint256 from,
    uint256 to
  ) public view returns (bytes memory) {
    require(from <= to, "bad length");
    uint256 length = to.sub(from).add(1);
    uint256[] memory positionValue = new uint256[](length);
    uint256[] memory totalDebt = new uint256[](length);
    uint256[] memory _killFactor = new uint256[](length);
    address[] memory worker = new address[](length);
    address[] memory owner = new address[](length);
    uint256[] memory id = new uint256[](length);
    uint256[] memory leverage = new uint256[](length);

    uint256 j = 0;
    address _vault = _vaultAddr;
    for (uint256 i = from; i <= to; i++) {
      (uint256 _positionValue, uint256 _totalDebt) = positionInfo(_vault, i);
      (address _worker, address _owner, , uint256 leverageVal, , , , , ) = positions(_vault, i);
      positionValue[j] = _positionValue;
      totalDebt[j] = _totalDebt;
      _killFactor[j] = killFactor(_worker, _totalDebt);
      worker[j] = _worker;
      owner[j] = _owner;
      leverage[j] = leverageVal;
      id[j] = i;
      j++;
    }
    return abi.encode(positionValue, totalDebt, _killFactor, worker, owner, leverage, id);
  }

  // Return Sushiswap yield farm APY.
  function getSushiYieldFarmAPY(address[] memory _workers) public view returns (bytes memory) {
    uint256 len = _workers.length;
    uint256[] memory yieldFarmAPY = new uint256[](len);
    address[] memory workersList = new address[](len);
    for (uint256 i = 0; i < _workers.length; i++) {
      address worker = _workers[i];
      uint256 pid = getPoolIdSushi(worker);
      address lp = getLpToken(worker);
      uint256 numerator = (
        (sushiPerYear(pid).mul(getSushiPrice()).div(1e18)).add(
          getRewardPerYearSushi(pid).mul(getRewardPrice(pid)).div(10**(rewardTokenDecimals(pid)))
        )
      ).mul(uint256(100)).mul(1e18);
      uint256 denominator = (
        (IERC20(lp).balanceOf(address(miniChef)).mul(1e18).div(IERC20(lp).totalSupply())).mul(getLPValue(worker))
      ).div(1e18);
      yieldFarmAPY[i] = denominator == 0 ? 0 : numerator.div(denominator);
      workersList[i] = worker;
    }
    return abi.encode(workersList, yieldFarmAPY);
  }

  // Return Quickswap yield farm APY.
  function getQuickYieldFarmAPY(address[] memory _workers) public view returns (bytes memory) {
    uint256 len = _workers.length;
    uint256[] memory yieldFarmAPY = new uint256[](len);
    address[] memory workersList = new address[](len);
    for (uint256 i = 0; i < _workers.length; i++) {
      address worker = _workers[i];
      address stakingRewards = getStakingRewards(worker);
      address lp = getLpToken(worker);
      uint256 numerator = quickPerYear(stakingRewards).mul(getQuickPrice()).mul(uint256(100));
      uint256 denominator = (
        (IERC20(lp).balanceOf(stakingRewards).mul(1e18).div(IERC20(lp).totalSupply())).mul(getLPValue(worker))
      ).div(1e18);
      yieldFarmAPY[i] = denominator == 0 ? 0 : numerator.div(denominator);
      workersList[i] = worker;
    }
    return abi.encode(workersList, yieldFarmAPY);
  }

  // ===================== //

  // ===== Page Lend ===== //

  // Return Data for Lend and Earn page.
  function lendAndEarn(
    address _vault,
    address _user,
    uint256 _pid
  ) public view returns (bytes memory) {
    return
      abi.encode(
        rewardAPY(_vault, _pid), //Meow Rewards APY
        getTokenBalance(_vault, _user), // Token balance
        balanceOf(_vault, _user), // ibToken balance
        totalTokenValue(_vault, _user), // Total Token Value
        utilization(_vault),
        totalToken(_vault), // Total Token Deposited
        vaultDebtVal(_vault), // Total debt issued
        ibTokenApy(_vault) // Current ibToken APY
      );
  }

  // ===================== //

  // ===== Page Stake ===== //

  // Return Info for lender.
  function getStakeInfo(
    address _vault,
    uint256 _pid,
    address _user
  )
    public
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return (
      pendingMeow(_pid, _user),
      totalStake(_pid),
      percentStake(_pid, _user),
      userStake(_pid, _user),
      rewardAPY(_vault, _pid),
      meowLockedAmount(_pid, _user),
      availableUnlock(_pid, _user)
    );
  }

  // Return borrower info for the given Vault.
  function getBorrowerReward(address _vault, address _user) public view returns (bytes memory) {
    uint256 _pid = IVault(_vault).meowMiningPoolId();
    return
      abi.encode(
        vaultDebtVal(_vault),
        myPercentDebt(_vault, _user),
        myPositionDebt(_vault, _user),
        borrowerRewardAPY(_vault),
        pendingMeow(_pid, _user),
        meowLockedAmount(_pid, _user),
        availableUnlock(_pid, _user)
      );
  }

  // ========================== //

  // ===== Other function ===== //

  // Return Sushiswap worker TVL.
  function getTVLSushiswap(address[] memory _workers) public view returns (bytes memory) {
    uint256 len = _workers.length;
    uint256 totalTVL = 0;
    uint256[] memory tvl = new uint256[](len);
    address[] memory workersList = new address[](len);
    for (uint256 i = 0; i < _workers.length; i++) {
      address worker = _workers[i];
      uint256 _tvl = getPortionLPValueSushi(worker).add(getPendingSushiValue(worker)).add(
        getPendingRewardValue(worker)
      );
      tvl[i] = _tvl;
      workersList[i] = worker;
      totalTVL = totalTVL.add(_tvl);
    }
    return abi.encode(workersList, tvl, totalTVL);
  }

  // Return Quickswap worker TVL.
  function getTVLQuickswap(address[] memory _workers) public view returns (bytes memory) {
    uint256 len = _workers.length;
    uint256 totalTVL = 0;
    uint256[] memory tvl = new uint256[](len);
    address[] memory workersList = new address[](len);
    for (uint256 i = 0; i < _workers.length; i++) {
      address worker = _workers[i];
      uint256 _tvl = getPortionLPValueQuick(worker).add(getPendingQuickValue(worker));
      tvl[i] = _tvl;
      workersList[i] = worker;
      totalTVL = totalTVL.add(_tvl);
    }
    return abi.encode(workersList, tvl, totalTVL);
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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "./IVaultConfig.sol";

interface IVault {
  // Return address of token to deposit to Vault.
  function token() external view returns (address);

  // Return the total token entitled to the token holders. Be careful of unaccrued interests.
  function totalToken() external view returns (uint256);

  // Return VaultConfig's address of the Vault.
  function config() external view returns (IVaultConfig);

  // Return TotalDebt Value.
  function vaultDebtVal() external view returns (uint256);

  // Return next position id of the Vault.
  function nextPositionID() external view returns (uint256);

  // Return info of the given Position.
  function positions(uint256 id)
    external
    view
    returns (
      address,
      address,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    );

  // Return Token value and debt of the given position. Be careful of unaccrued interests.
  function positionInfo(uint256 id) external view returns (uint256, uint256);

  // Return pool id of borrower MeowMining of this Vault.
  function meowMiningPoolId() external view returns (uint256);

  // Add more token to the Vault.
  function deposit(uint256 amountToken) external payable;

  // Withdraw token from the Vault by burning the share tokens.
  function withdraw(uint256 share) external;

  // Request funds from user through Vault
  function requestFunds(address targetedToken, uint256 amount) external;

  // Return reservePool of Vault.
  function reservePool() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

interface IVaultConfig {
  /// @dev Return minimum BaseToken debt size per position.
  function minDebtSize() external view returns (uint256);

  /// @dev Return the interest rate per year.
  function getInterestRate(
    uint256 debt,
    uint256 floating,
    uint8 decimals
  ) external view returns (uint256);

  /// @dev Return the address of wrapped native token.
  function getWrappedNativeAddr() external view returns (address);

  /// @dev Return the address of wNative relayer.
  function getWNativeRelayer() external view returns (address);

  /// @dev Return the address of fair launch contract.
  function getMeowMiningAddr() external view returns (address);

  /// @dev Return the bps rate for reserve pool.
  function getReservePoolBps() external view returns (uint256);

  /// @dev Return the bps rate for Avada Kill caster.
  function getKillBps() external view returns (uint256);

  /// @dev Return if the caller is whitelisted.
  function whitelistedCallers(address caller) external returns (bool);

  /// @dev Return whether the given address is a worker.
  function isWorker(address worker) external view returns (bool);

  /// @dev Return whether the given worker accepts more debt. Revert on non-worker.
  function acceptDebt(address worker) external view returns (bool);

  /// @dev Return the work factor for the worker + BaseToken debt, using 1e4 as denom. Revert on non-worker.
  function workFactor(address worker, uint256 debt) external view returns (uint256);

  /// @dev Return the kill factor for the worker + BaseToken debt, using 1e4 as denom. Revert on non-worker.
  function killFactor(address worker, uint256 debt) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

interface IMeowMining {
  // Info of each user.
  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
    address fundedBy;
    uint256 lockedAmount;
    uint256 lastUnlockTime;
    uint256 lockTo;
  }

  // Info of each pool.
  struct PoolInfo {
    address stakeToken;
    uint256 allocPoint;
    uint256 lastRewardTime;
    uint256 accMeowPerShare;
  }

  // Return MeowToken address.
  function meow() external view returns (address);

  // Return MEOW tokens created per second.
  function meowPerSecond() external view returns (uint256);

  // Return MeowMining pool length.
  function poolLength() external view returns (uint256);

  // Return total allocation points.
  function totalAllocPoint() external view returns (uint256);

  // Return info of the given pool.
  function poolInfo(uint256 _pid)
    external
    view
    returns (
      address,
      uint256,
      uint256,
      uint256
    );

  // Return info of given user on the given pool.
  function userInfo(uint256 _pid, address _user)
    external
    view
    returns (
      uint256,
      uint256,
      address,
      uint256,
      uint256,
      uint256
    );

  function addPool(uint256 _allocPoint, address _stakeToken) external;

  function setPool(uint256 _pid, uint256 _allocPoint) external;

  function manualMint(address _to, uint256 _amount) external;

  // Return pending MeowToken for given user on given pool.
  function pendingMeow(uint256 _pid, address _user) external view returns (uint256);

  // Return pending unlock MeowToken.
  function availableUnlock(uint256 _pid, address _user) external view returns (uint256);

  function updatePool(uint256 _pid) external;

  function deposit(
    address _for,
    uint256 _pid,
    uint256 _amount
  ) external;

  function withdraw(
    address _for,
    uint256 _pid,
    uint256 _amount
  ) external;

  function withdrawAll(address _for, uint256 _pid) external;

  function harvest(uint256 _pid) external;

  function emergencyWithdraw(uint256 pid) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

interface IWorker {
  /// @dev Work on a (potentially new) position. Optionally send token back to Vault.
  function work(
    uint256 id,
    address user,
    uint256 debt,
    bytes calldata data
  ) external;

  /// @dev Re-invest whatever the worker is working on.
  function reinvest() external;

  // Return address of operator of this worker.
  function operator() external view returns (address);

  /// @dev Return the amount of wei to get back if we are to liquidate the position.
  function health(uint256 id) external view returns (uint256);

  /// @dev Liquidate the given position to token. Send all token back to its Vault.
  function liquidate(uint256 id) external;

  /// @dev SetStretegy that be able to executed by the worker.
  function setStrategyOk(address[] calldata strats, bool isOk) external;

  /// @dev Set address that can be reinvest
  function setReinvestorOk(address[] calldata reinvestor, bool isOk) external;

  /// @dev LP token holds by worker
  function lpToken() external view returns (IUniswapV2Pair);

  /// @dev Base Token that worker is working on
  function baseToken() external view returns (address);

  /// @dev Farming Token that worker is working on
  function farmingToken() external view returns (address);

  /// @dev Return the reward bounty for calling reinvest operation.
  function reinvestBountyBps() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../interfaces/IMiniChefV2.sol";

interface ISushiWorker {
  /// @dev Work on a (potentially new) position. Optionally send token back to Vault.
  function work(
    uint256 id,
    address user,
    uint256 debt,
    bytes calldata data
  ) external;

  /// @dev Re-invest whatever the worker is working on.
  function reinvest() external;

  // Return address of operator of this worker.
  function operator() external view returns (address);

  /// @dev Return the amount of wei to get back if we are to liquidate the position.
  function health(uint256 id) external view returns (uint256);

  /// @dev Liquidate the given position to token. Send all token back to its Vault.
  function liquidate(uint256 id) external;

  /// @dev SetStretegy that be able to executed by the worker.
  function setStrategyOk(address[] calldata strats, bool isOk) external;

  /// @dev Set address that can be reinvest
  function setReinvestorOk(address[] calldata reinvestor, bool isOk) external;

  /// @dev LP token holds by worker
  function lpToken() external view returns (IUniswapV2Pair);

  /// @dev Return address of MasterChef.
  function masterChef() external view returns (IMiniChefV2);

  /// @dev Return address of SushiToken.
  function sushi() external view returns (address);

  /// @dev Return pool id on MasterChef of this worker.
  function pid() external view returns (uint256);

  /// @dev Base Token that worker is working on
  function baseToken() external view returns (address);

  /// @dev Farming Token that worker is working on
  function farmingToken() external view returns (address);

  /// @dev Return the reward bounty for calling reinvest operation.
  function reinvestBountyBps() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../interfaces/IStakingRewards.sol";

interface IQuickWorker {
  /// @dev Work on a (potentially new) position. Optionally send token back to Vault.
  function work(
    uint256 id,
    address user,
    uint256 debt,
    bytes calldata data
  ) external;

  /// @dev Re-invest whatever the worker is working on.
  function reinvest() external;

  // Return address of operator of this worker.
  function operator() external view returns (address);

  /// @dev Return the amount of wei to get back if we are to liquidate the position.
  function health(uint256 id) external view returns (uint256);

  /// @dev Liquidate the given position to token. Send all token back to its Vault.
  function liquidate(uint256 id) external;

  /// @dev SetStretegy that be able to executed by the worker.
  function setStrategyOk(address[] calldata strats, bool isOk) external;

  /// @dev Set address that can be reinvest
  function setReinvestorOk(address[] calldata reinvestor, bool isOk) external;

  /// @dev LP token holds by worker
  function lpToken() external view returns (IUniswapV2Pair);

  /// @dev Return pool id on StakingRewardsFactory of this worker.
  function pid() external view returns (uint256);

  /// @dev Return address of StakingRewards.
  function stakingRewards() external view returns (IStakingRewards);

  /// @dev Return address of QuickToken.
  function quick() external view returns (address);

  /// @dev Base Token that worker is working on
  function baseToken() external view returns (address);

  /// @dev Farming Token that worker is working on
  function farmingToken() external view returns (address);

  /// @dev Return the reward bounty for calling reinvest operation.
  function reinvestBountyBps() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

interface ITripleSlopeModel {
  // Return Utilization.
  function getUtilization(uint256 debt, uint256 floating) external pure returns (uint256);

  // Return the interest rate per year.
  function getInterestRate(
    uint256 debt,
    uint256 floating,
    uint8 decimals
  ) external view returns (uint256);

  function CEIL_SLOPE_1() external view returns (uint256);

  function CEIL_SLOPE_2() external view returns (uint256);

  function CEIL_SLOPE_3() external view returns (uint256);

  function MAX_INTEREST_SLOPE_1() external view returns (uint256);

  function MAX_INTEREST_SLOPE_2() external view returns (uint256);

  function MAX_INTEREST_SLOPE_3() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

interface IMiniChefV2 {
  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
  }

  struct PoolInfo {
    uint128 accSushiPerShare;
    uint64 lastRewardTime;
    uint64 allocPoint;
  }

  function SUSHI() external view returns (address);

  function sushiPerSecond() external view returns (uint256);

  function totalAllocPoint() external view returns (uint256);

  function lpToken(uint256 _pid) external view returns (address);

  function rewarder(uint256 _pid) external view returns (address);

  function pendingSushi(uint256 _pid, address _user) external view returns (uint256);

  function poolLength() external view returns (uint256);

  function poolInfo(uint256 _pid)
    external
    view
    returns (
      uint128,
      uint64,
      uint64
    );

  function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

  function deposit(
    uint256 pid,
    uint256 amount,
    address to
  ) external;

  function withdraw(
    uint256 pid,
    uint256 amount,
    address to
  ) external;

  function harvest(uint256 pid, address to) external;

  function withdrawAndHarvest(
    uint256 pid,
    uint256 amount,
    address to
  ) external;

  function emergencyWithdraw(uint256 pid, address to) external;
}

pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

interface IRewarder {
  function pendingTokens(
    uint256 pid,
    address user,
    uint256 sushiAmount
  ) external view returns (IERC20[] memory, uint256[] memory);

  function rewardPerSecond() external view returns (uint256);
}

pragma solidity 0.6.6;

interface IStakingRewardsFactory {
  // Views
  function rewardsToken() external view returns (address);

  function stakingRewardsGenesis() external view returns (uint256);

  function stakingTokens(uint256 _pid) external view returns (address);

  function stakingRewardsInfoByStakingToken(address _stakingToken)
    external
    view
    returns (
      address,
      uint256,
      uint256
    );
}

pragma solidity 0.6.6;

interface IStakingRewards {
  // Views
  function rewardsToken() external view returns (address);

  function stakingToken() external view returns (address);

  function rewardsDistribution() external view returns (address);

  function lastTimeRewardApplicable() external view returns (uint256);

  function rewardPerToken() external view returns (uint256);

  function earned(address account) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function rewardRate() external view returns (uint256);

  // Mutative

  function stake(uint256 amount) external;

  function withdraw(uint256 amount) external;

  function getReward() external;

  function exit() external;
}

pragma solidity 0.6.6;

// a library for performing various math operations

library Math {
  function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = x < y ? x : y;
  }

  // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
  function sqrt(uint256 y) internal pure returns (uint256 z) {
    if (y > 3) {
      z = y;
      uint256 x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

pragma solidity ^0.6.0;

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
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

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
    function decimals() external view returns (uint8);

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

