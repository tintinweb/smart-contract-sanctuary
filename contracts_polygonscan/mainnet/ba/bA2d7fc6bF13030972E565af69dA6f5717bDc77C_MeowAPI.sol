pragma solidity 0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "./sushi/IUniswapV2Router02.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IVaultConfig.sol";
import "../../token/interfaces/IFairLaunch.sol";
import "../interfaces/IWorker.sol";
import "../interfaces/InterestModel.sol";
import "../interfaces/IMiniChefV2.sol";
import "../interfaces/AggregatorV3Interface.sol";
import "../../utils/Math.sol";

contract MeowAPI is Ownable {
  using SafeMath for uint256;
  address public meowToken;
  address public usdcToken;
  address public wMatic;
  IUniswapV2Router02 public router;
  IUniswapV2Factory public factory;
  IFairLaunch public fairLaunch;
  InterestModel public interest;

  constructor(
    IFairLaunch _fairLaunch,
    InterestModel _interest,
    IUniswapV2Router02 _router,
    address _meowToken,
    address _usdcToken
  ) public {
    fairLaunch = _fairLaunch;
    interest = _interest;
    router = _router;
    factory = IUniswapV2Factory(_router.factory());
    wMatic = _router.WETH();
    meowToken = _meowToken;
    usdcToken = _usdcToken;
  }

  function setParam(
    IFairLaunch _fairLaunch,
    InterestModel _interest,
    IUniswapV2Router02 _router,
    address _meowToken,
    address _usdcToken
  ) public onlyOwner {
    fairLaunch = _fairLaunch;
    interest = _interest;
    router = _router;
    factory = IUniswapV2Factory(_router.factory());
    wMatic = _router.WETH();
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
    if (IVault(_vault).token() == IVaultConfig(IVault(_vault).config()).getWrappedNativeAddr()) {
      return getMaticBalance(_user);
    } else return IERC20(IVault(_vault).token()).balanceOf(_user);
  }

  // Return interest bearing token balance for the given user.
  function balanceOf(address _vault, address _user) public view returns (uint256) {
    // return IVault(_vault).balanceOf(_user);
    return IERC20(_vault).balanceOf(_user);
  }

  // Return ibToken price for the given Station.
  function ibTokenPrice(address _vault) public view returns (uint256) {
    if (totalSupply(_vault) == 0) {
      return 0;
    } else return totalToken(_vault).mul(1e18).div(totalSupply(_vault));
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
    address token = IVault(_vault).token();
    uint256 balance = IERC20(token).balanceOf(_vault).sub(IVault(_vault).reservePool());
    if (vaultDebtVal(_vault) == 0) {
      return 0;
    } else return vaultDebtVal(_vault).mul(1e18).div(vaultDebtVal(_vault).add(balance)).mul(100);
  }

  // Return interest rate for the given Vault.
  function getInterestRate(address _vault) public view returns (uint256) {
    uint256 _utilization = utilization(_vault);
    uint256 ceil1 = interest.CEIL_SLOPE_1();
    uint256 ceil2 = interest.CEIL_SLOPE_2();
    uint256 ceil3 = interest.CEIL_SLOPE_3();

    uint256 interest1 = interest.MAX_INTEREST_SLOPE_1();
    uint256 interest2 = interest.MAX_INTEREST_SLOPE_2();
    uint256 interest3 = interest.MAX_INTEREST_SLOPE_3();

    if (_utilization < ceil1) return _utilization.mul(interest1).div(ceil1);
    else if (_utilization < ceil2) return interest2;
    else if (_utilization < ceil3)
      return interest2.add((_utilization.sub(ceil2)).mul(interest3.sub(interest2)).div(ceil3.sub(ceil2)));
    else return interest3;
  }

  // Return ibToken APY for the given Vault.
  function ibTokenApy(address _vault) public view returns (uint256) {
    return getInterestRate(_vault).mul(utilization(_vault)).div(1e18);
  }

  // Return total Token value for the given user.
  function totalTokenValue(address _vault, address _user) public view returns (uint256) {
    if (totalSupply(_vault) == 0) {
      return 0;
    } else return balanceOf(_vault, _user).mul(totalToken(_vault)).div(totalSupply(_vault));
  }

  // Return Fairlaunch pool id for borrower.
  function getFairLaunchPoolId(address _vault) public view returns (uint256) {
    return IVault(_vault).fairLaunchPoolId();
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
      (, address _owner, , , , , ) = positions(_vault, i);
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
    if (totalDebt == 0) {
      return 0;
    } else return myDebt.mul(uint256(100)).mul(1e18).div(totalDebt);
  }

  // =============================== //

  // ===== Fairlaunch function ===== //

  // Return MEOW per second.
  function meowPerSecond() public view returns (uint256) {
    return fairLaunch.meowPerSecond();
  }

  // Return total allocation point.
  function totalAllocPoint() public view returns (uint256) {
    return fairLaunch.totalAllocPoint();
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
    return fairLaunch.userInfo(_pid, _user);
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
    return fairLaunch.poolInfo(_pid);
  }

  // Return total stake token for given pool.
  function totalStake(uint256 _pid) public view returns (uint256) {
    (address stakeToken, , , ) = poolInfo(_pid);
    return IERC20(stakeToken).balanceOf(address(fairLaunch));
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
    return fairLaunch.pendingMeow(_pid, _user);
  }

  // Return MEOW lockedAmount.
  function meowLockedAmount(uint256 _pid, address _user) public view returns (uint256) {
    (, , , uint256 lockedAmount, , ) = userInfo(_pid, _user);
    return lockedAmount;
  }

  // Return pending release MEOW for the given user.
  function availableUnlock(uint256 _pid, address _user) public view returns (uint256) {
    return fairLaunch.availableUnlock(_pid, _user);
  }

  // Return meowPerSecond for given pool
  function meowPerSecondInPool(uint256 _pid) public view returns (uint256) {
    uint256 total = totalAllocPoint();
    if (total == 0) {
      return 0;
    } else return _allocPoint(_pid).mul(1e18).mul(1e18).div(totalAllocPoint().mul(1e18)).mul(meowPerSecond()).div(1e18);
  }

  // Return reward per day for given pool.
  function rewardPerDay(uint256 _pid) public view returns (uint256) {
    return meowPerSecondInPool(_pid).mul(86400);
  }

  // Return reward per year for given pool.
  function rewardPerYear(uint256 _pid) public view returns (uint256) {
    return rewardPerDay(_pid).mul(365);
  }

  // Return reward APY.
  function rewardAPY(address _vault, uint256 _pid) public view returns (uint256) {
    uint256 numerator = rewardPerYear(_pid).mul(meowPrice()).mul(uint256(100));
    uint256 price = getTokenPrice(_vault, _pid);
    uint256 dominator = totalStake(_pid).mul(price).div(1e18);
    return dominator == 0 ? 0 : numerator.mul(1e18).div(dominator);
  }

  // Return reward APY of borrower for the given Vault.
  function borrowerRewardAPY(address _vault, uint256 _pid) public view returns (uint256) {
    uint256 totalDebt = vaultDebtVal(_vault);
    if (totalDebt == 0) {
      return 0;
    } else
      return
        rewardPerYear(_pid).mul(meowPrice()).mul(uint256(100)).mul(1e18).div(totalDebt.mul(baseTokenPrice(_vault)));
  }

  // ========================== //

  // ===== Price function ===== //

  // Get price from Chainlink.
  function getLatestPrice(address _priceFeed) public view returns (int256) {
    (
      uint80 roundID,
      int256 price,
      uint256 startedAt,
      uint256 timeStamp,
      uint80 answeredInRound
    ) = AggregatorV3Interface(_priceFeed).latestRoundData();
    // If the round is not complete yet, timestamp is 0
    require(timeStamp > 0, "Round not complete");
    return price;
  }

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
        ? uint256(reserve0).mul(1e18).div(uint256(reserve1))
        : uint256(reserve1).mul(1e18).div(uint256(reserve0));
  }

  // Return LP reserve of LP token pair for the given pool.
  function lpReserves(uint256 _pid) public view returns (uint112, uint112) {
    (address stakeToken, , , ) = fairLaunch.poolInfo(_pid);
    (uint112 _reserve0, uint112 _reserve1, ) = IUniswapV2Pair(stakeToken).getReserves();
    return (_reserve0, _reserve1);
  }

  // Return total supply of LP token for the given pool.
  function lpSupply(uint256 _pid) public view returns (uint256) {
    (address stakeToken, , , ) = fairLaunch.poolInfo(_pid);
    return IUniswapV2Pair(stakeToken).totalSupply();
  }

  // Return token0 of LP token for the given pool.
  function lpToken0(uint256 _pid) public view returns (address) {
    (address stakeToken, , , ) = fairLaunch.poolInfo(_pid);
    return IUniswapV2Pair(stakeToken).token0();
  }

  // Return MeowToken price in USDC.
  function meowPrice() public view returns (uint256) {
    uint256 meowPerMatic = getTokenPerMatic(factory.getPair(wMatic, meowToken));
    uint256 usdcPerMatic = getTokenPerMatic(factory.getPair(wMatic, usdcToken));
    return usdcPerMatic.mul(1e18).div(meowPerMatic);
  }

  // Return BaseToken price in USDC for the given Vault.
  function baseTokenPrice(address _vault) public view returns (uint256) {
    address baseToken = IVault(_vault).token();
    uint256 usdcPerMatic = getTokenPerMatic(factory.getPair(wMatic, usdcToken));
    address baseTokenLP;
    if (baseToken == wMatic) {
      return usdcPerMatic;
    } else {
      baseTokenLP = factory.getPair(baseToken, wMatic);
      uint256 tokenPerMatic = getTokenPerMatic(baseTokenLP);
      return usdcPerMatic.mul(1e18).div(tokenPerMatic);
    }
  }

  function MaticReserve(uint256 _pid) public view returns (uint256) {
    string memory symbol = IERC20(lpToken0(_pid)).symbol();
    (uint112 _reserve0, uint112 _reserve1) = lpReserves(_pid);
    if (keccak256(bytes(symbol)) == keccak256(bytes("WMATIC"))) {
      return uint256(_reserve1);
    }
    return uint256(_reserve0);
  }

  function tokenReserve(uint256 _pid) public view returns (uint256) {
    string memory symbol = IERC20(lpToken0(_pid)).symbol();
    (uint112 _reserve0, uint112 _reserve1) = lpReserves(_pid);
    if (keccak256(bytes(symbol)) != keccak256(bytes("WMATIC"))) {
      return uint256(_reserve1);
    }
    return uint256(_reserve0);
  }

  function _result1(uint256 _MaticReserve, uint256 _tokenReserve) public pure returns (uint256) {
    return _MaticReserve.mul(_tokenReserve);
  }

  function _result2(uint256 _MaticReserve, uint256 _tokenReserve) public pure returns (uint256) {
    return _tokenReserve.mul(1e18).div(_MaticReserve);
  }

  // Return LP price in Matic.
  function lpPrice(uint256 _pid) public view returns (uint256) {
    uint256 _MaticReserve = MaticReserve(_pid);
    uint256 _tokenReserve = tokenReserve(_pid);
    uint256 _lpSupply = lpSupply(_pid);
    uint256 result1 = _result1(_MaticReserve, _tokenReserve);
    uint256 result2 = _result2(_MaticReserve, _tokenReserve);
    return uint256(2).mul(Math.sqrt(result1.mul(result2).div(1e18))).mul(1e18).div(_lpSupply);
  }

  // Return token value.
  function getTokenPrice(address _vault, uint256 _pid) public view returns (uint256) {
    uint256 price;
    price = ibTokenPrice(_vault).mul(baseTokenPrice(_vault));
    return price;
  }

  // Return Sushi price in USDC.
  function getSushiPrice(address _masterChef) public view returns (uint256) {
    address sushi = IMiniChefV2(_masterChef).SUSHI();
    uint256 sushiPerMatic = getTokenPerMatic(factory.getPair(wMatic, sushi));
    uint256 usdcPerMatic = getTokenPerMatic(factory.getPair(wMatic, usdcToken));
    return usdcPerMatic.mul(1e18).div(sushiPerMatic);
  }

  // =========================== //

  // ===== Worker function ===== //

  // Return LP Token of the given worker.
  function getLpToken(address _worker) public view returns (address) {
    return address(IWorker(_worker).lpToken());
  }

  // Return pool id of the given worker.
  function getPoolId(address _worker) public view returns (uint256) {
    return IWorker(_worker).pid();
  }

  // Return MasterChef of the given worker.
  function getMasterChef(address _worker) public view returns (address) {
    return address(IWorker(_worker).masterChef());
  }

  // Return BaseToken of the given worker.
  function getBaseToken(address _worker) public view returns (address) {
    return IWorker(_worker).baseToken();
  }

  // Return FarmingToken of the given worker.
  function getFarmingToken(address _worker) public view returns (address) {
    return IWorker(_worker).farmingToken();
  }

  // Return Reward token address of MasterChef for the given worker.
  function getSushiAddr(address _worker) public view returns (address) {
    return IWorker(_worker).sushi();
  }

  // Return the reward bounty for calling reinvest operation of the given worker.
  function getReinvestBounty(address _worker) public view returns (uint256) {
    return IWorker(_worker).reinvestBountyBps();
  }

  // Return StakeToken amount of the given worker on MasterChef.
  function getWorkerStakeAmount(address _worker) public view returns (uint256) {
    uint256 pid = getPoolId(_worker);
    address masterChef = getMasterChef(_worker);
    (uint256 amount, ) = IMiniChefV2(masterChef).userInfo(pid, _worker);
    return amount;
  }

  // Return BaseToken amount in the LP of the given worker.
  function getLPValue(address _worker) public view returns (uint256) {
    address lpToken = address(IWorker(_worker).lpToken());
    address baseToken = IWorker(_worker).baseToken();
    address vault = IWorker(_worker).operator();
    uint256 tokenPrice = baseTokenPrice(vault);
    return (IERC20(baseToken).balanceOf(lpToken)).mul(uint256(2).mul(tokenPrice).div(1e18));
  }

  // ============================= //

  // ===== Frontend function ===== //

  // ===== Page Farm ===== //

  // Return all position info in the given range for the given Station.
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
    uint256 j = 0;
    address _vault = _vaultAddr;
    for (uint256 i = from; i <= to; i++) {
      (uint256 _positionValue, uint256 _totalDebt) = positionInfo(_vault, i);
      (address _worker, address _owner, , , , , ) = positions(_vault, i);
      positionValue[j] = _positionValue;
      totalDebt[j] = _totalDebt;
      _killFactor[j] = killFactor(_worker, _totalDebt);
      worker[j] = _worker;
      owner[j] = _owner;
      j++;
    }
    return abi.encode(positionValue, totalDebt, _killFactor, worker, owner);
  }

  // Return Sushiswap yield farm APY.
  function getSushiYieldFarmAPY(address[] memory _workers) public view returns (bytes memory) {
    uint256 len = _workers.length;
    uint256[] memory balance = new uint256[](len);
    uint256[] memory _totalSupply = new uint256[](len);
    uint256[] memory lpBaseTokenAmount = new uint256[](len);
    uint256[] memory allocPoint = new uint256[](len);
    address[] memory workersList = new address[](len);
    for (uint256 i = 0; i < _workers.length; i++) {
      address worker = _workers[i];
      address lp = getLpToken(worker);
      uint256 pid = getPoolId(worker);
      address masterChef = getMasterChef(worker);
      address _baseToken = getBaseToken(worker);
      balance[i] = IUniswapV2Pair(lp).balanceOf(masterChef);
      _totalSupply[i] = IUniswapV2Pair(lp).totalSupply();
      lpBaseTokenAmount[i] = IERC20(_baseToken).balanceOf(lp);
      (, , uint64 _alloc) = IMiniChefV2(masterChef).poolInfo(pid);
      allocPoint[i] = uint256(_alloc);
      workersList[i] = worker;
    }
    return abi.encode(balance, _totalSupply, lpBaseTokenAmount, allocPoint, workersList);
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
  function getBorrowerReward(
    address _vault,
    address _user,
    uint256 _pid
  ) public view returns (bytes memory) {
    return
      abi.encode(
        vaultDebtVal(_vault),
        myPercentDebt(_vault, _user),
        myPositionDebt(_vault, _user),
        borrowerRewardAPY(_vault, _pid),
        pendingMeow(_pid, _user),
        meowLockedAmount(_pid, _user),
        availableUnlock(_pid, _user)
      );
  }

  // ========================== //

  // ===== Other function ===== //

  // Return info for the given Masterchef.
  function masterChefInfo(address _masterChef) public view returns (uint256, uint256) {
    return (IMiniChefV2(_masterChef).sushiPerSecond(), IMiniChefV2(_masterChef).totalAllocPoint());
  }

  // Return Sushiswap TVL.
  function getTVLSushiswap(address[] memory _workers) public view returns (bytes memory) {
    uint256 len = _workers.length;
    uint256 totalTVL = 0;
    uint256[] memory bps = new uint256[](len);
    uint256[] memory pendingSushi = new uint256[](len);
    uint256[] memory tvl = new uint256[](len);
    address[] memory workersList = new address[](len);
    for (uint256 i = 0; i < _workers.length; i++) {
      address worker = _workers[i];
      address lp = getLpToken(worker);
      uint256 pid = getPoolId(worker);
      address masterChef = getMasterChef(worker);
      address sushi = getSushiAddr(worker);
      bps[i] = getReinvestBounty(worker);
      pendingSushi[i] = IMiniChefV2(masterChef).pendingSushi(pid, worker).add(IERC20(sushi).balanceOf(worker));
      uint256 amount = getWorkerStakeAmount(worker);
      uint256 _totalSupply = IUniswapV2Pair(lp).totalSupply();
      uint256 _tvl = getLPValue(worker).mul(uint256(amount)).div(uint256(_totalSupply));
      tvl[i] = _tvl;
      workersList[i] = worker;
      totalTVL = totalTVL.add(_tvl);
    }
    return abi.encode(bps, pendingSushi, tvl, workersList, totalTVL);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.6;

import "./IVaultConfig.sol";

interface IVault {
  // Return address of token to deposit to Vault.
  function token() external view returns (address);

  // Return the total token entitled to the token holders. Be careful of unaccrued interests.
  function totalToken() external view returns (uint256);

  // // Return total supply of the ibToken.
  // function totalSupply() external view returns (uint256);

  // // Return ibToken amount of the given account.
  // function balanceOf(address account) external view returns (uint256);

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
      uint256
    );

  // Return Token value and debt of the given position. Be careful of unaccrued interests.
  function positionInfo(uint256 id) external view returns (uint256, uint256);

  // Return pool id of borrower FairLaunch of this Vault.
  function fairLaunchPoolId() external view returns (uint256);

  // Add more token to the Vault.
  function deposit(uint256 amountToken) external payable;

  // Withdraw token from the Vault by burning the share tokens.
  function withdraw(uint256 share) external;

  // Request funds from user through Vault
  function requestFunds(address targetedToken, uint256 amount) external;

  // Return reservePool of Vault.
  function reservePool() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.6;

interface IVaultConfig {
  /// @dev Return minimum BaseToken debt size per position.
  function minDebtSize() external view returns (uint256);

  /// @dev Return the interest rate per second, using 1e18 as denom.
  function getInterestRate(uint256 debt, uint256 floating) external view returns (uint256);

  /// @dev Return the address of wrapped native token.
  function getWrappedNativeAddr() external view returns (address);

  /// @dev Return the address of wNative relayer.
  function getWNativeRelayer() external view returns (address);

  /// @dev Return the address of fair launch contract.
  function getFairLaunchAddr() external view returns (address);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.6;

interface IFairLaunch {
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

  // Return FairLaunch pool length.
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.6;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../interfaces/IMiniChefV2.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.6;

interface InterestModel {
  /// @dev Return the interest rate per second, using 1e18 as denom.
  function getInterestRate(uint256 debt, uint256 floating) external view returns (uint256);

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

pragma solidity ^0.6.6;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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