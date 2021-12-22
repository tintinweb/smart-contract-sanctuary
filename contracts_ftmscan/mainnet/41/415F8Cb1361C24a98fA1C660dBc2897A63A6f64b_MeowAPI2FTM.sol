// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "../IUniswapV2Router02.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/IVault.sol";
import "../../interfaces/IVaultConfig.sol";
import "../../../token/interfaces/IMeowMining.sol";
import "../../interfaces/IWorker.sol";
import "../../interfaces/ISpookyWorker.sol";
import "../../interfaces/ISpookyMasterChef.sol";
import "../../interfaces/ISpiritWorker.sol";
import "../../interfaces/ISpiritMasterChef.sol";
import "../../../utils/Math.sol";

interface IWNative {
  function symbol() external view returns (string memory);
}

contract MeowAPI2FTM is Ownable {
  using SafeMath for uint256;
  address public meowToken;
  address public usdcToken;
  address public wNative;
  IUniswapV2Router02 public spookyRouter;
  IUniswapV2Factory public spookyFactory;
  ISpookyMasterChef public spookyMasterChef;
  IUniswapV2Router02 public spiritRouter;
  IUniswapV2Factory public spiritFactory;
  ISpiritMasterChef public spiritMasterChef;
  IMeowMining public meowMining;
  address[] public vaults;
  address[] public spookyWorkers;
  address[] public spiritWorkers;

  constructor(
    IMeowMining _meowMining,
    IUniswapV2Router02 _spookyRouter,
    ISpookyMasterChef _spookyMasterChef,
    IUniswapV2Router02 _spiritRouter,
    ISpiritMasterChef _spiritMasterChef,
    address _usdcToken
  ) public {
    meowMining = _meowMining;
    spookyRouter = _spookyRouter;
    spookyFactory = IUniswapV2Factory(_spookyRouter.factory());
    spookyMasterChef = _spookyMasterChef;
    spiritRouter = _spiritRouter;
    spiritFactory = IUniswapV2Factory(_spiritRouter.factory());
    spiritMasterChef = _spiritMasterChef;
    wNative = _spookyRouter.WETH();
    meowToken = IMeowMining(_meowMining).meow();
    usdcToken = _usdcToken;
  }

  // ===== Set Params function ===== //

  function setVaults(address[] memory _vaults) public onlyOwner {
    vaults = _vaults;
  }

  function setSpookyWorkers(address[] memory _spookyWorkers) public onlyOwner {
    spookyWorkers = _spookyWorkers;
  }

  function setSpiritWorkers(address[] memory _spiritWorkers) public onlyOwner {
    spiritWorkers = _spiritWorkers;
  }

  function setMeowMining(IMeowMining _meowMining) public onlyOwner {
    meowMining = _meowMining;
    meowToken = IMeowMining(_meowMining).meow();
  }

  // =============================== //

  // ===== Vault function ===== //

  function getVaults() public view returns (address[] memory) {
    return vaults;
  }

  function getVaultsLength() public view returns (uint256) {
    return vaults.length;
  }

  // Return Native balance for the given user.
  function getBalance(address _user) public view returns (uint256) {
    return address(_user).balance;
  }

  // Return the given Token balance for the given user.
  function getTokenBalance(address _vault, address _user) public view returns (uint256) {
    if (IVault(_vault).token() == IVaultConfig(IVault(_vault).config()).getWrappedNativeAddr())
      return getBalance(_user);
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

  // =============================== //

  // ===== MeowMining function ===== //

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

  // ========================== //

  // ===== Price function ===== //

  // Return Token per Native.
  function getTokenPerNative(address _lp) public view returns (uint256) {
    (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(_lp).getReserves();
    string memory symbol = IERC20(IUniswapV2Pair(_lp).token0()).symbol();
    return
      keccak256(bytes(symbol)) == keccak256(bytes(IWNative(wNative).symbol()))
        ? uint256(reserve1).mul(1e18).div(uint256(reserve0))
        : uint256(reserve0).mul(1e18).div(uint256(reserve1));
  }

  // Return Native per Token.
  function getNativePerToken(address _lp) public view returns (uint256) {
    (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(_lp).getReserves();
    string memory symbol = IERC20(IUniswapV2Pair(_lp).token0()).symbol();
    return
      keccak256(bytes(symbol)) == keccak256(bytes(IWNative(wNative).symbol()))
        ? uint256(reserve0).mul(10**uint256(IERC20(IUniswapV2Pair(_lp).token1()).decimals())).div(uint256(reserve1))
        : uint256(reserve1).mul(10**uint256(IERC20(IUniswapV2Pair(_lp).token0()).decimals())).div(uint256(reserve0));
  }

  // Return MeowToken price in USDC.
  function meowPrice() public view returns (uint256) {
    if (spookyFactory.getPair(wNative, meowToken) == address(0)) return 0;
    uint256 meowPerNative = getTokenPerNative(spookyFactory.getPair(wNative, meowToken));
    uint256 usdcPerNative = getTokenPerNative(spookyFactory.getPair(wNative, usdcToken));
    return usdcPerNative.mul(1e18).div(meowPerNative);
  }

  // Return BaseToken price in USDC for the given Vault.
  function baseTokenPrice(address _vault) public view returns (uint256) {
    address baseToken = IVault(_vault).token();
    uint256 decimals = uint256(IERC20(_vault).decimals());
    uint256 usdcPerNativeSpooky = getTokenPerNative(spookyFactory.getPair(wNative, usdcToken));
    address baseTokenLPSpooky;
    if (baseToken == wNative) return usdcPerNativeSpooky;
    baseTokenLPSpooky = spookyFactory.getPair(baseToken, wNative);
    uint256 tokenPerNativeSpooky = getTokenPerNative(baseTokenLPSpooky);
    return usdcPerNativeSpooky.mul(10**decimals).div(tokenPerNativeSpooky);
  }

  // Return token value.
  function getTokenPrice(address _vault, uint256 _pid) public view returns (uint256) {
    uint256 price;
    uint256 decimals;
    if (_vault != address(0)) decimals = uint256(IERC20(_vault).decimals());
    uint256 usdcPerNative = getTokenPerNative(spookyFactory.getPair(wNative, usdcToken));
    address meowLp = spookyFactory.getPair(wNative, meowToken);
    (address stakeToken, , , ) = meowMining.poolInfo(_pid);
    if (stakeToken == meowLp || _vault == address(0))
      return IERC20(wNative).balanceOf(meowLp).mul(uint256(2)).mul(usdcPerNative).div(1e18);
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

  // ===== Spooky Worker function ===== //

  function getSpookyWorkers() public view returns (address[] memory) {
    return spookyWorkers;
  }

  function getSpookyWorkersLength() public view returns (uint256) {
    return spookyWorkers.length;
  }

  // Return pool id on MasterChef of the given Spooky worker.
  function getPoolIdSpooky(address _worker) public view returns (uint256) {
    return ISpookyWorker(_worker).pid();
  }

  // Return MasterChef of the given Spooky worker.
  function getMasterChefSpooky(address _worker) public view returns (address) {
    return address(ISpookyWorker(_worker).masterChef());
  }

  // Return Reward token address of MasterChef for the given Spooky worker.
  function getBOOAddr(address _worker) public view returns (address) {
    return ISpookyWorker(_worker).boo();
  }

  // Return StakeToken amount of the given Spooky worker on MasterChef.
  function getWorkerStakeAmountSpooky(address _worker) public view returns (uint256) {
    (uint256 amount, ) = spookyMasterChef.userInfo(getPoolIdSpooky(_worker), _worker);
    return amount;
  }

  // Return pending BOO value.
  function getPendingBOOValue(address _worker) public view returns (uint256) {
    return
      (
        spookyMasterChef.pendingBOO(getPoolIdSpooky(_worker), _worker).add(
          IERC20(getBOOAddr(_worker)).balanceOf(_worker)
        )
      ).mul(getBOOPrice()).div(1e18);
  }

  // Return portion LP value of given Spooky worker.
  function getPortionLPValueSpooky(address _workewr) public view returns (uint256) {
    return
      getWorkerStakeAmountSpooky(_workewr)
        .mul(1e18)
        .div(IUniswapV2Pair(getLpToken(_workewr)).totalSupply())
        .mul(getLPValue(_workewr))
        .div(1e18);
  }

  // ================================= //

  // ===== Spirit Worker function ===== //

  function getSpiritWorkers() public view returns (address[] memory) {
    return spiritWorkers;
  }

  function getSpiritWorkersLength() public view returns (uint256) {
    return spiritWorkers.length;
  }

  // Return pool id on MasterChef of the given Spirit worker.
  function getPoolIdSpirit(address _worker) public view returns (uint256) {
    return ISpiritWorker(_worker).pid();
  }

  // Return MasterChef of the given Spirit worker.
  function getMasterChefSpirit(address _worker) public view returns (address) {
    return address(ISpiritWorker(_worker).masterChef());
  }

  // Return Reward token address of MasterChef for the given Spirit worker.
  function getSPIRITAddr(address _worker) public view returns (address) {
    return ISpiritWorker(_worker).spirit();
  }

  // Return StakeToken amount of the given Spirit worker on MasterChef.
  function getWorkerStakeAmountSpirit(address _worker) public view returns (uint256) {
    (uint256 amount, ) = spiritMasterChef.userInfo(getPoolIdSpirit(_worker), _worker);
    return amount;
  }

  // Return pending SPIRIT value.
  function getPendingSPIRITValue(address _worker) public view returns (uint256) {
    return
      (
        spiritMasterChef.pendingSpirit(getPoolIdSpirit(_worker), _worker).add(
          IERC20(getSPIRITAddr(_worker)).balanceOf(_worker)
        )
      ).mul(getSPIRITPrice()).div(1e18);
  }

  // Return portion LP value of given Spirit worker.
  function getPortionLPValueSpirit(address _workewr) public view returns (uint256) {
    return
      getWorkerStakeAmountSpirit(_workewr)
        .mul(1e18)
        .div(IUniswapV2Pair(getLpToken(_workewr)).totalSupply())
        .mul(getLPValue(_workewr))
        .div(1e18);
  }

  // ================================= //

  // ================================= //

  // ===== Spookyswap function ===== //

  // Return BOO price in USDC.
  function getBOOPrice() public view returns (uint256) {
    address boo = spookyMasterChef.boo();
    uint256 booPerNative = getTokenPerNative(spookyFactory.getPair(wNative, boo));
    uint256 usdcPerNative = getTokenPerNative(spookyFactory.getPair(wNative, usdcToken));
    return usdcPerNative.mul(1e18).div(booPerNative);
  }

  // Return BOO per second.
  function booPerSecond() public view returns (uint256) {
    return spookyMasterChef.booPerSecond();
  }

  // Return total allocation point of SpookyMasterChef.
  function totalAllocPointSpooky() public view returns (uint256) {
    return spookyMasterChef.totalAllocPoint();
  }

  // Return poolInfo of given pool in SpookyMasterChef.
  function poolInfoSpooky(uint256 _pid)
    public
    view
    returns (
      address,
      uint256,
      uint256,
      uint256
    )
  {
    return spookyMasterChef.poolInfo(_pid);
  }

  // Return allocation point for given pool in SpookyMasterChef.
  function allocPointSpooky(uint256 _pid) public view returns (uint256) {
    (, uint256 allocPoint, , ) = poolInfoSpooky(_pid);
    return allocPoint;
  }

  // Return booPerSecond for given pool
  function booPerSecondInPool(uint256 _pid) public view returns (uint256) {
    uint256 total = totalAllocPointSpooky();
    if (total == 0) return 0;
    return allocPointSpooky(_pid).mul(1e18).mul(1e18).div(total.mul(1e18)).mul(booPerSecond()).div(1e18);
  }

  // Return reward per year for given Spooky pool.
  function booPerYear(uint256 _pid) public view returns (uint256) {
    return booPerSecondInPool(_pid).mul(365 days);
  }

  // =============================== //

  // ===== Spiritswap function ===== //

  // Return SPIRIT price in USDC.
  function getSPIRITPrice() public view returns (uint256) {
    address spirit = spiritMasterChef.spirit();
    uint256 spiritPerNative = getTokenPerNative(spiritFactory.getPair(wNative, spirit));
    uint256 usdcPerNative = getTokenPerNative(spiritFactory.getPair(wNative, usdcToken));
    return usdcPerNative.mul(1e18).div(spiritPerNative);
  }

  // Return SPIRIT per block.
  function spiritPerBlock() public view returns (uint256) {
    return spiritMasterChef.spiritPerBlock();
  }

  // Return total allocation point of SpiritMasterChef.
  function totalAllocPointSpirit() public view returns (uint256) {
    return spiritMasterChef.totalAllocPoint();
  }

  // Return poolInfo of given pool in SpiritMasterChef.
  function poolInfoSpirit(uint256 _pid)
    public
    view
    returns (
      address,
      uint256,
      uint256,
      uint256,
      uint16
    )
  {
    return spiritMasterChef.poolInfo(_pid);
  }

  // Return allocation point for given pool in SpiritMasterChef.
  function allocPointSpirit(uint256 _pid) public view returns (uint256) {
    (, uint256 allocPoint, , , ) = poolInfoSpirit(_pid);
    return allocPoint;
  }

  // Return spiritPerBlock for given pool
  function spiritPerBlockInPool(uint256 _pid) public view returns (uint256) {
    uint256 total = totalAllocPointSpirit();
    if (total == 0) return 0;
    return allocPointSpirit(_pid).mul(1e18).mul(1e18).div(total.mul(1e18)).mul(spiritPerBlock()).div(1e18);
  }

  // Return reward per year for given Spirit pool. assume block time is 1 sec.
  function spiritPerYear(uint256 _pid) public view returns (uint256) {
    return spiritPerBlockInPool(_pid).mul(365 days);
  }

  // =============================== //

  // ===== Frontend function ===== //

  // ===== TVL function ===== //

  // Return Spookyswap worker TVL.
  function getTVLSpookyswap(address[] memory _workers) public view returns (address[] memory, uint256[] memory) {
    uint256 len = _workers.length;
    uint256[] memory tvl = new uint256[](len);
    address[] memory workersList = new address[](len);
    for (uint256 i = 0; i < len; i++) {
      address worker = _workers[i];
      uint256 _tvl = getPortionLPValueSpooky(worker).add(getPendingBOOValue(worker));
      tvl[i] = _tvl;
      workersList[i] = worker;
    }
    return (workersList, tvl);
  }

  // Return Spiritswap worker TVL.
  function getTVLSpiritswap(address[] memory _workers) public view returns (address[] memory, uint256[] memory) {
    uint256 len = _workers.length;
    uint256[] memory tvl = new uint256[](len);
    address[] memory workersList = new address[](len);
    for (uint256 i = 0; i < len; i++) {
      address worker = _workers[i];
      uint256 _tvl = getPortionLPValueSpirit(worker).add(getPendingSPIRITValue(worker));
      tvl[i] = _tvl;
      workersList[i] = worker;
    }
    return (workersList, tvl);
  }

  // Return TVL for given workers.
  function getWorkersTVL(address[] memory _workers) public view returns (address[] memory, uint256[] memory) {
    uint256 len = _workers.length;
    if (len > 0) {
      if (IWorker(_workers[0]).router() == spookyRouter) {
        return getTVLSpookyswap(_workers);
      } else if (IWorker(_workers[0]).router() == spiritRouter) {
        return getTVLSpiritswap(_workers);
      }
    }
  }

  // Return MeowLP TVL
  function getMeowLPTVL() public view returns (uint256) {
    address meowLp = spookyFactory.getPair(wNative, meowToken);
    if (meowLp == address(0)) return 0;
    return (IERC20(meowToken).balanceOf(meowLp)).mul(uint256(2)).mul(meowPrice()).div(1e36);
  }

  // Return Total Deposited on all Vaults.
  function getVaultsTVL() public view returns (uint256) {
    uint256 len = getVaultsLength();
    uint256 totalTVL = 0;
    if (len == 0) return 0;
    for (uint256 i = 0; i < len; i++) {
      address _vault = vaults[i];
      uint256 _decimals = uint256(IERC20(_vault).decimals());
      address _token = IVault(_vault).token();
      totalTVL = totalTVL.add((IERC20(_token).balanceOf(_vault)).mul(baseTokenPrice(_vault)).div(10**_decimals));
    }
    return totalTVL;
  }

  // Return total TVL of Spookyswap workers.
  function getTotalSpookyWorkersTVL() public view returns (uint256) {
    uint256 len = getSpookyWorkersLength();
    uint256 totalTVL = 0;
    if (len == 0) return 0;
    for (uint256 i = 0; i < len; i++) {
      address _worker = spookyWorkers[i];
      totalTVL = totalTVL.add(getPortionLPValueSpooky(_worker).add(getPendingBOOValue(_worker)));
    }
    return totalTVL;
  }

  // Return total TVL of Spiritswap workers.
  function getTotalSpiritWorkersTVL() public view returns (uint256) {
    uint256 len = getSpiritWorkersLength();
    uint256 totalTVL = 0;
    if (len == 0) return 0;
    for (uint256 i = 0; i < len; i++) {
      address _worker = spiritWorkers[i];
      totalTVL = totalTVL.add(getPortionLPValueSpirit(_worker).add(getPendingSPIRITValue(_worker)));
    }
    return totalTVL;
  }

  // Return total TVL of all workers.
  function getTotalWorkersTVL() public view returns (uint256) {
    return getTotalSpookyWorkersTVL().add(getTotalSpiritWorkersTVL());
  }

  // Return total TVL on Meow finance.
  function getTotalTVL() public view returns (uint256) {
    return getMeowLPTVL().add(getVaultsTVL()).add(getTotalWorkersTVL());
  }

  // ======================== //
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
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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
pragma solidity 0.6.12;

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

  /// @dev Return the address of MeowMining contract.
  function getMeowMiningAddr() external view returns (address);

  /// @dev Return the address of MMeowFee contract.
  function mMeowFee() external view returns (address);

  /// @dev Return the bps rate for reserve pool.
  function getReservePoolBps() external view returns (uint256);

  /// @dev Return the bps rate for Avada Kill caster.
  function getKillBps() external view returns (uint256);

  /// @dev Return if the caller is whitelisted.
  function whitelistedCallers(address caller) external view returns (bool);

  /// @dev Return if the caller is whitelisted bot.
  function whitelistedBots(address bot) external view returns (bool);

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
pragma solidity 0.6.12;

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
pragma solidity 0.6.12;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../apis/IUniswapV2Router02.sol";

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

  /// @dev Return address of router.
  function router() external view returns (IUniswapV2Router02);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../interfaces/ISpookyMasterChef.sol";

interface ISpookyWorker {
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

  /// @dev Return address of MasterChef.
  function masterChef() external view returns (ISpookyMasterChef);

  /// @dev Return address of BOOToken.
  function boo() external view returns (address);

  /// @dev Base Token that worker is working on
  function baseToken() external view returns (address);

  /// @dev Farming Token that worker is working on
  function farmingToken() external view returns (address);

  /// @dev Return the reward bounty for calling reinvest operation.
  function reinvestBountyBps() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ISpookyMasterChef {
  function boo() external view returns (address);

  function booPerSecond() external view returns (uint256);

  function deposit(uint256 _pid, uint256 _amount) external;

  function emergencyWithdraw(uint256 _pid) external;

  function pendingBOO(uint256 _pid, address _user) external view returns (uint256);

  function poolInfo(uint256)
    external
    view
    returns (
      address lpToken,
      uint256 allocPoint,
      uint256 lastRewardTime,
      uint256 accBOOPerShare
    );

  function poolLength() external view returns (uint256);

  function totalAllocPoint() external view returns (uint256);

  function userInfo(uint256, address) external view returns (uint256 amount, uint256 rewardDebt);

  function withdraw(uint256 _pid, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../interfaces/ISpiritMasterChef.sol";

interface ISpiritWorker {
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

  /// @dev Return address of MasterChef.
  function masterChef() external view returns (ISpiritMasterChef);

  /// @dev Return address of QuickToken.
  function spirit() external view returns (address);

  /// @dev Base Token that worker is working on
  function baseToken() external view returns (address);

  /// @dev Farming Token that worker is working on
  function farmingToken() external view returns (address);

  /// @dev Return the reward bounty for calling reinvest operation.
  function reinvestBountyBps() external view returns (uint256);
}

pragma solidity >=0.6.0 <0.8.0;

interface ISpiritMasterChef {
  function spirit() external view returns (address);

  function spiritPerBlock() external view returns (uint256);

  function deposit(uint256 _pid, uint256 _amount) external;

  function emergencyWithdraw(uint256 _pid) external;

  function pendingSpirit(uint256 _pid, address _user) external view returns (uint256);

  function poolInfo(uint256)
    external
    view
    returns (
      address lpToken,
      uint256 allocPoint,
      uint256 lastRewardBlock,
      uint256 accSpiritPerShare,
      uint16 depositFeeBP
    );

  function poolLength() external view returns (uint256);

  function totalAllocPoint() external view returns (uint256);

  function userInfo(uint256, address) external view returns (uint256 amount, uint256 rewardDebt);

  function withdraw(uint256 _pid, uint256 _amount) external;
}

pragma solidity 0.6.12;

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