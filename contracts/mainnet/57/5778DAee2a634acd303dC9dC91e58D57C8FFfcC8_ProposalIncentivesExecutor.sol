// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import {IERC20} from '@aave/aave-stake/contracts/interfaces/IERC20.sol';
import {ILendingPoolAddressesProvider} from '../interfaces/ILendingPoolAddressesProvider.sol';
import {ILendingPoolConfigurator} from '../interfaces/ILendingPoolConfigurator.sol';
import {IAaveIncentivesController} from '../interfaces/IAaveIncentivesController.sol';
import {IAaveEcosystemReserveController} from '../interfaces/IAaveEcosystemReserveController.sol';
import {IProposalIncentivesExecutor} from '../interfaces/IProposalIncentivesExecutor.sol';
import {DistributionTypes} from '../lib/DistributionTypes.sol';
import {DataTypes} from '../utils/DataTypes.sol';
import {ILendingPoolData} from '../interfaces/ILendingPoolData.sol';
import {IATokenDetailed} from '../interfaces/IATokenDetailed.sol';
import {PercentageMath} from '../utils/PercentageMath.sol';
import {SafeMath} from '../lib/SafeMath.sol';

contract ProposalIncentivesExecutor is IProposalIncentivesExecutor {
  using SafeMath for uint256;
  using PercentageMath for uint256;

  address constant AAVE_TOKEN = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
  address constant POOL_CONFIGURATOR = 0x311Bb771e4F8952E6Da169b425E7e92d6Ac45756;
  address constant ADDRESSES_PROVIDER = 0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;
  address constant LENDING_POOL = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
  address constant ECO_RESERVE_ADDRESS = 0x1E506cbb6721B83B1549fa1558332381Ffa61A93;
  address constant INCENTIVES_CONTROLLER_PROXY_ADDRESS = 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;
  address constant INCENTIVES_CONTROLLER_IMPL_ADDRESS = 0x83D055D382f25e6793099713505c68a5C7535a35;

  uint256 constant DISTRIBUTION_DURATION = 7776000; // 90 days
  uint256 constant DISTRIBUTION_AMOUNT = 198000000000000000000000; // 198000 AAVE during 90 days

  function execute(
    address[6] memory aTokenImplementations,
    address[6] memory variableDebtImplementations
  ) external override {
    uint256 tokensCounter;

    address[] memory assets = new address[](12);

    // Reserves Order: DAI/GUSD/USDC/USDT/WBTC/WETH
    address payable[6] memory reserves =
      [
        0x6B175474E89094C44Da98b954EedeAC495271d0F,
        0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd,
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
        0xdAC17F958D2ee523a2206206994597C13D831ec7,
        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
      ];

    uint256[] memory emissions = new uint256[](12);

    emissions[0] = 1706018518518520; //aDAI
    emissions[1] = 1706018518518520; //vDebtDAI
    emissions[2] = 92939814814815; //aGUSD
    emissions[3] = 92939814814815; //vDebtGUSD
    emissions[4] = 5291203703703700; //aUSDC
    emissions[5] = 5291203703703700; //vDebtUSDC
    emissions[6] = 3293634259259260; //aUSDT
    emissions[7] = 3293634259259260; //vDebtUSDT
    emissions[8] = 1995659722222220; //aWBTC
    emissions[9] = 105034722222222; //vDebtWBTC
    emissions[10] = 2464942129629630; //aETH
    emissions[11] = 129733796296296; //vDebtWETH

    ILendingPoolConfigurator poolConfigurator = ILendingPoolConfigurator(POOL_CONFIGURATOR);
    IAaveIncentivesController incentivesController =
      IAaveIncentivesController(INCENTIVES_CONTROLLER_PROXY_ADDRESS);
    IAaveEcosystemReserveController ecosystemReserveController =
      IAaveEcosystemReserveController(ECO_RESERVE_ADDRESS);

    ILendingPoolAddressesProvider provider = ILendingPoolAddressesProvider(ADDRESSES_PROVIDER);

    //adding the incentives controller proxy to the addresses provider
    provider.setAddress(keccak256('INCENTIVES_CONTROLLER'), INCENTIVES_CONTROLLER_PROXY_ADDRESS);

    //updating the implementation of the incentives controller proxy
    provider.setAddressAsProxy(keccak256('INCENTIVES_CONTROLLER'), INCENTIVES_CONTROLLER_IMPL_ADDRESS);

    require(
      aTokenImplementations.length == variableDebtImplementations.length &&
        aTokenImplementations.length == reserves.length,
      'ARRAY_LENGTH_MISMATCH'
    );

    // Update each reserve AToken implementation, Debt implementation, and prepare incentives configuration input
    for (uint256 x = 0; x < reserves.length; x++) {
      require(
        IATokenDetailed(aTokenImplementations[x]).UNDERLYING_ASSET_ADDRESS() == reserves[x],
        'AToken underlying does not match'
      );
      require(
        IATokenDetailed(variableDebtImplementations[x]).UNDERLYING_ASSET_ADDRESS() == reserves[x],
        'Debt Token underlying does not match'
      );
      DataTypes.ReserveData memory reserveData =
        ILendingPoolData(LENDING_POOL).getReserveData(reserves[x]);

      // Update aToken impl
      poolConfigurator.updateAToken(reserves[x], aTokenImplementations[x]);

      // Update variable debt impl
      poolConfigurator.updateVariableDebtToken(reserves[x], variableDebtImplementations[x]);

      assets[tokensCounter++] = reserveData.aTokenAddress;

      // Configure variable debt token at incentives controller
      assets[tokensCounter++] = reserveData.variableDebtTokenAddress;

    }
    // Transfer AAVE funds to the Incentives Controller
    ecosystemReserveController.transfer(
      AAVE_TOKEN,
      INCENTIVES_CONTROLLER_PROXY_ADDRESS,
      DISTRIBUTION_AMOUNT
    );

    // Enable incentives in aTokens and Variable Debt tokens
    incentivesController.configureAssets(assets, emissions);

    // Sets the end date for the distribution
    incentivesController.setDistributionEnd(block.timestamp + DISTRIBUTION_DURATION);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * From https://github.com/OpenZeppelin/openzeppelin-contracts
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendingPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfiguratorImpl(address configurator) external;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

interface ILendingPoolConfigurator {
  function updateAToken(address reserve, address implementation) external;

  function updateVariableDebtToken(address reserve, address implementation) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

pragma experimental ABIEncoderV2;

import {IAaveDistributionManager} from '../interfaces/IAaveDistributionManager.sol';

interface IAaveIncentivesController is IAaveDistributionManager {
  
  event RewardsAccrued(address indexed user, uint256 amount);
  
  event RewardsClaimed(
    address indexed user,
    address indexed to,
    address indexed claimer,
    uint256 amount
  );

  event ClaimerSet(address indexed user, address indexed claimer);

  /**
   * @dev Whitelists an address to claim the rewards on behalf of another address
   * @param user The address of the user
   * @param claimer The address of the claimer
   */
  function setClaimer(address user, address claimer) external;

  /**
   * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
   * @param user The address of the user
   * @return The claimer address
   */
  function getClaimer(address user) external view returns (address);

  /**
   * @dev Configure assets for a certain rewards emission
   * @param assets The assets to incentivize
   * @param emissionsPerSecond The emission for each asset
   */
  function configureAssets(address[] calldata assets, uint256[] calldata emissionsPerSecond)
    external;


  /**
   * @dev Called by the corresponding asset on any update that affects the rewards distribution
   * @param asset The address of the user
   * @param userBalance The balance of the user of the asset in the lending pool
   * @param totalSupply The total supply of the asset in the lending pool
   **/
  function handleAction(
    address asset,
    uint256 userBalance,
    uint256 totalSupply
  ) external;

  /**
   * @dev Returns the total of rewards of an user, already accrued + not yet accrued
   * @param user The address of the user
   * @return The rewards
   **/
  function getRewardsBalance(address[] calldata assets, address user)
    external
    view
    returns (uint256);

  /**
   * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
   * @param amount Amount of rewards to claim
   * @param to Address that will be receiving the rewards
   * @return Rewards claimed
   **/
  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards. The caller must
   * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
   * @param amount Amount of rewards to claim
   * @param user Address to check and claim rewards
   * @param to Address that will be receiving the rewards
   * @return Rewards claimed
   **/
  function claimRewardsOnBehalf(
    address[] calldata assets,
    uint256 amount,
    address user,
    address to
  ) external returns (uint256);

  /**
   * @dev returns the unclaimed rewards of the user
   * @param user the address of the user
   * @return the unclaimed user rewards
   */
  function getUserUnclaimedRewards(address user) external view returns (uint256);

  /**
  * @dev for backward compatibility with previous implementation of the Incentives controller
  */
  function REWARD_TOKEN() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import {DistributionTypes} from '../lib/DistributionTypes.sol';

interface IAaveDistributionManager {
  
  event AssetConfigUpdated(address indexed asset, uint256 emission);
  event AssetIndexUpdated(address indexed asset, uint256 index);
  event UserIndexUpdated(address indexed user, address indexed asset, uint256 index);
  event DistributionEndUpdated(uint256 newDistributionEnd);

  /**
  * @dev Sets the end date for the distribution
  * @param distributionEnd The end date timestamp
  **/
  function setDistributionEnd(uint256 distributionEnd) external;

  /**
  * @dev Gets the end date for the distribution
  * @return The end of the distribution
  **/
  function getDistributionEnd() external view returns (uint256);

  /**
  * @dev for backwards compatibility with the previous DistributionManager used
  * @return The end of the distribution
  **/
  function DISTRIBUTION_END() external view returns(uint256);

   /**
   * @dev Returns the data of an user on a distribution
   * @param user Address of the user
   * @param asset The address of the reference asset of the distribution
   * @return The new index
   **/
   function getUserAssetData(address user, address asset) external view returns (uint256);

   /**
   * @dev Returns the configuration of the distribution for a certain asset
   * @param asset The address of the reference asset of the distribution
   * @return The asset index, the emission per second and the last updated timestamp
   **/
   function getAssetData(address asset) external view returns (uint256, uint256, uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

library DistributionTypes {
  struct AssetConfigInput {
    uint104 emissionPerSecond;
    uint256 totalStaked;
    address underlyingAsset;
  }

  struct UserStakeInput {
    address underlyingAsset;
    uint256 stakedByUser;
    uint256 totalStaked;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

interface IAaveEcosystemReserveController {
  function AAVE_RESERVE_ECOSYSTEM() external view returns (address);

  function approve(
    address token,
    address recipient,
    uint256 amount
  ) external;

  function owner() external view returns (address);

  function renounceOwnership() external;

  function transfer(
    address token,
    address recipient,
    uint256 amount
  ) external;

  function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

interface IProposalIncentivesExecutor {
  function execute(
    address[6] memory aTokenImplementations,
    address[6] memory variableDebtImplementation
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import {DataTypes} from '../utils/DataTypes.sol';

interface ILendingPoolData {
  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

interface IATokenDetailed {
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

/**
 * @title PercentageMath library
 * @author Aave
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
  uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
  uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

  /**
   * @dev Executes a percentage multiplication
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The percentage of value
   **/
  function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256) {
    if (value == 0 || percentage == 0) {
      return 0;
    }

    require(
      value <= (type(uint256).max - HALF_PERCENT) / percentage,
      'MATH_MULTIPLICATION_OVERFLOW'
    );

    return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
  }

  /**
   * @dev Executes a percentage division
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The value divided the percentage
   **/
  function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256) {
    require(percentage != 0, 'MATH_DIVISION_BY_ZERO');
    uint256 halfPercentage = percentage / 2;

    require(
      value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR,
      'MATH_MULTIPLICATION_OVERFLOW'
    );

    return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.7.5;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
/// inspired by uniswap V3
library SafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    function div(uint256 x, uint256 y) internal pure returns(uint256) {
        // no need to check for division by zero - solidity already reverts
        return x / y;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}