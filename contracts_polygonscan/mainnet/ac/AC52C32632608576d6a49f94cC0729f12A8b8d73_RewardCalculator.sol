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

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../../base/governance/Controllable.sol";
import "../../base/interface/ISmartVault.sol";
import "../../base/interface/IStrategy.sol";
import "../../base/interface/IBookkeeper.sol";
import "../../base/interface/IControllableExtended.sol";
import "../../third_party/wault/IWexPolyMaster.sol";
import "../../third_party/sushi/IMiniChefV2.sol";
import "../../third_party/iron/IIronChef.sol";
import "../../third_party/hermes/IIrisMasterChef.sol";
import "../../third_party/synthetix/SNXRewardInterface.sol";
import "../../base/interface/IMasterChefStrategyCafe.sol";
import "../../base/interface/IMasterChefStrategyV1.sol";
import "../../base/interface/IMasterChefStrategyV2.sol";
import "../../base/interface/IMasterChefStrategyV3.sol";
import "../../base/interface/IIronFoldStrategy.sol";
import "../../base/interface/ISNXStrategy.sol";
import "../../base/interface/IStrategyWithPool.sol";
import "../../third_party/cosmic/ICosmicMasterChef.sol";
import "../../third_party/dino/IFossilFarms.sol";
import "../price/IPriceCalculator.sol";
import "./IRewardCalculator.sol";
import "../../third_party/quick/IDragonLair.sol";
import "../../third_party/quick/IStakingDualRewards.sol";
import "../../third_party/iron/IronControllerInterface.sol";
import "../../third_party/iron/CompleteRToken.sol";

/// @title Calculate estimated strategy rewards
/// @author belbix
contract RewardCalculator is Controllable, IRewardCalculator {

  // ************** CONSTANTS *****************************
  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant VERSION = "1.4.0";
  uint256 public constant PRECISION = 1e18;
  uint256 public constant MULTIPLIER_DENOMINATOR = 100;
  uint256 public constant BLOCKS_PER_MINUTE = 2727; // 27.27
  string private constant _CALCULATOR = "calculator";
  address public constant D_QUICK = address(0xf28164A485B0B2C90639E47b0f377b4a438a16B1);
  uint256 private constant _BUY_BACK_DENOMINATOR = 10000;
  uint256 public constant AVG_REWARDS = 7;
  uint256 public constant LAST_EARNED = 3;

  // ************** VARIABLES *****************************
  // !!!!!!!!! DO NOT CHANGE NAMES OR ORDERING!!!!!!!!!!!!!
  mapping(bytes32 => address) internal tools;
  mapping(IStrategy.Platform => uint256) internal platformMultiplier;
  mapping(uint256 => uint256) internal platformMultiplierV2;

  function initialize(address _controller, address _calculator) external initializer {
    Controllable.initializeControllable(_controller);
    tools[keccak256(abi.encodePacked(_CALCULATOR))] = _calculator;
  }

  // ************* MAIN ***********************************

  function priceCalculator() public view returns (IPriceCalculator) {
    return IPriceCalculator(tools[keccak256(abi.encodePacked(_CALCULATOR))]);
  }

  function getPrice(address _token) public view override returns (uint256) {
    return priceCalculator().getPriceWithDefaultOutput(_token);
  }

  function strategyRewardsUsd(address _strategy, uint256 _period) public view override returns (uint256) {
    return rewardBasedOnBuybacks(_strategy) * _period;
    //    IStrategy strategy = IStrategy(_strategy);
    //    if (strategy.rewardTokens().length == 0) {
    //      return 0;
    //    }
    //    uint256 rewardsPerSecond = 0;
    //    if (strategy.platform() == IStrategy.Platform.QUICK) {
    //
    //      if (strategy.rewardTokens().length == 2) {
    //        rewardsPerSecond = quickDualFarm(IStrategyWithPool(_strategy).pool());
    //      } else {
    //        rewardsPerSecond = quick(address(ISNXStrategy(_strategy).rewardPool()));
    //      }
    //
    //    } else if (strategy.platform() == IStrategy.Platform.SUSHI) {
    //
    //      IMasterChefStrategyV3 mc = IMasterChefStrategyV3(_strategy);
    //      rewardsPerSecond = miniChefSushi(mc.mcRewardPool(), mc.poolID());
    //
    //    } else if (strategy.platform() == IStrategy.Platform.WAULT) {
    //
    //      IMasterChefStrategyV2 mc = IMasterChefStrategyV2(_strategy);
    //      rewardsPerSecond = wault(mc.pool(), mc.poolID());
    //
    //    } else if (strategy.platform() == IStrategy.Platform.IRON) {
    //
    //      IMasterChefStrategyV3 mc = IMasterChefStrategyV3(_strategy);
    //      rewardsPerSecond = ironMc(mc.mcRewardPool(), mc.poolID());
    //
    //    } else if (strategy.platform() == IStrategy.Platform.COSMIC) {
    //
    //      IMasterChefStrategyV1 mc = IMasterChefStrategyV1(_strategy);
    //      rewardsPerSecond = cosmic(mc.masterChefPool(), mc.poolID());
    //
    //    } else if (strategy.platform() == IStrategy.Platform.DINO) {
    //
    //      IMasterChefStrategyV2 mc = IMasterChefStrategyV2(_strategy);
    //      rewardsPerSecond = dino(mc.pool(), mc.poolID());
    //
    //    } else if (strategy.platform() == IStrategy.Platform.IRON_LEND) {
    //      // we already have usd rate
    //      rewardsPerSecond = ironLending(strategy);
    //
    //    } else if (strategy.platform() == IStrategy.Platform.HERMES) {
    //
    //      IMasterChefStrategyV2 mc = IMasterChefStrategyV2(_strategy);
    //      rewardsPerSecond = hermes(mc.pool(), mc.poolID());
    //
    //    } else if (strategy.platform() == IStrategy.Platform.CAFE) {
    //
    //      IMasterChefStrategyCafe mc = IMasterChefStrategyCafe(_strategy);
    //      rewardsPerSecond = cafe(address(mc.masterChefPool()), mc.poolID());
    //
    //    } else {
    //      return rewardBasedOnBuybacks(_strategy) * _period;
    //    }
    //
    //    rewardsPerSecond = adjustRewardPerSecond(rewardsPerSecond, strategy);
    //
    //    // return precalculated rates
    //    if (strategy.platform() == IStrategy.Platform.IRON_LEND) {
    //      return _period * rewardsPerSecond;
    //    }
    //
    //    uint256 rtPrice = getPrice(strategy.rewardTokens()[0]);
    //
    //    uint256 result = _period * rewardsPerSecond * rtPrice / PRECISION;
    //    if (strategy.rewardTokens().length == 2) {
    //      if (strategy.platform() == IStrategy.Platform.SUSHI) {
    //        IMasterChefStrategyV3 mc = IMasterChefStrategyV3(_strategy);
    //        uint256 rewardsPerSecond2 = mcRewarder(mc.mcRewardPool(), mc.poolID());
    //        uint256 rtPrice2 = priceCalculator().getPriceWithDefaultOutput(strategy.rewardTokens()[1]);
    //        result += _period * rewardsPerSecond2 * rtPrice2 / PRECISION;
    //      } else if (strategy.platform() == IStrategy.Platform.QUICK) {
    //        uint256 rtPrice2 = priceCalculator().getPriceWithDefaultOutput(strategy.rewardTokens()[1]);
    //        result += IStakingDualRewards(IStrategyWithPool(_strategy).pool()).rewardRateB() * rtPrice2 / PRECISION;
    //      }
    //    }
    //    return result;
  }

  function adjustRewardPerSecond(uint rewardsPerSecond, IStrategy strategy) public view returns (uint) {
    if (strategy.buyBackRatio() < _BUY_BACK_DENOMINATOR) {
      rewardsPerSecond = rewardsPerSecond * strategy.buyBackRatio() / _BUY_BACK_DENOMINATOR;
    }

    uint256 _kpi = kpi(strategy.vault());
    uint256 multiplier = platformMultiplierV2[uint256(strategy.platform())];

    if (_kpi != 0) {
      rewardsPerSecond = rewardsPerSecond * _kpi / PRECISION;
    } else {
      // no rewards for strategies without profit
      return 0;
    }

    if (multiplier != 0) {
      rewardsPerSecond = rewardsPerSecond * multiplier / MULTIPLIER_DENOMINATOR;
    }
    return rewardsPerSecond;
  }

  /// @dev Return recommended USD amount of rewards for this vault based on TVL ratio
  function rewardsPerTvl(address _vault, uint256 _period) public view override returns (uint256) {
    ISmartVault vault = ISmartVault(_vault);
    uint256 rewardAmount = strategyRewardsUsd(vault.strategy(), _period);
    uint256 ratio = vaultTVLRatio(_vault);
    return rewardAmount * ratio / PRECISION;
  }

  function vaultTVLRatio(address _vault) public view override returns (uint256) {
    ISmartVault vault = ISmartVault(_vault);
    uint256 poolTvl = IStrategy(vault.strategy()).poolTotalAmount();
    if (poolTvl == 0) {
      return 0;
    }
    return vault.underlyingBalanceWithInvestment() * PRECISION / poolTvl;
  }

  function rewardPerBlockToPerSecond(uint256 amount) public pure returns (uint256) {
    return amount * BLOCKS_PER_MINUTE / 6000;
  }

  function mcRewardPerSecond(
    uint256 allocPoint,
    uint256 rewardPerSecond,
    uint256 totalAllocPoint
  ) public pure returns (uint256) {
    return rewardPerSecond * allocPoint / totalAllocPoint;
  }

  function kpi(address _vault) public view override returns (uint256) {
    ISmartVault vault = ISmartVault(_vault);
    if (vault.duration() == 0) {
      return 0;
    }

    uint256 lastRewards = vaultLastTetuReward(_vault);
    if (lastRewards == 0) {
      return 0;
    }

    (uint256 earned,) = strategyEarnedSinceLastDistribution(vault.strategy());

    return PRECISION * earned / lastRewards;
  }

  function vaultLastTetuReward(address _vault) public view override returns (uint256) {
    IBookkeeper bookkeeper = IBookkeeper(IController(controller()).bookkeeper());
    ISmartVault ps = ISmartVault(IController(controller()).psVault());
    uint256 rewardsSize = bookkeeper.vaultRewardsLength(_vault, address(ps));
    uint rewardSum = 0;
    if (rewardsSize > 0) {
      uint count = 0;
      for (uint i = 1; i <= Math.min(AVG_REWARDS, rewardsSize); i++) {
        rewardSum += vaultTetuReward(_vault, rewardsSize - i);
        count++;
      }
      return rewardSum / count;
    }
    return 0;
  }

  function vaultTetuReward(address _vault, uint i) public view returns (uint256) {
    IBookkeeper bookkeeper = IBookkeeper(IController(controller()).bookkeeper());
    ISmartVault ps = ISmartVault(IController(controller()).psVault());
    uint amount = bookkeeper.vaultRewards(_vault, address(ps), i);
    // we distributed xTETU, need to calculate approx TETU amount
    // assume that xTETU ppfs didn't change dramatically
    return amount * ps.getPricePerFullShare() / ps.underlyingUnit();
  }

  function strategyEarnedSinceLastDistribution(address strategy)
  public view override returns (uint256 earned, uint256 lastEarnedTs){
    IBookkeeper bookkeeper = IBookkeeper(IController(controller()).bookkeeper());
    uint256 lastEarned = 0;
    lastEarnedTs = 0;
    earned = 0;

    uint256 earnedSize = bookkeeper.strategyEarnedSnapshotsLength(strategy);
    if (earnedSize > 0) {
      lastEarned = bookkeeper.strategyEarnedSnapshots(strategy, earnedSize - 1);
      lastEarnedTs = bookkeeper.strategyEarnedSnapshotsTime(strategy, earnedSize - 1);
    }
    lastEarnedTs = Math.max(lastEarnedTs, IControllableExtended(strategy).created());
    uint256 currentEarned = bookkeeper.targetTokenEarned(strategy);
    if (currentEarned >= lastEarned) {
      earned = currentEarned - lastEarned;
    }
  }

  function strategyEarnedAvg(address strategy)
  public view returns (uint256 earned, uint256 lastEarnedTs){
    IBookkeeper bookkeeper = IBookkeeper(IController(controller()).bookkeeper());
    uint256 lastEarned = 0;
    lastEarnedTs = 0;
    earned = 0;

    uint256 earnedSize = bookkeeper.strategyEarnedSnapshotsLength(strategy);
    uint i = Math.min(earnedSize, LAST_EARNED);
    if (earnedSize > 0) {
      lastEarned = bookkeeper.strategyEarnedSnapshots(strategy, earnedSize - i);
      lastEarnedTs = bookkeeper.strategyEarnedSnapshotsTime(strategy, earnedSize - i);
    }
    lastEarnedTs = Math.max(lastEarnedTs, IControllableExtended(strategy).created());
    uint256 currentEarned = bookkeeper.targetTokenEarned(strategy);
    if (currentEarned >= lastEarned) {
      earned = currentEarned - lastEarned;
    }
  }

  function rewardBasedOnBuybacks(address strategy) public view returns (uint256){
    uint lastHw = IBookkeeper(IController(controller()).bookkeeper()).lastHardWork(strategy).time;
    (uint256 earned, uint256 lastEarnedTs) = strategyEarnedAvg(strategy);
    uint timeDiff = block.timestamp - lastEarnedTs;
    if (lastEarnedTs == 0 || timeDiff == 0 || lastHw == 0 || (block.timestamp - lastHw) > 3 days) {
      return 0;
    }
    uint256 tetuPrice = getPrice(IController(controller()).rewardToken());
    uint earnedUsd = earned * tetuPrice / PRECISION;
    uint rewardsPerSecond = earnedUsd / timeDiff;

    uint256 multiplier = platformMultiplierV2[uint256(IStrategy(strategy).platform())];
    if (multiplier != 0) {
      rewardsPerSecond = rewardsPerSecond * multiplier / MULTIPLIER_DENOMINATOR;
    }
    return rewardsPerSecond;
  }

  // ************* SPECIFIC TO STRATEGY FUNCTIONS *************

  /// @notice Calculate approximately rewards amounts for Wault Swap
  function wault(address _pool, uint256 _poolID) public view returns (uint256) {
    IWexPolyMaster pool = IWexPolyMaster(_pool);
    (, uint256 allocPoint,,) = pool.poolInfo(_poolID);
    return mcRewardPerSecond(
      allocPoint,
      rewardPerBlockToPerSecond(pool.wexPerBlock()),
      pool.totalAllocPoint()
    );
  }

  /// @notice Calculate approximately rewards amounts for Cosmic Swap
  function cosmic(address _pool, uint256 _poolID) public view returns (uint256) {
    ICosmicMasterChef pool = ICosmicMasterChef(_pool);
    ICosmicMasterChef.PoolInfo memory info = pool.poolInfo(_poolID);
    return mcRewardPerSecond(
      info.allocPoint,
      rewardPerBlockToPerSecond(pool.cosmicPerBlock()),
      pool.totalAllocPoint()
    );
  }

  /// @notice Calculate approximately rewards amounts for Dino Swap
  function dino(address _pool, uint256 _poolID) public view returns (uint256) {
    IFossilFarms pool = IFossilFarms(_pool);
    (, uint256 allocPoint,,) = pool.poolInfo(_poolID);
    return mcRewardPerSecond(
      allocPoint,
      rewardPerBlockToPerSecond(pool.dinoPerBlock()),
      pool.totalAllocPoint()
    );
  }

  /// @notice Calculate approximately rewards amounts for SushiSwap
  function miniChefSushi(address _pool, uint256 _poolID) public view returns (uint256) {
    IMiniChefV2 pool = IMiniChefV2(_pool);
    (,, uint256 allocPoint) = pool.poolInfo(_poolID);
    return mcRewardPerSecond(
      allocPoint,
      pool.sushiPerSecond(),
      pool.totalAllocPoint()
    );
  }

  /// @notice Calculate approximately rewards amounts for Sushi rewarder
  function mcRewarder(address _pool, uint256 _poolID) public view returns (uint256) {
    IMiniChefV2 pool = IMiniChefV2(_pool);
    IRewarder rewarder = pool.rewarder(_poolID);
    (,, uint256 allocPoint) = rewarder.poolInfo(_poolID);
    return mcRewardPerSecond(
      allocPoint,
      rewarder.rewardPerSecond(), // totalAllocPoint is not public so assume that it is the same as MC
      pool.totalAllocPoint()
    );
  }

  /// @notice Calculate approximately reward amounts for Iron MC
  function ironMc(address _pool, uint256 _poolID) public view returns (uint256) {
    IIronChef.PoolInfo memory poolInfo = IIronChef(_pool).poolInfo(_poolID);
    return mcRewardPerSecond(
      poolInfo.allocPoint,
      IIronChef(_pool).rewardPerSecond(),
      IIronChef(_pool).totalAllocPoint()
    );
  }

  /// @notice Calculate approximately reward amounts for HERMES
  function hermes(address _pool, uint256 _poolID) public view returns (uint256) {
    IIrisMasterChef pool = IIrisMasterChef(_pool);
    (, uint256 allocPoint,,,,) = pool.poolInfo(_poolID);
    return mcRewardPerSecond(
      allocPoint,
      rewardPerBlockToPerSecond(pool.irisPerBlock()),
      pool.totalAllocPoint()
    );
  }

  /// @notice Calculate approximately reward amounts for Cafe swap
  function cafe(address _pool, uint256 _poolID) public view returns (uint256) {
    ICafeMasterChef pool = ICafeMasterChef(_pool);
    ICafeMasterChef.PoolInfo memory info = pool.poolInfo(_poolID);
    return mcRewardPerSecond(
      info.allocPoint,
      rewardPerBlockToPerSecond(pool.brewPerBlock()),
      pool.totalAllocPoint()
    );
  }

  /// @notice Calculate approximately reward amounts for Quick swap
  function quick(address _pool) public view returns (uint256) {
    if (SNXRewardInterface(_pool).periodFinish() < block.timestamp) {
      return 0;
    }
    uint256 dQuickRatio = IDragonLair(D_QUICK).QUICKForDQUICK(PRECISION);
    return SNXRewardInterface(_pool).rewardRate() * dQuickRatio / PRECISION;
  }

  /// @notice Calculate approximately reward amounts for Quick swap
  function quickDualFarm(address _pool) public view returns (uint256) {
    if (IStakingDualRewards(_pool).periodFinish() < block.timestamp) {
      return 0;
    }
    uint256 dQuickRatio = IDragonLair(D_QUICK).QUICKForDQUICK(PRECISION);
    return IStakingDualRewards(_pool).rewardRateA() * dQuickRatio / PRECISION;
  }

  function ironLending(IStrategy strategy) public view returns (uint256) {
    address iceToken = strategy.rewardTokens()[0];
    address rToken = IIronFoldStrategy(address(strategy)).rToken();
    address controller = IIronFoldStrategy(address(strategy)).ironController();

    uint icePrice = getPrice(iceToken);
    uint undPrice = getPrice(strategy.underlying());

    uint8 undDecimals = CompleteRToken(strategy.underlying()).decimals();

    uint256 rTokenExchangeRate = CompleteRToken(rToken).exchangeRateStored();

    uint256 totalSupply = CompleteRToken(rToken).totalSupply() * rTokenExchangeRate
    / (10 ** undDecimals);

    uint suppliedRate = CompleteRToken(rToken).supplyRatePerBlock() * undPrice * totalSupply / (PRECISION ** 2);
    // ICE rewards
    uint rewardSpeed = IronControllerInterface(controller).rewardSpeeds(rToken) * icePrice / PRECISION;
    // regarding folding we will earn x2.45
    rewardSpeed = rewardSpeed * 245 / 100;
    return rewardPerBlockToPerSecond(rewardSpeed + suppliedRate);
  }

  // *********** GOVERNANCE ACTIONS *****************

  function setPriceCalculator(address newValue) external onlyControllerOrGovernance {
    tools[keccak256(abi.encodePacked(_CALCULATOR))] = newValue;
    emit ToolAddressUpdated(_CALCULATOR, newValue);
  }

  function setPlatformMultiplier(uint256 _platform, uint256 _value) external onlyControllerOrGovernance {
    require(_value < MULTIPLIER_DENOMINATOR * 10, "RC: Too high value");
    platformMultiplierV2[_platform] = _value;
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

interface ISmartVault {

  function setStrategy(address _strategy) external;

  function changeActivityStatus(bool _active) external;

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

  function userLastWithdrawTs(address _user) external returns (uint256);

  function userLastDepositTs(address _user) external returns (uint256);

  function userBoostTs(address _user) external returns (uint256);

  function userLockTs(address _user) external returns (uint256);

  function addRewardToken(address rt) external;

  function removeRewardToken(address rt) external;

  function stop() external;

  function ppfsDecreaseAllowed() external view returns (bool);

  function lockPeriod() external view returns (uint256);

  function lockPenalty() external view returns (uint256);

  function toInvest() external view returns (uint256);

  function lockAllowed() external view returns (bool);
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
    AAVE_LEND //14

  }

  // *************** GOVERNANCE ACTIONS **************
  function STRATEGY_NAME() external view returns (string memory);

  function withdrawAllToVault() external;

  function withdrawToVault(uint256 amount) external;

  function salvage(address recipient, address token, uint256 amount) external;

  function doHardWork() external;

  function investAllUnderlying() external;

  function emergencyExit() external;

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

interface IBookkeeper {

  struct PpfsChange {
    address vault;
    uint256 block;
    uint256 time;
    uint256 value;
    uint256 oldBlock;
    uint256 oldTime;
    uint256 oldValue;
  }

  struct HardWork {
    address strategy;
    uint256 block;
    uint256 time;
    uint256 targetTokenAmount;
  }

  function addVault(address _vault) external;

  function addStrategy(address _strategy) external;

  function registerStrategyEarned(uint256 _targetTokenAmount) external;

  function registerFundKeeperEarned(address _token, uint256 _fundTokenAmount) external;

  function registerUserAction(address _user, uint256 _amount, bool _deposit) external;

  function registerVaultTransfer(address from, address to, uint256 amount) external;

  function registerUserEarned(address _user, address _vault, address _rt, uint256 _amount) external;

  function registerPpfsChange(address vault, uint256 value) external;

  function registerRewardDistribution(address vault, address token, uint256 amount) external;

  function vaults() external view returns (address[] memory);

  function vaultsLength() external view returns (uint256);

  function strategies() external view returns (address[] memory);

  function strategiesLength() external view returns (uint256);

  function lastPpfsChange(address vault) external view returns (PpfsChange memory);

  /// @notice Return total earned TETU tokens for strategy
  /// @dev Should be incremented after strategy rewards distribution
  /// @param strategy Strategy address
  /// @return Earned TETU tokens
  function targetTokenEarned(address strategy) external view returns (uint256);

  /// @notice Return share(xToken) balance of given user
  /// @dev Should be calculated for each xToken transfer
  /// @param vault Vault address
  /// @param user User address
  /// @return User share (xToken) balance
  function vaultUsersBalances(address vault, address user) external view returns (uint256);

  /// @notice Return earned token amount for given token and user
  /// @dev Fills when user claim rewards
  /// @param user User address
  /// @param vault Vault address
  /// @param token Token address
  /// @return User's earned tokens amount
  function userEarned(address user, address vault, address token) external view returns (uint256);

  function lastHardWork(address vault) external view returns (HardWork memory);

  /// @notice Return users quantity for given Vault
  /// @dev Calculation based in Bookkeeper user balances
  /// @param vault Vault address
  /// @return Users quantity
  function vaultUsersQuantity(address vault) external view returns (uint256);

  function fundKeeperEarned(address vault) external view returns (uint256);

  function vaultRewards(address vault, address token, uint256 idx) external view returns (uint256);

  function vaultRewardsLength(address vault, address token) external view returns (uint256);

  function strategyEarnedSnapshots(address strategy, uint256 idx) external view returns (uint256);

  function strategyEarnedSnapshotsTime(address strategy, uint256 idx) external view returns (uint256);

  function strategyEarnedSnapshotsLength(address strategy) external view returns (uint256);
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

/// @dev This interface contains additional functions for Controllable class
///      Don't extend exist Controllable for the reason huge coherence
interface IControllableExtended {

  function created() external view returns (uint256 ts);

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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWexPolyMaster {

  function deposit(uint256 _pid, uint256 _amount, bool _withdrawRewards) external;

  function withdraw(uint256 _pid, uint256 _amount, bool _withdrawRewards) external;

  function emergencyWithdraw(uint256 _pid) external;

  function claim(uint256 _pid) external;

  // *********** VIEWS ***********

  function poolLength() external view returns (uint256);

  function getMultiplier(uint256 _from, uint256 _to) external pure returns (uint256);

  function wexPerBlock() external view returns (uint256);

  function totalAllocPoint() external view returns (uint256);

  function startBlock() external view returns (uint256);

  function pendingWex(uint256 _pid, address _user) external view returns (uint256);

  function poolInfo(uint256 _pid) external view returns (
    IERC20 lpToken,
    uint256 allocPoint,
    uint256 lastRewardBlock,
    uint256 accWexPerShare
  );

  function userInfo(uint256 _pid, address _user) external view returns (
    uint256 amount,
    uint256 rewardDebt,
    uint256 pendingRewards
  );

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

import "./IRewarder.sol";

interface IMiniChefV2 {

  function rewarder(uint256 _pid) external view returns (IRewarder);

  function deposit(uint256 _pid, uint256 _amount, address to) external;

  function withdraw(uint256 _pid, uint256 _amount, address to) external;

  function harvest(uint256 _pid, address to) external;

  function withdrawAndHarvest(uint256 _pid, uint256 _amount, address to) external;

  function emergencyWithdraw(uint256 _pid, address to) external;

  // **************** VIEWS ***************

  function userInfo(uint256 _pid, address _user)
  external view returns (uint256 amount, uint256 rewardDebt);

  function lpToken(uint256 _pid) external view returns (address);

  function poolLength() external view returns (uint256);

  function sushiPerSecond() external view returns (uint256);

  function totalAllocPoint() external view returns (uint256);

  function poolInfo(uint256 _pid)
  external view returns (uint256 accSushiPerShare, uint256 lastRewardTime, uint256 allocPoint);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

interface IIronChef {

  struct UserInfo {
    uint256 amount;
    int256 rewardDebt;
  }

  struct PoolInfo {
    uint256 accRewardPerShare;
    uint256 lastRewardTime;
    uint256 allocPoint;
  }

  function reward() external view returns (address);

  function fund() external view returns (address);

  /// @notice Info of each MCV2 pool.
  function poolInfo(uint256 index) external view returns (PoolInfo memory);

  /// @notice Address of the LP token for each MCV2 pool.
  function lpToken(uint256 index) external view returns (address);

  /// @notice Address of each `IRewarder` contract in MCV2.
  function rewarder(uint256 index) external view returns (address);

  /// @notice Info of each user that stakes LP tokens.
  function userInfo(uint256 _pid, address _user) external view returns (UserInfo memory);

  /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
  function totalAllocPoint() external view returns (uint256);

  function rewardPerSecond() external view returns (uint256);

  /// @notice Returns the number of MCV2 pools.
  function poolLength() external view returns (uint256);

  /// @notice View function to see pending reward on frontend.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _user Address of user.
  /// @return Pending reward for a given user.
  function pendingReward(uint256 _pid, address _user) external view returns (uint256);

  /// @notice Update reward variables of the given pool.
  /// @param pid The index of the pool. See `poolInfo`.
  /// @return pool Returns the pool that was updated.
  function updatePool(uint256 pid) external returns (PoolInfo memory pool);

  /// @notice Update reward variables for all pools. Be careful of gas spending!
  /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
  function massUpdatePools(uint256[] calldata pids) external;

  /// @notice Deposit LP tokens to MCV2 for reward allocation.
  /// @param pid The index of the pool. See `poolInfo`.
  /// @param amount LP token amount to deposit.
  /// @param to The receiver of `amount` deposit benefit.
  function deposit(uint256 pid, uint256 amount, address to) external;

  /// @notice Withdraw LP tokens from MCV2.
  /// @param pid The index of the pool. See `poolInfo`.
  /// @param amount LP token amount to withdraw.
  /// @param to Receiver of the LP tokens.
  function withdraw(uint256 pid, uint256 amount, address to) external;

  /// @notice Harvest proceeds for transaction sender to `to`.
  /// @param pid The index of the pool. See `poolInfo`.
  /// @param to Receiver of rewards.
  function harvest(uint256 pid, address to) external;

  /// @notice Withdraw LP tokens from MCV2 and harvest proceeds for transaction sender to `to`.
  /// @param pid The index of the pool. See `poolInfo`.
  /// @param amount LP token amount to withdraw.
  /// @param to Receiver of the LP tokens and rewards.
  function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;

  /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
  /// @param pid The index of the pool. See `poolInfo`.
  /// @param to Receiver of the LP tokens.
  function emergencyWithdraw(uint256 pid, address to) external;

  function harvestAllRewards(address to) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IReferral {
  /**
   * @dev Record referral.
   */
  function recordReferral(address user, address referrer) external;

  /**
   * @dev Get the referrer address that referred the user.
   */
  function getReferrer(address user) external view returns (address);
}

interface IIrisMasterChef {
  // Info of each user.
  struct UserInfo {
    uint256 amount;         // How many LP tokens the user has provided.
    uint256 rewardDebt;     // Reward debt. See explanation below.
    //
    // We do some fancy math here. Basically, any point in time, the amount of IRIS
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.amount * pool.accIrisPerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The pool's `accIrisPerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
  }

  // Info of each pool.
  struct PoolInfo {
    IERC20 lpToken;           // Address of LP token contract.
    uint256 allocPoint;       // How many allocation points assigned to this pool. IRISes to distribute per block.
    uint256 lastRewardBlock;  // Last block number that IRISes distribution occurs.
    uint256 accIrisPerShare;   // Accumulated IRISes per share, times 1e18. See below.
    uint16 depositFeeBP;      // Deposit fee in basis points
    uint256 lpSupply;
  }

  // The IRIS TOKEN!
  //    IrisToken public iris;
  //    address public devAddress;
  //    address public feeAddress;
  //    uint256 constant max_iris_supply = 1000000 ether;

  // IRIS tokens created per block.
  //    uint256 public irisPerBlock = 0.4 ether;

  // Info of each pool.
  //    PoolInfo[] public poolInfo;
  function poolInfo(uint256 _pid)
  external view returns (
    IERC20 lpToken,
    uint256 allocPoint,
    uint256 lastRewardBlock,
    uint256 accIrisPerShare,
    uint16 depositFeeBP,
    uint256 lpSupply
  );
  // IRIS tokens created per block.
  function irisPerBlock() external view returns (uint256);
  // The block number at which IRIS distribution starts.
  function startBlock() external view returns (uint256);
  // The block number at which IRIS distribution ends.
  function endBlock() external view returns (uint256);

  function totalAllocPoint() external view returns (uint256); // Total allocation points. Must be the sum of all allocation points in all pools.

  // Info of each user that stakes LP tokens.
  function userInfo(uint256 _pid, address _user)
  external view returns (
    uint256 amount,
    uint256 rewardDebt
  );


  // Iris referral contract address.
  //    IReferral public referral;
  // Referral commission rate in basis points.
  //    uint16 public referralCommissionRate = 200;
  // Max referral commission rate: 5%.
  //    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 500;
  //    uint256 public constant MAXIMUM_EMISSION_RATE = 1 ether;

  function poolLength() external view returns (uint256);

  // Add a new lp to the pool. Can only be called by the owner.
  function add(uint256 _allocPoint, address _lpToken, uint16 _depositFeeBP) external;

  // Update the given pool's IRIS allocation point and deposit fee. Can only be called by the owner.
  function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP) external;

  // Return reward multiplier over the given _from to _to block.
  function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);

  // View function to see pending IRISes on frontend.
  function pendingIris(uint256 _pid, address _user) external view returns (uint256);

  // Update reward variables for all pools. Be careful of gas spending!
  function massUpdatePools() external;

  // Update reward variables of the given pool to be up-to-date.
  function updatePool(uint256 _pid) external;

  // Deposit LP tokens to MasterChef for IRIS allocation.
  function deposit(uint256 _pid, uint256 _amount, address _referrer) external;

  // Withdraw LP tokens from MasterChef.
  function withdraw(uint256 _pid, uint256 _amount) external;

  // Withdraw without caring about rewards. EMERGENCY ONLY.
  function emergencyWithdraw(uint256 _pid) external;

  // Update dev address by the previous dev.
  function setDevAddress(address _devAddress) external;

  function setFeeAddress(address _feeAddress) external;

  function updateEmissionRate(uint256 _irisPerBlock) external;

  // Update the referral contract address by the owner
  function setReferralAddress(IReferral _referral) external;

  // Update referral commission rate by the owner
  function setReferralCommissionRate(uint16 _referralCommissionRate) external;

  // Only update before start of farm
  function updateStartBlock(uint256 _startBlock) external;
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

interface SNXRewardInterface {
  function withdraw(uint) external;

  function getReward() external;

  function stake(uint) external;

  function exit() external;

  function balanceOf(address) external view returns (uint256);

  function earned(address account) external view returns (uint256);

  function periodFinish() external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function lastUpdateTime() external view returns (uint256);

  function rewardRate() external view returns (uint256);

  function stakingToken() external view returns (address);

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

import "../../third_party/cafe/ICafeMasterChef.sol";

interface IMasterChefStrategyCafe {

  function masterChefPool() external view returns (ICafeMasterChef);

  function poolID() external view returns (uint256);

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

interface IMasterChefStrategyV1 {

  function masterChefPool() external view returns (address);

  function poolID() external view returns (uint256);

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

interface IMasterChefStrategyV2 {

  function pool() external view returns (address);

  function poolID() external view returns (uint256);

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

interface IMasterChefStrategyV3 {

  function mcRewardPool() external view returns (address);

  function poolID() external view returns (uint256);

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

interface IIronFoldStrategy {

  function rToken() external view returns (address);

  function ironController() external view returns (address);

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
import "../../third_party/synthetix/SNXRewardInterface.sol";

interface ISNXStrategy {

  function rewardPool() external view returns (SNXRewardInterface);

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

interface IStrategyWithPool {

  function pool() external view returns (address);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

interface ICosmicMasterChef {

  // Info of each user.
  struct UserInfo {
    uint256 amount;         // How many LP tokens the user has provided.
    uint256 rewardDebt;     // Reward debt. See explanation below.
    //
    // We do some fancy math here. Basically, any point in time, the amount of COSMICs
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.amount * pool.accCosmicPerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The pool's `accCosmicPerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
  }

  // Info of each pool.
  struct PoolInfo {
    address lpToken;           // Address of LP token contract.
    uint256 allocPoint;       // How many allocation points assigned to this pool. COSMICs to distribute per block.
    uint256 lastRewardBlock;  // Last block number that COSMICs distribution occurs.
    uint256 accCosmicPerShare;   // Accumulated COSMICs per share, times 1e12. See below.
    uint16 depositFeeBP;      // Deposit fee in basis points
  }

  function cosmic() external view returns (address);

  function devAddress() external view returns (address);

  function feeAddress() external view returns (address);

  function cosmicPerBlock() external view returns (uint256);

  function BONUS_MULTIPLIER() external view returns (uint256);

  function INITIAL_EMISSION_RATE() external view returns (uint256);

  function MINIMUM_EMISSION_RATE() external view returns (uint256);

  function EMISSION_REDUCTION_PERIOD_BLOCKS() external view returns (uint256);

  function EMISSION_REDUCTION_RATE_PER_PERIOD() external view returns (uint256);

  function lastReductionPeriodIndex() external view returns (uint256);

  function poolInfo(uint256 _pid) external view returns (PoolInfo memory);

  function userInfo(uint256 _pid, address _user) external view returns (UserInfo memory);

  function totalAllocPoint() external view returns (uint256);

  function startBlock() external view returns (uint256);

  function cosmicReferral() external view returns (address);

  function referralCommissionRate() external view returns (uint256);

  function MAXIMUM_REFERRAL_COMMISSION_RATE() external view returns (uint256);

  function poolLength() external view returns (uint256);

  function pendingCosmic(uint256 _pid, address _user) external view returns (uint256);

  function deposit(uint256 _pid, uint256 _amount, address _referrer) external;

  function withdraw(uint256 _pid, uint256 _amount) external;

  function emergencyWithdraw(uint256 _pid) external;
}

// SPDX-License-Identifier: MIT
// Original contract: https://github.com/DinoSwap/fossil-farms-contract/blob/main/FossilFarms.sol
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFossilFarms {

    // IERC20 public DINO;                 // DINO token

    // Info of each pool.
    function poolInfo(uint256 _pid)
    external view returns (
        IERC20 lpToken,
        uint256 allocPoint,
        uint256 lastRewardBlock,
        uint256 accDinoPerShare
    );
    // DINO tokens created per block.
    function dinoPerBlock() external view returns (uint256);
    // The block number at which DINO distribution starts.
    function startBlock() external view returns (uint256);
    // The block number at which DINO distribution ends.
    function endBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256); // Total allocation points. Must be the sum of all allocation points in all pools.

    // Info of each user that stakes LP tokens.
    function userInfo(uint256 _pid, address _user)
    external view returns (
        uint256 amount,
        uint256 rewardDebt
    );

    /**
     * @dev View function to see pending DINO on frontend.
     * @param _pid ID of a specific LP token pool. See index of PoolInfo[].
     * @param _user Address of a specific user.
     * @return Pending DINO.
     */
    function pendingDino(uint256 _pid, address _user) external view returns (uint256);

    /**
     * @dev Update reward variables for all pools. Be careful of gas spending!
     */
    function massUpdatePools() external;

    /**
     * @dev Update reward variables of the given pool to be up-to-date.
     * @param _pid ID of a specific LP token pool. See index of PoolInfo[].
     */
    function updatePool(uint256 _pid) external;

    /**
     * @dev Deposit LP tokens to the Fossil Farm for DINO allocation.
     * @param _pid ID of a specific LP token pool. See index of PoolInfo[].
     * @param _amount Amount of LP tokens to deposit.
     */
    function deposit(uint256 _pid, uint256 _amount) external;

    /**
     * @dev Withdraw LP tokens from the Fossil Farm.
     * @param _pid ID of a specific LP token pool. See index of PoolInfo[].
     * @param _amount Amount of LP tokens to withdraw.
     */
    function withdraw(uint256 _pid, uint256 _amount) external;

    /**
     * @dev Withdraw without caring about rewards. EMERGENCY ONLY.
     * @param _pid ID of a specific LP token pool. See index of PoolInfo[].
     */
    function emergencyWithdraw(uint256 _pid) external;

    /**
     * @dev Views total number of LP token pools.
     * @return Size of poolInfo array.
     */
    function poolLength() external view returns (uint256);

    /**
     * @dev Views total number of DINO tokens deposited for rewards.
     * @return DINO token balance of the Fossil Farm.
     */
    function balance() external view returns (uint256);

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

interface IPriceCalculator {

  function getPrice(address token, address outputToken) external view returns (uint256);

  function getPriceWithDefaultOutput(address token) external view returns (uint256);

  function getLargestPool(address token, address[] memory usedLps) external view returns (address, uint256, address);

  function getPriceFromLp(address lpAddress, address token) external view returns (uint256);

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

interface IRewardCalculator {

  event ToolAddressUpdated(string name, address newValue);

  function getPrice(address _token) external view returns (uint256);

  function strategyRewardsUsd(address _strategy, uint256 _period) external view returns (uint256);

  function rewardsPerTvl(address _vault, uint256 _period) external view returns (uint256);

  function vaultTVLRatio(address _vault) external view returns (uint256);

  function kpi(address _vault) external view returns (uint256);

  function vaultLastTetuReward(address _vault) external view returns (uint256);

  function strategyEarnedSinceLastDistribution(address strategy)
  external view returns (uint256 earned, uint256 lastEarnedTs);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDragonLair {

  function quick() external view returns (IERC20);

  // Enter the lair. Pay some QUICK. Earn some dragon QUICK.
  function enter(uint256 _quickAmount) external;

  // Leave the lair. Claim back your QUICK.
  function leave(uint256 _dQuickAmount) external;

  // returns the total amount of QUICK an address has in the contract including fees earned
  function QUICKBalance(address _account) external view returns (uint256 quickAmount_);

  //returns how much QUICK someone gets for depositing dQUICK
  function dQUICKForQUICK(uint256 _dQuickAmount) external view returns (uint256 quickAmount_);

  //returns how much dQUICK someone gets for depositing QUICK
  function QUICKForDQUICK(uint256 _quickAmount) external view returns (uint256 dQuickAmount_);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStakingDualRewards {

  function rewardsTokenA() external view returns (IERC20);

  function rewardsTokenB() external view returns (IERC20);

  function stakingToken() external view returns (IERC20);

  function periodFinish() external view returns (uint256);

  function rewardRateA() external view returns (uint256);

  function rewardRateB() external view returns (uint256);

  function lastUpdateTime() external view returns (uint256);

  function rewardPerTokenAStored() external view returns (uint256);

  function rewardPerTokenBStored() external view returns (uint256);

  function userRewardPerTokenAPaid(address _adr) external view returns (uint256);

  function userRewardPerTokenBPaid(address _adr) external view returns (uint256);

  function rewardsA(address _adr) external view returns (uint256);

  function rewardsB(address _adr) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function lastTimeRewardApplicable() external view returns (uint256);

  function rewardPerTokenA() external view returns (uint256);

  function rewardPerTokenB() external view returns (uint256);

  function earnedA(address account) external view returns (uint256);

  function earnedB(address account) external view returns (uint256);

  // Mutative
  function stake(uint256 amount) external;

  function withdraw(uint256 amount) external;

  function getReward() external;

  function exit() external;

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

interface IronControllerInterface {
  /*** Assets You Are In ***/

  function enterMarkets(address[] calldata RTokens) external returns (uint[] memory);

  function exitMarket(address RToken) external returns (uint);

  /*** Policy Hooks ***/

  function mintAllowed(address RToken, address minter, uint mintAmount) external returns (uint);

  function mintVerify(address RToken, address minter, uint mintAmount, uint mintTokens) external;

  function redeemAllowed(address RToken, address redeemer, uint redeemTokens) external returns (uint);

  function redeemVerify(address RToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

  function borrowAllowed(address RToken, address borrower, uint borrowAmount) external returns (uint);

  function borrowVerify(address RToken, address borrower, uint borrowAmount) external;

  function repayBorrowAllowed(
    address RToken,
    address payer,
    address borrower,
    uint repayAmount) external returns (uint);

  function repayBorrowVerify(
    address RToken,
    address payer,
    address borrower,
    uint repayAmount,
    uint borrowerIndex) external;

  function liquidateBorrowAllowed(
    address RTokenBorrowed,
    address RTokenCollateral,
    address liquidator,
    address borrower,
    uint repayAmount) external returns (uint);

  function liquidateBorrowVerify(
    address RTokenBorrowed,
    address RTokenCollateral,
    address liquidator,
    address borrower,
    uint repayAmount,
    uint seizeTokens) external;

  function seizeAllowed(
    address RTokenCollateral,
    address RTokenBorrowed,
    address liquidator,
    address borrower,
    uint seizeTokens) external returns (uint);

  function seizeVerify(
    address RTokenCollateral,
    address RTokenBorrowed,
    address liquidator,
    address borrower,
    uint seizeTokens) external;

  function transferAllowed(address RToken, address src, address dst, uint transfeRTokens) external returns (uint);

  function transferVerify(address RToken, address src, address dst, uint transfeRTokens) external;

  /*** Liquidity/Liquidation Calculations ***/

  function liquidateCalculateSeizeTokens(
    address RTokenBorrowed,
    address RTokenCollateral,
    uint repayAmount) external view returns (uint, uint);


  function claimReward(address holder, address[] memory rTokens) external;

  function rewardSpeeds(address rToken) external view returns (uint);

  function oracle() external view returns (address);

  function getAllMarkets() external view returns (address[] memory);

  function markets(address rToken) external view returns (bool isListed, uint collateralFactorMantissa);

  function getAccountLiquidity(address account) external view returns (uint, uint, uint);

  function rewardAccrued(address account) external view returns (uint);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "./RTokenInterfaces.sol";

abstract contract CompleteRToken is RErc20Interface, RTokenInterface {}

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

  function addVaultAndStrategy(address _vault, address _strategy) external;

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

  // ************ DAO ACTIONS *************
  function setPSNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function setFundNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function addToWhiteListMulti(address[] calldata _targets) external;

  function addToWhiteList(address _target) external;

  function removeFromWhiteListMulti(address[] calldata _targets) external;

  function removeFromWhiteList(address _target) external;
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewarder {
  function onSushiReward(uint256 pid, address user, address recipient, uint256 sushiAmount, uint256 newLpAmount) external;

  function pendingTokens(uint256 pid, address user, uint256 sushiAmount) external view returns (IERC20[] memory, uint256[] memory);

  function pendingToken(uint256 _pid, address _user) external view returns (uint256 pending);

  function rewardPerSecond() external view returns (uint256);

  function userInfo(uint256 _pid, address _user)
  external view returns (uint256 amount, uint256 rewardDebt);

  function poolInfo(uint256 _pid)
  external view returns (uint256 accSushiPerShare, uint256 lastRewardBlock, uint256 allocPoint);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface ICafeMasterChef {
  // Info of each user.
  struct UserInfo {
    uint256 amount; // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    //
    // We do some fancy math here. Basically, any point in time, the amount of BREWs
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.amount * pool.accBrewPerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The pool's `accBrewPerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
  }

  // Info of each pool.
  struct PoolInfo {
    IERC20 lpToken; // Address of LP token contract.
    uint256 allocPoint; // How many allocation points assigned to this pool. BREWs to distribute per block.
    uint256 lastRewardBlock; // Last block number that BREWs distribution occurs.
    uint256 accBrewPerShare; // Accumulated BREWs per share, times 1e12. See below.
    uint16 depositFeeBP; // Deposit fee in basis points
  }

  // The BREW TOKEN!
  function brew() external view returns (address);
  // Dev address.
  function devaddr() external view returns (address);
  // BREW tokens created per block.
  function brewPerBlock() external view returns (uint256);
  // Deposit Fee address
  function feeAddress() external view returns (address);

  // Info of each pool.
  function poolInfo(uint256 _pid) external view returns (PoolInfo memory);
  // Info of each user that stakes LP tokens.
  function userInfo(uint256 _pid, address _user) external view returns (UserInfo memory);
  // Info if a pool exists or not
  function poolExistence(address _erc20) external view returns (bool);
  // Total allocation points. Must be the sum of all allocation points in all pools.
  function totalAllocPoint() external view returns (uint256);
  // The block number when BREW mining starts.
  function startBlock() external view returns (uint256);

  // cafeSwapTransfer helper to be able to stake brew tokens
  function cafeSwapTransfer() external view returns (address);


  function poolLength() external view returns (uint256);

  // Add a new lp to the pool. Can only be called by the owner.
  function add(
    uint256 _allocPoint,
    IERC20 _lpToken,
    uint16 _depositFeeBP,
    bool _withUpdate
  ) external;

  // Update the given pool's BREW allocation point and deposit fee. Can only be called by the owner.
  function set(
    uint256 _pid,
    uint256 _allocPoint,
    uint16 _depositFeeBP,
    bool _withUpdate
  ) external;

  // Return reward multiplier over the given _from to _to block.
  function getMultiplier(uint256 _from, uint256 _to) external pure returns (uint256);

  // View function to see pending BREWs on frontend.
  function pendingBrew(uint256 _pid, address _user)
  external
  view
  returns (uint256);

  // Update reward variables for all pools. Be careful of gas spending!
  function massUpdatePools() external;

  // Update reward variables of the given pool to be up-to-date.
  function updatePool(uint256 _pid) external;

  // Deposit LP tokens to MasterChef for BREW allocation.
  function deposit(uint256 _pid, uint256 _amount) external;

  // Withdraw LP tokens from MasterChef.
  function withdraw(uint256 _pid, uint256 _amount) external;

  // Withdraw without caring about rewards. EMERGENCY ONLY.
  function emergencyWithdraw(uint256 _pid) external;

  // Update dev address by the previous dev.
  function dev(address _devaddr) external;

  function setFeeAddress(address _feeAddress) external;

  //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
  function updateEmissionRate(uint256 _brewPerBlock) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "./InterestRateModel.sol";
import "./IronControllerInterface.sol";
import "./EIP20NonStandardInterface.sol";

abstract contract RTokenStorage {
  /**
   * @dev Guard variable for re-entrancy checks
   */
  bool internal _notEntered;

  /**
   * @notice EIP-20 token name for this token
   */
  string public name;

  /**
   * @notice EIP-20 token symbol for this token
   */
  string public symbol;

  /**
   * @notice EIP-20 token decimals for this token
   */
  uint8 public decimals;

  /**
   * @notice Maximum borrow rate that can ever be applied (.0005% / block)
   */

  uint internal constant borrowRateMaxMantissa = 0.0005e16;

  /**
   * @notice Maximum fraction of interest that can be set aside for reserves
   */
  uint internal constant reserveFactorMaxMantissa = 1e18;

  /**
   * @notice Administrator for this contract
   */
  address payable public admin;

  /**
   * @notice Pending administrator for this contract
   */
  address payable public pendingAdmin;

  /**
   * @notice Contract which oversees inter-RToken operations
   */
  IronControllerInterface public ironController;

  /**
   * @notice Model which tells what the current interest rate should be
   */
  InterestRateModel public interestRateModel;

  /**
   * @notice Initial exchange rate used when minting the first RTokens (used when totalSupply = 0)
   */
  uint internal initialExchangeRateMantissa;

  /**
   * @notice Fraction of interest currently set aside for reserves
   */
  uint public reserveFactorMantissa;

  /**
   * @notice Block number that interest was last accrued at
   */
  uint public accrualBlockNumber;

  /**
   * @notice Accumulator of the total earned interest rate since the opening of the market
   */
  uint public borrowIndex;

  /**
   * @notice Total amount of outstanding borrows of the underlying in this market
   */
  uint public totalBorrows;

  /**
   * @notice Total amount of reserves of the underlying held in this market
   */
  uint public totalReserves;

  /**
   * @notice Total number of tokens in circulation
   */
  uint public totalSupply;

  /**
   * @notice Official record of token balances for each account
   */
  mapping(address => uint) internal accountTokens;

  /**
   * @notice Approved token transfer amounts on behalf of others
   */
  mapping(address => mapping(address => uint)) internal transferAllowances;

  /**
   * @notice Container for borrow balance information
   * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
   * @member interestIndex Global borrowIndex as of the most recent balance-changing action
   */
  struct BorrowSnapshot {
    uint principal;
    uint interestIndex;
  }

  /**
   * @notice Mapping of account addresses to outstanding borrow balances
   */
  mapping(address => BorrowSnapshot) internal accountBorrows;
}

abstract contract RTokenInterface is RTokenStorage {
  /**
   * @notice Indicator that this is a RToken contract (for inspection)
   */
  bool public constant isRToken = true;


  /*** Market Events ***/

  /**
   * @notice Event emitted when interest is accrued
   */
  event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

  /**
   * @notice Event emitted when tokens are minted
   */
  event Mint(address minter, uint mintAmount, uint mintTokens);

  /**
   * @notice Event emitted when tokens are redeemed
   */
  event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);

  /**
   * @notice Event emitted when underlying is borrowed
   */
  event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

  /**
   * @notice Event emitted when a borrow is repaid
   */
  event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

  /**
   * @notice Event emitted when a borrow is liquidated
   */
  event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address RTokenCollateral, uint seizeTokens);


  /*** Admin Events ***/

  /**
   * @notice Event emitted when pendingAdmin is changed
   */
  event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

  /**
   * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
   */
  event NewAdmin(address oldAdmin, address newAdmin);

  /**
   * @notice Event emitted when ironController is changed
   */
  event NewIronController(IronControllerInterface oldIronController, IronControllerInterface newIronController);

  /**
   * @notice Event emitted when interestRateModel is changed
   */
  event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

  /**
   * @notice Event emitted when the reserve factor is changed
   */
  event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

  /**
   * @notice Event emitted when the reserves are added
   */
  event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

  /**
   * @notice Event emitted when the reserves are reduced
   */
  event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);

  /**
   * @notice EIP20 Transfer event
   */
  event Transfer(address indexed from, address indexed to, uint amount);

  /**
   * @notice EIP20 Approval event
   */
  event Approval(address indexed owner, address indexed spender, uint amount);

  /**
   * @notice Failure event
   */
  event Failure(uint error, uint info, uint detail);


  /*** User Interface ***/

  function transfer(address dst, uint amount) virtual external returns (bool);

  function transferFrom(address src, address dst, uint amount) virtual external returns (bool);

  function approve(address spender, uint amount) virtual external returns (bool);

  function allowance(address owner, address spender) virtual external view returns (uint);

  function balanceOf(address owner) virtual external view returns (uint);

  function balanceOfUnderlying(address owner) virtual external returns (uint);

  function getAccountSnapshot(address account) virtual external view returns (uint, uint, uint, uint);

  function borrowRatePerBlock() virtual external view returns (uint);

  function supplyRatePerBlock() virtual external view returns (uint);

  function totalBorrowsCurrent() virtual external returns (uint);

  function borrowBalanceCurrent(address account) virtual external returns (uint);

  function borrowBalanceStored(address account) virtual external view returns (uint);

  function exchangeRateCurrent() virtual external returns (uint);

  function exchangeRateStored() virtual external view returns (uint);

  function getCash() virtual external view returns (uint);

  function accrueInterest() virtual external returns (uint);

  function seize(address liquidator, address borrower, uint seizeTokens) virtual external returns (uint);


  /*** Admin Functions ***/

  function _setPendingAdmin(address payable newPendingAdmin) virtual external returns (uint);

  function _acceptAdmin() virtual external returns (uint);

  function _setIronController(IronControllerInterface newIronController) virtual external returns (uint);

  function _setReserveFactor(uint newReserveFactorMantissa) virtual external returns (uint);

  function _reduceReserves(uint reduceAmount) virtual external returns (uint);

  function _setInterestRateModel(InterestRateModel newInterestRateModel) virtual external returns (uint);
}

abstract contract RErc20Storage {
  /**
   * @notice Underlying asset for this RToken
   */
  address public underlying;
}

abstract contract RErc20Interface is RErc20Storage {

  /*** User Interface ***/

  function mint(uint mintAmount) virtual external returns (uint);

  function redeem(uint redeemTokens) virtual external returns (uint);

  function redeemUnderlying(uint redeemAmount) virtual external returns (uint);

  function borrow(uint borrowAmount) virtual external returns (uint);

  function repayBorrow(uint repayAmount) virtual external returns (uint);

  function repayBorrowBehalf(address borrower, uint repayAmount) virtual external returns (uint);

  function liquidateBorrow(address borrower, uint repayAmount, RTokenInterface RTokenCollateral) virtual external returns (uint);

  function sweepToken(EIP20NonStandardInterface token) virtual external;


  /*** Admin Functions ***/

  function _addReserves(uint addAmount) virtual external returns (uint);
}

abstract contract RDelegationStorage {
  /**
   * @notice Implementation address for this contract
   */
  address public implementation;
}

abstract contract rDelegatorInterface is RDelegationStorage {
  /**
   * @notice Emitted when implementation is changed
   */
  event NewImplementation(address oldImplementation, address newImplementation);

  /**
   * @notice Called by the admin to update the implementation of the delegator
   * @param implementation_ The address of the new implementation for delegation
   * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
   * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
   */
  function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData) virtual external;
}

abstract contract RDelegateInterface is RDelegationStorage {
  /**
   * @notice Called by the delegator on a delegate to initialize it for duty
   * @dev Should revert if any issues arise which make it unfit for delegation
   * @param data The encoded bytes data for any initialization
   */
  function _becomeImplementation(bytes memory data) virtual external;

  /**
   * @notice Called by the delegator on a delegate to forfeit its responsibility
   */
  function _resignImplementation() virtual external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

/**
  * @title Compound's InterestRateModel Interface
  * @author Compound
  */
abstract contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view virtual returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view virtual returns (uint);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}