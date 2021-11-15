// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/tokens/IERC20Detailed.sol';
import '../access/interfaces/IMarketAccessController.sol';
import '../access/AccessFlags.sol';
import '../interfaces/ILendingPool.sol';
import '../interfaces/ILendingPoolConfigurator.sol';
import '../interfaces/IStableDebtToken.sol';
import '../interfaces/IVariableDebtToken.sol';
import '../protocol/libraries/configuration/ReserveConfiguration.sol';
import '../protocol/libraries/configuration/UserConfiguration.sol';
import '../protocol/libraries/types/DataTypes.sol';
import '../interfaces/IReserveRateStrategy.sol';
import '../interfaces/IPoolAddressProvider.sol';
import './interfaces/IUiPoolDataProvider.sol';
import '../interfaces/IPriceOracleGetter.sol';
import '../interfaces/IDepositToken.sol';
import '../interfaces/IDerivedToken.sol';
import '../interfaces/IRewardedToken.sol';
import '../interfaces/IUnderlyingBalance.sol';
import '../reward/interfaces/IManagedRewardPool.sol';
import '../reward/interfaces/IRewardExplainer.sol';
import '../protocol/stake/interfaces/IStakeConfigurator.sol';
import '../protocol/stake/interfaces/IStakeToken.sol';

contract ProtocolDataProvider is IUiPoolDataProvider {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;

  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public constant USD = 0x10F7Fc1F91Ba351f9C629c5947AD69bD03C05b96;

  // solhint-disable-next-line var-name-mixedcase
  IMarketAccessController public immutable ADDRESS_PROVIDER;

  constructor(IMarketAccessController addressesProvider) {
    ADDRESS_PROVIDER = addressesProvider;
  }

  function getAllTokenDescriptions(bool includeAssets)
    external
    view
    override
    returns (TokenDescription[] memory tokens, uint256 tokenCount)
  {
    ILendingPool pool = ILendingPool(ADDRESS_PROVIDER.getLendingPool());
    address[] memory reserveList = pool.getReservesList();

    address[] memory stakeList;
    IStakeConfigurator stakeCfg = IStakeConfigurator(_getAddress(AccessFlags.STAKE_CONFIGURATOR));
    if (address(stakeCfg) != address(0)) {
      stakeList = stakeCfg.list();
    }

    tokenCount = 2 + stakeList.length + reserveList.length * 3;
    if (includeAssets) {
      tokenCount += reserveList.length;
    }

    tokens = new TokenDescription[](tokenCount);

    tokenCount = 0;
    address token = _getAddress(AccessFlags.REWARD_TOKEN);
    if (token != address(0)) {
      tokens[tokenCount] = TokenDescription(
        token,
        token,
        address(0),
        IERC20Detailed(token).symbol(),
        address(0),
        IERC20Detailed(token).decimals(),
        TokenType.Reward,
        true,
        false
      );
      tokenCount++;
    }

    token = _getAddress(AccessFlags.REWARD_STAKE_TOKEN);
    if (token != address(0)) {
      tokens[tokenCount] = TokenDescription(
        token,
        address(0),
        token,
        IERC20Detailed(token).symbol(),
        tokens[0].token,
        IERC20Detailed(token).decimals(),
        TokenType.RewardStake,
        true,
        false
      );
      tokenCount++;
    }

    for (uint256 i = 0; i < reserveList.length; i++) {
      token = reserveList[i];
      DataTypes.ReserveData memory reserveData = pool.getReserveData(token);
      (bool isActive, bool isFrozen, bool canBorrow, bool canBorrowStable) = reserveData.configuration.getFlagsMemory();

      canBorrow = isActive && canBorrow;
      canBorrowStable = canBorrowStable && canBorrow;

      uint8 decimals = reserveData.configuration.getDecimalsMemory();

      if (includeAssets) {
        address underlying;
        if (reserveData.configuration.isExternalStrategyMemory()) {
          underlying = IUnderlyingStrategy(reserveData.strategy).getUnderlying(token);
        }

        tokens[tokenCount] = TokenDescription(
          token,
          token,
          address(0),
          IERC20Detailed(token).symbol(),
          underlying,
          decimals,
          TokenType.PoolAsset,
          true,
          false
        );
        tokenCount++;
      }

      address subToken = reserveData.depositTokenAddress;
      tokens[tokenCount] = TokenDescription(
        subToken,
        token,
        IRewardedToken(subToken).getIncentivesController(),
        IERC20Detailed(subToken).symbol(),
        token,
        decimals,
        TokenType.Deposit,
        isActive,
        isFrozen
      );
      tokenCount++;

      if (reserveData.variableDebtTokenAddress != address(0)) {
        subToken = reserveData.variableDebtTokenAddress;
        tokens[tokenCount] = TokenDescription(
          subToken,
          token,
          IRewardedToken(subToken).getIncentivesController(),
          IERC20Detailed(subToken).symbol(),
          token,
          decimals,
          TokenType.VariableDebt,
          canBorrow,
          isFrozen
        );
        tokenCount++;
      }

      if (reserveData.stableDebtTokenAddress != address(0)) {
        subToken = reserveData.stableDebtTokenAddress;
        tokens[tokenCount] = TokenDescription(
          subToken,
          token,
          IRewardedToken(subToken).getIncentivesController(),
          IERC20Detailed(subToken).symbol(),
          token,
          decimals,
          TokenType.StableDebt,
          canBorrowStable,
          isFrozen
        );
        tokenCount++;
      }
    }

    for (uint256 i = 0; i < stakeList.length; i++) {
      token = stakeList[i];
      address underlying = IDerivedToken(token).UNDERLYING_ASSET_ADDRESS();
      tokens[tokenCount] = TokenDescription(
        token,
        underlying,
        IRewardedToken(token).getIncentivesController(),
        IERC20Detailed(token).symbol(),
        underlying,
        IERC20Detailed(token).decimals(),
        TokenType.Stake,
        true,
        false
      );
      tokenCount++;
    }

    return (tokens, tokenCount);
  }

  function getAllTokens(bool includeAssets)
    public
    view
    override
    returns (
      address[] memory tokens,
      uint256 tokenCount,
      TokenType[] memory tokenTypes
    )
  {
    ILendingPool pool = ILendingPool(ADDRESS_PROVIDER.getLendingPool());
    address[] memory reserveList = pool.getReservesList();

    address[] memory stakeList;
    IStakeConfigurator stakeCfg = IStakeConfigurator(_getAddress(AccessFlags.STAKE_CONFIGURATOR));
    if (address(stakeCfg) != address(0)) {
      stakeList = stakeCfg.list();
    }

    tokenCount = 2 + stakeList.length + reserveList.length * 3;
    if (includeAssets) {
      tokenCount += reserveList.length;
    }
    tokens = new address[](tokenCount);
    tokenTypes = new TokenType[](tokenCount);

    tokenCount = 0;

    tokens[tokenCount] = _getAddress(AccessFlags.REWARD_TOKEN);
    tokenTypes[tokenCount] = TokenType.Reward;
    if (tokens[tokenCount] != address(0)) {
      tokenCount++;
    }

    tokens[tokenCount] = _getAddress(AccessFlags.REWARD_STAKE_TOKEN);
    tokenTypes[tokenCount] = TokenType.RewardStake;
    if (tokens[tokenCount] != address(0)) {
      tokenCount++;
    }

    for (uint256 i = 0; i < reserveList.length; i++) {
      address token = reserveList[i];
      DataTypes.ReserveData memory reserveData = pool.getReserveData(token);
      (bool isActive, , bool canBorrow, bool canBorrowStable) = reserveData.configuration.getFlagsMemory();
      canBorrow = isActive && canBorrow;
      canBorrowStable = canBorrowStable && canBorrow;

      if (includeAssets) {
        tokens[tokenCount] = token;
        tokenTypes[tokenCount] = TokenType.PoolAsset;
        tokenCount++;
      }

      tokens[tokenCount] = reserveData.depositTokenAddress;
      tokenTypes[tokenCount] = TokenType.Deposit;
      tokenCount++;

      if (reserveData.variableDebtTokenAddress != address(0)) {
        tokens[tokenCount] = reserveData.variableDebtTokenAddress;
        tokenTypes[tokenCount] = TokenType.VariableDebt;
        tokenCount++;
      }

      if (reserveData.stableDebtTokenAddress != address(0)) {
        tokens[tokenCount] = reserveData.stableDebtTokenAddress;
        tokenTypes[tokenCount] = TokenType.StableDebt;
        tokenCount++;
      }
    }

    for (uint256 i = 0; i < stakeList.length; i++) {
      tokens[tokenCount] = stakeList[i];
      tokenTypes[tokenCount] = TokenType.Stake;
      tokenCount++;
    }

    return (tokens, tokenCount, tokenTypes);
  }

  function getReserveConfigurationData(address asset)
    external
    view
    override
    returns (
      uint256 decimals,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      uint256 reserveFactor,
      bool usageAsCollateralEnabled,
      bool borrowingEnabled,
      bool stableBorrowRateEnabled,
      bool isActive,
      bool isFrozen
    )
  {
    DataTypes.ReserveConfigurationMap memory configuration = ILendingPool(ADDRESS_PROVIDER.getLendingPool())
      .getConfiguration(asset);

    (ltv, liquidationThreshold, liquidationBonus, decimals, reserveFactor) = configuration.getParamsMemory();
    (isActive, isFrozen, borrowingEnabled, stableBorrowRateEnabled) = configuration.getFlagsMemory();

    usageAsCollateralEnabled = liquidationThreshold > 0;
  }

  function getReserveData(address asset)
    external
    view
    override
    returns (
      uint256 availableLiquidity,
      uint256 totalStableDebt,
      uint256 totalVariableDebt,
      uint256 liquidityRate,
      uint256 variableBorrowRate,
      uint256 stableBorrowRate,
      uint256 averageStableBorrowRate,
      uint256 liquidityIndex,
      uint256 variableBorrowIndex,
      uint40 lastUpdateTimestamp
    )
  {
    DataTypes.ReserveData memory reserve = ILendingPool(ADDRESS_PROVIDER.getLendingPool()).getReserveData(asset);

    availableLiquidity = IERC20Detailed(asset).balanceOf(reserve.depositTokenAddress);

    if (reserve.variableDebtTokenAddress != address(0)) {
      totalVariableDebt = IERC20Detailed(reserve.variableDebtTokenAddress).totalSupply();
    }

    if (reserve.stableDebtTokenAddress != address(0)) {
      totalStableDebt = IERC20Detailed(reserve.stableDebtTokenAddress).totalSupply();
      averageStableBorrowRate = IStableDebtToken(reserve.stableDebtTokenAddress).getAverageStableRate();
    }

    return (
      availableLiquidity,
      totalStableDebt,
      totalVariableDebt,
      reserve.currentLiquidityRate,
      reserve.currentVariableBorrowRate,
      reserve.currentStableBorrowRate,
      averageStableBorrowRate,
      reserve.liquidityIndex,
      reserve.variableBorrowIndex,
      reserve.lastUpdateTimestamp
    );
  }

  function getUserReserveData(address asset, address user)
    external
    view
    override
    returns (
      uint256 currentDepositBalance,
      uint256 currentStableDebt,
      uint256 currentVariableDebt,
      uint256 principalStableDebt,
      uint256 scaledVariableDebt,
      uint256 stableBorrowRate,
      uint256 liquidityRate,
      uint40 stableRateLastUpdated,
      bool usageAsCollateralEnabled
    )
  {
    DataTypes.ReserveData memory reserve = ILendingPool(ADDRESS_PROVIDER.getLendingPool()).getReserveData(asset);

    DataTypes.UserConfigurationMap memory userConfig = ILendingPool(ADDRESS_PROVIDER.getLendingPool())
      .getUserConfiguration(user);

    liquidityRate = reserve.currentLiquidityRate;
    usageAsCollateralEnabled = userConfig.isUsingAsCollateral(reserve.id);

    currentDepositBalance = IERC20Detailed(reserve.depositTokenAddress).balanceOf(user);

    if (reserve.variableDebtTokenAddress != address(0)) {
      currentVariableDebt = IERC20Detailed(reserve.variableDebtTokenAddress).balanceOf(user);
      scaledVariableDebt = IVariableDebtToken(reserve.variableDebtTokenAddress).scaledBalanceOf(user);
    }

    if (reserve.stableDebtTokenAddress != address(0)) {
      currentStableDebt = IERC20Detailed(reserve.stableDebtTokenAddress).balanceOf(user);
      principalStableDebt = IStableDebtToken(reserve.stableDebtTokenAddress).principalBalanceOf(user);
      stableBorrowRate = IStableDebtToken(reserve.stableDebtTokenAddress).getUserStableRate(user);
      stableRateLastUpdated = IStableDebtToken(reserve.stableDebtTokenAddress).getUserLastUpdated(user);
    }
  }

  function getReservesData(address user)
    external
    view
    override
    returns (
      AggregatedReserveData[] memory,
      UserReserveData[] memory,
      uint256
    )
  {
    ILendingPool lendingPool = ILendingPool(ADDRESS_PROVIDER.getLendingPool());
    IPriceOracleGetter oracle = IPriceOracleGetter(ADDRESS_PROVIDER.getPriceOracle());
    address[] memory reserves = lendingPool.getReservesList();
    DataTypes.UserConfigurationMap memory userConfig = lendingPool.getUserConfiguration(user);

    AggregatedReserveData[] memory reservesData = new AggregatedReserveData[](reserves.length);
    UserReserveData[] memory userReservesData = new UserReserveData[](user != address(0) ? reserves.length : 0);

    for (uint256 i = 0; i < reserves.length; i++) {
      AggregatedReserveData memory reserveData = reservesData[i];
      reserveData.underlyingAsset = reserves[i];
      reserveData.pricingAsset = reserveData.underlyingAsset;

      // reserve current state
      DataTypes.ReserveData memory baseData = lendingPool.getReserveData(reserveData.underlyingAsset);
      reserveData.liquidityIndex = baseData.liquidityIndex;
      reserveData.variableBorrowIndex = baseData.variableBorrowIndex;
      reserveData.liquidityRate = baseData.currentLiquidityRate;
      reserveData.variableBorrowRate = baseData.currentVariableBorrowRate;
      reserveData.stableBorrowRate = baseData.currentStableBorrowRate;
      reserveData.lastUpdateTimestamp = baseData.lastUpdateTimestamp;
      reserveData.depositTokenAddress = baseData.depositTokenAddress;
      reserveData.stableDebtTokenAddress = baseData.stableDebtTokenAddress;
      reserveData.variableDebtTokenAddress = baseData.variableDebtTokenAddress;
      reserveData.strategy = baseData.strategy;
      reserveData.isExternalStrategy = baseData.configuration.isExternalStrategyMemory();
      reserveData.priceInEth = oracle.getAssetPrice(reserveData.pricingAsset);

      reserveData.availableLiquidity = IERC20Detailed(reserveData.underlyingAsset).balanceOf(
        reserveData.depositTokenAddress
      );

      if (reserveData.variableDebtTokenAddress != address(0)) {
        reserveData.totalScaledVariableDebt = IVariableDebtToken(reserveData.variableDebtTokenAddress)
          .scaledTotalSupply();
      }

      if (reserveData.stableDebtTokenAddress != address(0)) {
        (
          reserveData.totalPrincipalStableDebt,
          reserveData.totalStableDebt,
          reserveData.averageStableRate,
          reserveData.stableDebtLastUpdateTimestamp
        ) = IStableDebtToken(reserveData.stableDebtTokenAddress).getSupplyData();
      }

      // reserve configuration

      // we're getting this info from the depositToken, because some of assets can be not compliant with ETC20Detailed
      reserveData.symbol = IERC20Detailed(reserveData.depositTokenAddress).symbol();
      reserveData.name = '';

      (
        reserveData.baseLTVasCollateral,
        reserveData.reserveLiquidationThreshold,
        reserveData.reserveLiquidationBonus,
        reserveData.decimals,
        reserveData.reserveFactor
      ) = baseData.configuration.getParamsMemory();
      (
        reserveData.isActive,
        reserveData.isFrozen,
        reserveData.borrowingEnabled,
        reserveData.stableBorrowRateEnabled
      ) = baseData.configuration.getFlagsMemory();
      reserveData.usageAsCollateralEnabled = reserveData.baseLTVasCollateral != 0;

      if (user != address(0)) {
        // user reserve data
        userReservesData[i].underlyingAsset = reserveData.underlyingAsset;
        userReservesData[i].scaledDepositTokenBalance = IDepositToken(reserveData.depositTokenAddress).scaledBalanceOf(
          user
        );
        userReservesData[i].usageAsCollateralEnabledOnUser = userConfig.isUsingAsCollateral(i);

        if (userConfig.isBorrowing(i)) {
          if (reserveData.variableDebtTokenAddress != address(0)) {
            userReservesData[i].scaledVariableDebt = IVariableDebtToken(reserveData.variableDebtTokenAddress)
              .scaledBalanceOf(user);
          }

          if (reserveData.stableDebtTokenAddress != address(0)) {
            userReservesData[i].principalStableDebt = IStableDebtToken(reserveData.stableDebtTokenAddress)
              .principalBalanceOf(user);

            if (userReservesData[i].principalStableDebt != 0) {
              userReservesData[i].stableBorrowRate = IStableDebtToken(reserveData.stableDebtTokenAddress)
                .getUserStableRate(user);
              userReservesData[i].stableBorrowLastUpdateTimestamp = IStableDebtToken(reserveData.stableDebtTokenAddress)
                .getUserLastUpdated(user);
            }
          }
        }
      }
    }
    return (reservesData, userReservesData, oracle.getAssetPrice(USD));
  }

  function _getAddress(uint256 flag) private view returns (address) {
    return ADDRESS_PROVIDER.getAddress(flag);
  }

  function getAddresses() external view override returns (Addresses memory data) {
    data.addressProvider = address(ADDRESS_PROVIDER);
    data.lendingPool = _getAddress(AccessFlags.LENDING_POOL);
    data.stakeConfigurator = _getAddress(AccessFlags.STAKE_CONFIGURATOR);
    data.rewardConfigurator = _getAddress(AccessFlags.REWARD_CONFIGURATOR);
    data.rewardController = _getAddress(AccessFlags.REWARD_CONTROLLER);
    data.wethGateway = _getAddress(AccessFlags.WETH_GATEWAY);
    data.priceOracle = _getAddress(AccessFlags.PRICE_ORACLE);
    data.lendingPriceOracle = _getAddress(AccessFlags.LENDING_RATE_ORACLE);
    data.rewardToken = _getAddress(AccessFlags.REWARD_TOKEN);
    data.rewardStake = _getAddress(AccessFlags.REWARD_STAKE_TOKEN);
    data.referralRegistry = _getAddress(AccessFlags.REFERRAL_REGISTRY);
  }

  function balanceOf(
    address user,
    address token,
    TokenType tokenType
  ) public view returns (TokenBalance memory r) {
    if (tokenType >= TokenType.Stake) {
      if (tokenType == TokenType.Stake) {
        (r.balance, r.unstakeWindowStart, r.unstakeWindowEnd) = IStakeToken(token).balanceAndCooldownOf(user);
        r.underlyingBalance = IStakeToken(token).balanceOfUnderlying(user);
        r.rewardedBalance = IStakeToken(token).rewardedBalanceOf(user);
      } else if (tokenType == TokenType.RewardStake) {
        r.balance = IERC20Detailed(token).balanceOf(user);
        (r.underlyingBalance, r.unstakeWindowStart) = ILockedUnderlyingBalance(token).balanceOfUnderlyingAndExpiry(
          user
        );
        r.unstakeWindowEnd = type(uint32).max;
      } else {
        r.underlyingBalance = r.balance = IERC20Detailed(token).balanceOf(user);
      }
    } else if (tokenType == TokenType.PoolAsset) {
      r.underlyingBalance = r.balance = token == ETH ? user.balance : IERC20Detailed(token).balanceOf(user);
    } else {
      r.underlyingBalance = r.balance = IERC20Detailed(token).balanceOf(user);
      r.rewardedBalance = IRewardedToken(token).rewardedBalanceOf(user);
    }
  }

  /**
   * @return balances - an array with the concatenation of balances for each user
   **/
  function batchBalanceOf(
    address[] calldata users,
    address[] calldata tokens,
    TokenType[] calldata tokenTypes,
    TokenType defType
  ) external view override returns (TokenBalance[] memory balances) {
    balances = new TokenBalance[](users.length * tokens.length);

    for (uint256 i = 0; i < users.length; i++) {
      for (uint256 j = 0; j < tokens.length; j++) {
        balances[i * tokens.length + j] = balanceOf(
          users[i],
          tokens[j],
          tokenTypes.length == 0 ? defType : tokenTypes[j]
        );
      }
    }

    return balances;
  }

  function explainReward(address holder, uint32 minDuration) external view returns (RewardExplained memory, uint32 at) {
    IRewardExplainer re = IRewardExplainer(_getAddress(AccessFlags.REWARD_CONTROLLER));
    at = uint32(block.timestamp) + minDuration;
    return (re.explainReward(holder, at), at);
  }

  function rewardPoolNames(address[] calldata pools, uint256 ignoreMask) external view returns (string[] memory names) {
    names = new string[](pools.length);
    for (uint256 i = 0; i < pools.length; (i, ignoreMask) = (i + 1, ignoreMask >> 1)) {
      if (ignoreMask & 1 != 0 || pools[i] == address(0)) {
        continue;
      }
      names[i] = IManagedRewardPool(pools[i]).getPoolName();
    }
    return names;
  }

  function getReserveTokensAddresses(address asset)
    external
    view
    returns (
      address depositTokenAddress, // ATTN! DO NOT rename - scripts rely on names
      address stableDebtTokenAddress,
      address variableDebtTokenAddress
    )
  {
    DataTypes.ReserveData memory reserve = ILendingPool(ADDRESS_PROVIDER.getLendingPool()).getReserveData(asset);
    return (reserve.depositTokenAddress, reserve.stableDebtTokenAddress, reserve.variableDebtTokenAddress);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../dependencies/openzeppelin/contracts/IERC20.sol';
import './IERC20Details.sol';

interface IERC20Detailed is IERC20, IERC20Details {}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IAccessController.sol';

/// @dev Main registry of addresses part of or connected to the protocol, including permissioned roles. Also acts a proxy factory.
interface IMarketAccessController is IAccessController {
  function getMarketId() external view returns (string memory);

  function getLendingPool() external view returns (address);

  function getPriceOracle() external view returns (address);

  function getLendingRateOracle() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

library AccessFlags {
  // roles that can be assigned to multiple addresses - use range [0..15]
  uint256 public constant EMERGENCY_ADMIN = 1 << 0;
  uint256 public constant POOL_ADMIN = 1 << 1;
  uint256 public constant TREASURY_ADMIN = 1 << 2;
  uint256 public constant REWARD_CONFIG_ADMIN = 1 << 3;
  uint256 public constant REWARD_RATE_ADMIN = 1 << 4;
  uint256 public constant STAKE_ADMIN = 1 << 5;
  uint256 public constant REFERRAL_ADMIN = 1 << 6;
  uint256 public constant LENDING_RATE_ADMIN = 1 << 7;
  uint256 public constant SWEEP_ADMIN = 1 << 8;
  uint256 public constant ORACLE_ADMIN = 1 << 9;

  uint256 public constant ROLES = (uint256(1) << 16) - 1;

  // singletons - use range [16..64] - can ONLY be assigned to a single address
  uint256 public constant SINGLETONS = ((uint256(1) << 64) - 1) & ~ROLES;

  // proxied singletons
  uint256 public constant LENDING_POOL = 1 << 16;
  uint256 public constant LENDING_POOL_CONFIGURATOR = 1 << 17;
  uint256 public constant LIQUIDITY_CONTROLLER = 1 << 18;
  uint256 public constant TREASURY = 1 << 19;
  uint256 public constant REWARD_TOKEN = 1 << 20;
  uint256 public constant REWARD_STAKE_TOKEN = 1 << 21;
  uint256 public constant REWARD_CONTROLLER = 1 << 22;
  uint256 public constant REWARD_CONFIGURATOR = 1 << 23;
  uint256 public constant STAKE_CONFIGURATOR = 1 << 24;
  uint256 public constant REFERRAL_REGISTRY = 1 << 25;

  uint256 public constant PROXIES = ((uint256(1) << 26) - 1) & ~ROLES;

  // non-proxied singletons, numbered down from 31 (as JS has problems with bitmasks over 31 bits)
  uint256 public constant WETH_GATEWAY = 1 << 27;
  uint256 public constant DATA_HELPER = 1 << 28;
  uint256 public constant PRICE_ORACLE = 1 << 29;
  uint256 public constant LENDING_RATE_ORACLE = 1 << 30;

  // any other roles - use range [64..]
  // these roles can be assigned to multiple addresses

  uint256 public constant TRUSTED_FLASHLOAN = 1 << 66;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../protocol/libraries/types/DataTypes.sol';
import './ILendingPoolEvents.sol';

interface ILendingPool is ILendingPoolEvents {
  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying depositTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the depositTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of depositTokens
   *   is a different wallet
   * @param referral Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint256 referral
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent depositTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole depositToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referral Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint256 referral,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
   * @param asset The address of the underlying asset borrowed
   * @param rateMode The rate mode that the user wants to swap to
   **/
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /**
   * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and depositors are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveDeposit `true` if the liquidators wants to receive the collateral depositTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveDeposit
  ) external;

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referral Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint256 referral
  ) external;

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (address);

  function getFlashloanPremiumPct() external view returns (uint16);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../interfaces/IEmergencyAccessGroup.sol';

interface ILendingPoolConfigurator {
  struct InitReserveInput {
    address depositTokenImpl;
    address stableDebtTokenImpl;
    address variableDebtTokenImpl;
    uint8 underlyingAssetDecimals;
    bool externalStrategy;
    address strategy;
    address underlyingAsset;
    string depositTokenName;
    string depositTokenSymbol;
    string variableDebtTokenName;
    string variableDebtTokenSymbol;
    string stableDebtTokenName;
    string stableDebtTokenSymbol;
    bytes params;
  }

  struct UpdatePoolTokenInput {
    address asset;
    string name;
    string symbol;
    address implementation;
    bytes params;
  }

  struct ConfigureReserveInput {
    address asset;
    uint256 baseLTV;
    uint256 liquidationThreshold;
    uint256 liquidationBonus;
    uint256 reserveFactor;
    bool borrowingEnabled;
    bool stableBorrowingEnabled;
  }

  event ReserveInitialized(
    address indexed asset,
    address indexed depositToken,
    address stableDebtToken,
    address variableDebtToken,
    address strategy,
    bool externalStrategy
  );

  event BorrowingEnabledOnReserve(address indexed asset, bool stableRateEnabled);
  event BorrowingDisabledOnReserve(address indexed asset);

  event CollateralConfigurationChanged(
    address indexed asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  );

  event StableRateEnabledOnReserve(address indexed asset);
  event StableRateDisabledOnReserve(address indexed asset);

  event ReserveActivated(address indexed asset);
  event ReserveDeactivated(address indexed asset);

  event ReserveFrozen(address indexed asset);
  event ReserveUnfrozen(address indexed asset);

  event ReserveFactorChanged(address indexed asset, uint256 factor);
  event ReserveStrategyChanged(address indexed asset, address strategy, bool isExternal);

  event DepositTokenUpgraded(address indexed asset, address indexed proxy, address indexed implementation);

  event StableDebtTokenUpgraded(address indexed asset, address indexed proxy, address indexed implementation);

  event VariableDebtTokenUpgraded(address indexed asset, address indexed proxy, address indexed implementation);

  function getFlashloanAdapters(string[] calldata names) external view returns (address[] memory adapters);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IBalanceHook.sol';
import '../dependencies/openzeppelin/contracts/IERC20.sol';
import './IPoolToken.sol';

/// @dev Defines the interface for the stable debt token
interface IStableDebtToken is IPoolToken {
  /**
   * @dev Emitted when new stable debt is minted
   * @param user The address of the user who triggered the minting
   * @param onBehalfOf The recipient of stable debt tokens
   * @param amount The amount minted
   * @param currentBalance The current balance of the user
   * @param balanceIncrease The increase in balance since the last action of the user
   * @param newRate The rate of the debt after the minting
   * @param avgStableRate The new average stable rate after the minting
   * @param newTotalSupply The new total supply of the stable debt token after the action
   **/
  event Mint(
    address indexed user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 currentBalance,
    uint256 balanceIncrease,
    uint256 newRate,
    uint256 avgStableRate,
    uint256 newTotalSupply
  );

  /**
   * @dev Emitted when new stable debt is burned
   * @param user The address of the user
   * @param amount The amount being burned
   * @param currentBalance The current balance of the user
   * @param balanceIncrease The the increase in balance since the last action of the user
   * @param avgStableRate The new average stable rate after the burning
   * @param newTotalSupply The new total supply of the stable debt token after the action
   **/
  event Burn(
    address indexed user,
    uint256 amount,
    uint256 currentBalance,
    uint256 balanceIncrease,
    uint256 avgStableRate,
    uint256 newTotalSupply
  );

  /**
   * @dev Mints debt token to the `onBehalfOf` address.
   * - The resulting rate is the weighted average between the rate of the new debt
   * and the rate of the previous debt
   * @param user The address receiving the borrowed underlying, being the delegatee in case
   * of credit delegate, or same as `onBehalfOf` otherwise
   * @param onBehalfOf The address receiving the debt tokens
   * @param amount The amount of debt tokens to mint
   * @param rate The rate of the debt being minted
   **/
  function mint(
    address user,
    address onBehalfOf,
    uint256 amount,
    uint256 rate
  ) external returns (bool);

  /**
   * @dev Burns debt of `user`
   * - The resulting rate is the weighted average between the rate of the new debt
   * and the rate of the previous debt
   * @param user The address of the user getting his debt burned
   * @param amount The amount of debt tokens getting burned
   **/
  function burn(address user, uint256 amount) external;

  /// @dev Returns the average rate of all the stable rate loans
  function getAverageStableRate() external view returns (uint256);

  /// @dev Returns the stable rate of the user debt
  function getUserStableRate(address user) external view returns (uint256);

  /// @dev Returns the timestamp of the last update of the user
  function getUserLastUpdated(address user) external view returns (uint40);

  /// @dev Returns the principal, the total supply and the average stable rate
  function getSupplyData()
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint40
    );

  /// @dev Returns the timestamp of the last update of the total supply
  function getTotalSupplyLastUpdated() external view returns (uint40);

  /// @dev Returns the total supply and the average stable rate
  function getTotalSupplyAndAvgRate() external view returns (uint256, uint256);

  /// @dev Returns the principal debt balance of the user
  function principalBalanceOf(address user) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IScaledBalanceToken.sol';
import '../dependencies/openzeppelin/contracts/IERC20.sol';
import './IPoolToken.sol';

/// @dev Defines the basic interface for a variable debt token.
interface IVariableDebtToken is IPoolToken, IScaledBalanceToken {
  /**
   * @dev Emitted after the mint action
   * @param from The address performing the mint
   * @param onBehalfOf The address of the user on which behalf minting has been performed
   * @param value The amount to be minted
   * @param index The last index of the reserve
   **/
  event Mint(address indexed from, address indexed onBehalfOf, uint256 value, uint256 index);

  /// @dev Mints debt token to the `onBehalfOf` address. Returns `true` when balance of the `onBehalfOf` was 0
  function mint(
    address user,
    address onBehalfOf,
    uint256 amount,
    uint256 index
  ) external returns (bool);

  /**
   * @dev Emitted when variable debt is burnt
   * @param user The user which debt has been burned
   * @param amount The amount of debt being burned
   * @param index The index of the user
   **/
  event Burn(address indexed user, uint256 amount, uint256 index);

  /// @dev Burns user variable debt
  function burn(
    address user,
    uint256 amount,
    uint256 index
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../../tools/Errors.sol';
import '../types/DataTypes.sol';

/// @dev ReserveConfiguration library, implements the bitmap logic to handle the reserve configuration
library ReserveConfiguration {
  uint256 private constant LTV_MASK =                   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
  uint256 private constant LIQUIDATION_THRESHOLD_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
  uint256 private constant LIQUIDATION_BONUS_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
  uint256 private constant DECIMALS_MASK =              0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
  uint256 private constant ACTIVE_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
  uint256 private constant FROZEN_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
  uint256 private constant BORROWING_MASK =             0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
  uint256 private constant STABLE_BORROWING_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
  uint256 private constant RESERVE_FACTOR_MASK =        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 private constant STRATEGY_TYPE_MASK =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

  /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
  uint256 private constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
  uint256 private constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
  uint256 private constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
  uint256 private constant RESERVE_FACTOR_START_BIT_POSITION = 64;

  uint256 private constant MAX_VALID_LTV = 65535;
  uint256 private constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
  uint256 private constant MAX_VALID_LIQUIDATION_BONUS = 65535;
  uint256 private constant MAX_VALID_DECIMALS = 255;
  uint256 private constant MAX_VALID_RESERVE_FACTOR = 65535;

  /// @dev Sets the Loan to Value of the reserve
  function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv) internal pure {
    require(ltv <= MAX_VALID_LTV, Errors.RC_INVALID_LTV);

    self.data = (self.data & LTV_MASK) | ltv;
  }

  /// @dev Gets the Loan to Value of the reserve
  function getLtv(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
    return self.data & ~LTV_MASK;
  }

  function setLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self, uint256 threshold) internal pure {
    require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.RC_INVALID_LIQ_THRESHOLD);

    self.data = (self.data & LIQUIDATION_THRESHOLD_MASK) | (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
  }

  function getLiquidationThreshold(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
  }

  function setLiquidationBonus(DataTypes.ReserveConfigurationMap memory self, uint256 bonus) internal pure {
    require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.RC_INVALID_LIQ_BONUS);

    self.data = (self.data & LIQUIDATION_BONUS_MASK) | (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
  }

  function getLiquidationBonus(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
  }

  function setDecimals(DataTypes.ReserveConfigurationMap memory self, uint256 decimals) internal pure {
    require(decimals <= MAX_VALID_DECIMALS, Errors.RC_INVALID_DECIMALS);

    self.data = (self.data & DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
  }

  function getDecimals(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
  }

  function getDecimalsMemory(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint8) {
    return uint8((self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION);
  }

  function _setFlag(
    DataTypes.ReserveConfigurationMap memory self,
    uint256 mask,
    bool value
  ) internal pure {
    if (value) {
      self.data |= ~mask;
    } else {
      self.data &= mask;
    }
  }

  function setActive(DataTypes.ReserveConfigurationMap memory self, bool active) internal pure {
    _setFlag(self, ACTIVE_MASK, active);
  }

  function getActive(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~ACTIVE_MASK) != 0;
  }

  function setFrozen(DataTypes.ReserveConfigurationMap memory self, bool frozen) internal pure {
    _setFlag(self, FROZEN_MASK, frozen);
  }

  function getFrozen(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~FROZEN_MASK) != 0;
  }

  function getFrozenMemory(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
    return (self.data & ~FROZEN_MASK) != 0;
  }

  function setBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled) internal pure {
    _setFlag(self, BORROWING_MASK, enabled);
  }

  function getBorrowingEnabled(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~BORROWING_MASK) != 0;
  }

  function setStableRateBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled) internal pure {
    _setFlag(self, STABLE_BORROWING_MASK, enabled);
  }

  function getStableRateBorrowingEnabled(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~STABLE_BORROWING_MASK) != 0;
  }

  function setReserveFactor(DataTypes.ReserveConfigurationMap memory self, uint256 reserveFactor) internal pure {
    require(reserveFactor <= MAX_VALID_RESERVE_FACTOR, Errors.RC_INVALID_RESERVE_FACTOR);

    self.data = (self.data & RESERVE_FACTOR_MASK) | (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
  }

  function getReserveFactor(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
  }

  /// @dev Returns flags: active, frozen, borrowing enabled, stableRateBorrowing enabled
  function getFlags(DataTypes.ReserveConfigurationMap storage self)
    internal
    view
    returns (
      bool,
      bool,
      bool,
      bool
    )
  {
    return _getFlags(self.data);
  }

  function getFlagsMemory(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (
      bool active,
      bool frozen,
      bool borrowEnable,
      bool stableBorrowEnable
    )
  {
    return _getFlags(self.data);
  }

  function _getFlags(uint256 data)
    private
    pure
    returns (
      bool,
      bool,
      bool,
      bool
    )
  {
    return (
      (data & ~ACTIVE_MASK) != 0,
      (data & ~FROZEN_MASK) != 0,
      (data & ~BORROWING_MASK) != 0,
      (data & ~STABLE_BORROWING_MASK) != 0
    );
  }

  /// @dev Paramters of the reserve: ltv, liquidation threshold, liquidation bonus, the reserve decimals
  function getParams(DataTypes.ReserveConfigurationMap storage self)
    internal
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return _getParams(self.data);
  }

  /// @dev Paramters of the reserve: ltv, liquidation threshold, liquidation bonus, the reserve decimals
  function getParamsMemory(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return _getParams(self.data);
  }

  function _getParams(uint256 dataLocal)
    private
    pure
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return (
      dataLocal & ~LTV_MASK,
      (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
      (dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
      (dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
      (dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
    );
  }

  function isExternalStrategyMemory(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
    return (self.data & ~STRATEGY_TYPE_MASK) != 0;
  }

  function isExternalStrategy(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~STRATEGY_TYPE_MASK) != 0;
  }

  function setExternalStrategy(DataTypes.ReserveConfigurationMap memory self, bool isExternal) internal pure {
    _setFlag(self, STRATEGY_TYPE_MASK, isExternal);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../../tools/Errors.sol';
import '../types/DataTypes.sol';

/// @dev Implements the bitmap logic to handle the user configuration
library UserConfiguration {
  uint256 private constant ANY_BORROWING_MASK = 0x5555555555555555555555555555555555555555555555555555555555555555;
  uint256 private constant BORROW_BIT_MASK = 1;
  uint256 private constant COLLATERAL_BIT_MASK = 2;
  uint256 internal constant ANY_MASK = BORROW_BIT_MASK | COLLATERAL_BIT_MASK;
  uint256 internal constant SHIFT_STEP = 2;

  function setBorrowing(DataTypes.UserConfigurationMap storage self, uint256 reserveIndex) internal {
    self.data |= BORROW_BIT_MASK << (reserveIndex << 1);
  }

  function unsetBorrowing(DataTypes.UserConfigurationMap storage self, uint256 reserveIndex) internal {
    self.data &= ~(BORROW_BIT_MASK << (reserveIndex << 1));
  }

  function setUsingAsCollateral(DataTypes.UserConfigurationMap storage self, uint256 reserveIndex) internal {
    self.data |= COLLATERAL_BIT_MASK << (reserveIndex << 1);
  }

  function unsetUsingAsCollateral(DataTypes.UserConfigurationMap storage self, uint256 reserveIndex) internal {
    self.data &= ~(COLLATERAL_BIT_MASK << (reserveIndex << 1));
  }

  /// @dev Returns true if the user is using the reserve for borrowing
  function isBorrowing(DataTypes.UserConfigurationMap memory self, uint256 reserveIndex) internal pure returns (bool) {
    return (self.data >> (reserveIndex << 1)) & BORROW_BIT_MASK != 0;
  }

  /// @dev Returns true if the user is using the reserve as collateral
  function isUsingAsCollateral(DataTypes.UserConfigurationMap memory self, uint256 reserveIndex)
    internal
    pure
    returns (bool)
  {
    return (self.data >> (reserveIndex << 1)) & COLLATERAL_BIT_MASK != 0;
  }

  /// @dev Returns true if the user is borrowing from any reserve
  function isBorrowingAny(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {
    return self.data & ANY_BORROWING_MASK != 0;
  }

  /// @dev Returns true if the user is not using any reserve
  function isEmpty(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {
    return self.data == 0;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

library DataTypes {
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
    address depositTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the reserve strategy
    address strategy;
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
    //bit 80: strategy is external
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}

  struct InitReserveData {
    address asset;
    address depositTokenAddress;
    address stableDebtAddress;
    address variableDebtAddress;
    address strategy;
    bool externalStrategy;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IReserveStrategy.sol';

/// @dev Strategy to control a lending pool reserve
interface IReserveRateStrategy is IReserveStrategy {
  function baseVariableBorrowRate() external view returns (uint256);

  function getMaxVariableBorrowRate() external view returns (uint256);

  function calculateInterestRates(
    address reserve,
    address depositToken,
    uint256 liquidityAdded,
    uint256 liquidityTaken,
    uint256 totalStableDebt,
    uint256 totalVariableDebt,
    uint256 averageStableBorrowRate,
    uint256 reserveFactor
  )
    external
    view
    returns (
      uint256 liquidityRate,
      uint256 stableBorrowRate,
      uint256 variableBorrowRate
    );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IPriceOracleProvider.sol';

interface IPoolAddressProvider is IPriceOracleProvider {
  function getLendingPool() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../interfaces/IPoolAddressProvider.sol';

interface IUiPoolDataProvider {
  struct Addresses {
    address addressProvider;
    address lendingPool;
    address stakeConfigurator;
    address rewardConfigurator;
    address rewardController;
    address wethGateway;
    address priceOracle;
    address lendingPriceOracle;
    address rewardToken;
    address rewardStake;
    address referralRegistry;
  }

  function getAddresses() external view returns (Addresses memory);

  struct AggregatedReserveData {
    address underlyingAsset;
    address pricingAsset;
    string name;
    string symbol;
    uint256 decimals;
    uint256 baseLTVasCollateral;
    uint256 reserveLiquidationThreshold;
    uint256 reserveLiquidationBonus;
    uint256 reserveFactor;
    bool usageAsCollateralEnabled;
    bool borrowingEnabled;
    bool stableBorrowRateEnabled;
    bool isActive;
    bool isFrozen;
    // base data
    uint128 liquidityIndex;
    uint128 variableBorrowIndex;
    uint128 liquidityRate;
    uint128 variableBorrowRate;
    uint128 stableBorrowRate;
    uint40 lastUpdateTimestamp;
    address depositTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    address strategy;
    bool isExternalStrategy;
    //
    uint256 availableLiquidity;
    uint256 totalPrincipalStableDebt;
    uint256 averageStableRate;
    uint256 totalStableDebt;
    uint256 stableDebtLastUpdateTimestamp;
    uint256 totalScaledVariableDebt;
    uint256 priceInEth;
  }

  struct UserReserveData {
    address underlyingAsset;
    uint256 scaledDepositTokenBalance;
    bool usageAsCollateralEnabledOnUser;
    uint256 stableBorrowRate;
    uint256 scaledVariableDebt;
    uint256 principalStableDebt;
    uint256 stableBorrowLastUpdateTimestamp;
  }

  function getReservesData(address user)
    external
    view
    returns (
      AggregatedReserveData[] memory,
      UserReserveData[] memory,
      uint256
    );

  function getReserveData(address asset)
    external
    view
    returns (
      uint256 availableLiquidity,
      uint256 totalStableDebt,
      uint256 totalVariableDebt,
      uint256 liquidityRate,
      uint256 variableBorrowRate,
      uint256 stableBorrowRate,
      uint256 averageStableBorrowRate,
      uint256 liquidityIndex,
      uint256 variableBorrowIndex,
      uint40 lastUpdateTimestamp
    );

  function getUserReserveData(address asset, address user)
    external
    view
    returns (
      uint256 currentDepositBalance,
      uint256 currentStableDebt,
      uint256 currentVariableDebt,
      uint256 principalStableDebt,
      uint256 scaledVariableDebt,
      uint256 stableBorrowRate,
      uint256 liquidityRate,
      uint40 stableRateLastUpdated,
      bool usageAsCollateralEnabled
    );

  enum TokenType {
    PoolAsset,
    Deposit,
    VariableDebt,
    StableDebt,
    Stake,
    Reward,
    RewardStake
  }

  struct TokenDescription {
    address token;
    // priceToken == 0 for a non-transferrable token
    address priceToken;
    address rewardPool;
    string tokenSymbol;
    address underlying;
    uint8 decimals;
    TokenType tokenType;
    bool active;
    bool frozen;
  }

  function getAllTokenDescriptions(bool includeAssets)
    external
    view
    returns (TokenDescription[] memory tokens, uint256 tokenCount);

  function getAllTokens(bool includeAssets)
    external
    view
    returns (
      address[] memory tokens,
      uint256 tokenCount,
      TokenType[] memory tokenTypes
    );

  function getReserveConfigurationData(address asset)
    external
    view
    returns (
      uint256 decimals,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      uint256 reserveFactor,
      bool usageAsCollateralEnabled,
      bool borrowingEnabled,
      bool stableBorrowRateEnabled,
      bool isActive,
      bool isFrozen
    );

  struct TokenBalance {
    uint256 balance;
    uint256 underlyingBalance;
    uint256 rewardedBalance;
    uint32 unstakeWindowStart;
    uint32 unstakeWindowEnd;
  }

  function batchBalanceOf(
    address[] calldata users,
    address[] calldata tokens,
    TokenType[] calldata tokenTypes,
    TokenType defType
  ) external view returns (TokenBalance[] memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IPriceOracleEvents {
  event AssetPriceUpdated(address asset, uint256 price, uint256 timestamp);
  event EthPriceUpdated(uint256 price, uint256 timestamp);
  event DerivedAssetSourceUpdated(
    address indexed asset,
    uint256 index,
    address indexed underlyingSource,
    uint256 underlyingPrice,
    uint256 timestamp
  );
}

/// @dev Interface for a price oracle.
interface IPriceOracleGetter is IPriceOracleEvents {
  /// @dev returns the asset price in ETH
  function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../dependencies/openzeppelin/contracts/IERC20.sol';
import './IScaledBalanceToken.sol';
import './IPoolToken.sol';

interface IDepositToken is IERC20, IPoolToken, IScaledBalanceToken {
  /**
   * @dev Emitted on mint
   * @param account The receiver of minted tokens
   * @param value The amount minted
   * @param index The new liquidity index of the reserve
   **/
  event Mint(address indexed account, uint256 value, uint256 index);

  /**
   * @dev Mints `amount` depositTokens to `user`
   * @param user The address receiving the minted tokens
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   * @param repayOverdraft Enables to use this amount cover an overdraft
   * @return `true` if the the previous balance of the user was 0
   */
  function mint(
    address user,
    uint256 amount,
    uint256 index,
    bool repayOverdraft
  ) external returns (bool);

  /**
   * @dev Emitted on burn
   * @param account The owner of tokens burned
   * @param target The receiver of the underlying
   * @param value The amount burned
   * @param index The new liquidity index of the reserve
   **/
  event Burn(address indexed account, address indexed target, uint256 value, uint256 index);

  /**
   * @dev Emitted on transfer
   * @param from The sender
   * @param to The recipient
   * @param value The amount transferred
   * @param index The new liquidity index of the reserve
   **/
  event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

  /**
   * @dev Burns depositTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * @param user The owner of the depositTokens, getting them burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param amount The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  function burn(
    address user,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 index
  ) external;

  /**
   * @dev Mints depositTokens to the reserve treasury
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   */
  function mintToTreasury(uint256 amount, uint256 index) external;

  /**
   * @dev Transfers depositTokens in the event of a borrow being liquidated, in case the liquidators reclaims the depositToken
   * @param from The address getting liquidated, current owner of the depositTokens
   * @param to The recipient
   * @param value The amount of tokens getting transferred
   * @param index The liquidity index of the reserve
   * @param transferUnderlying is true when the underlying should be, otherwise the depositToken
   * @return true when transferUnderlying is false and the recipient had zero balance
   **/
  function transferOnLiquidation(
    address from,
    address to,
    uint256 value,
    uint256 index,
    bool transferUnderlying
  ) external returns (bool);

  /**
   * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
   * assets in borrow(), withdraw() and flashLoan()
   * @param user The recipient of the underlying
   * @param amount The amount getting transferred
   * @return The amount transferred
   **/
  function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);

  function collateralBalanceOf(address) external view returns (uint256);

  /**
   * @dev Emitted on use of overdraft (by liquidation)
   * @param account The receiver of overdraft (user with shortage)
   * @param value The amount received
   * @param index The liquidity index of the reserve
   **/
  event OverdraftApplied(address indexed account, uint256 value, uint256 index);

  /**
   * @dev Emitted on return of overdraft allowance when it was fully or partially used
   * @param provider The provider of overdraft
   * @param recipient The receiver of overdraft
   * @param overdraft The amount overdraft that was covered by the provider
   * @param index The liquidity index of the reserve
   **/
  event OverdraftCovered(address indexed provider, address indexed recipient, uint256 overdraft, uint256 index);

  event SubBalanceProvided(address indexed provider, address indexed recipient, uint256 amount, uint256 index);
  event SubBalanceReturned(address indexed provider, address indexed recipient, uint256 amount, uint256 index);
  event SubBalanceLocked(address indexed provider, uint256 amount, uint256 index);
  event SubBalanceUnlocked(address indexed provider, uint256 amount, uint256 index);

  function updateTreasury() external;

  function addSubBalanceOperator(address addr) external;

  function addStakeOperator(address addr) external;

  function removeSubBalanceOperator(address addr) external;

  function provideSubBalance(
    address provider,
    address recipient,
    uint256 scaledAmount
  ) external;

  function returnSubBalance(
    address provider,
    address recipient,
    uint256 scaledAmount,
    bool preferOverdraft
  ) external returns (uint256 coveredOverdraft);

  function lockSubBalance(address provider, uint256 scaledAmount) external;

  function unlockSubBalance(
    address provider,
    uint256 scaledAmount,
    address transferTo
  ) external;

  function replaceSubBalance(
    address prevProvider,
    address recipient,
    uint256 prevScaledAmount,
    address newProvider,
    uint256 newScaledAmount
  ) external returns (uint256 coveredOverdraftByPrevProvider);

  function transferLockedBalance(
    address from,
    address to,
    uint256 scaledAmount
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

// solhint-disable func-name-mixedcase
interface IDerivedToken {
  /**
   * @dev Returns the address of the underlying asset of this token (E.g. WETH for agWETH)
   **/
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IRewardedToken {
  function setIncentivesController(address) external;

  function getIncentivesController() external view returns (address);

  function rewardedBalanceOf(address) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IUnderlyingBalance {
  /// @dev Returns amount of underlying for the given address
  function balanceOfUnderlying(address account) external view returns (uint256);
}

interface ILockedUnderlyingBalance is IUnderlyingBalance {
  /// @dev Returns amount of underlying and a timestamp when the lock expires. Funds can be redeemed after the timestamp.
  function balanceOfUnderlyingAndExpiry(address account)
    external
    view
    returns (uint256 underlying, uint32 availableSince);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../interfaces/IEmergencyAccess.sol';

interface IManagedRewardPool is IEmergencyAccess {
  function updateBaseline(uint256) external returns (bool hasBaseline, uint256 appliedRate);

  function setBaselinePercentage(uint16) external;

  function getBaselinePercentage() external view returns (uint16);

  function getRate() external view returns (uint256);

  function getPoolName() external view returns (string memory);

  function claimRewardFor(address holder, uint256 limit)
    external
    returns (
      uint256 amount,
      uint32 since,
      bool keepPull
    );

  function calcRewardFor(address holder, uint32 at)
    external
    view
    returns (
      uint256 amount,
      uint256 extra,
      uint32 since
    );

  function addRewardProvider(address provider, address token) external;

  function removeRewardProvider(address provider) external;

  function getRewardController() external view returns (address);

  function attachedToRewardController() external;

  event RateUpdated(uint256 rate);
  event BaselinePercentageUpdated(uint16);
  event ProviderAdded(address provider, address token);
  event ProviderRemoved(address provider);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IRewardExplainer {
  /// @dev provides in depth details about rewards of the holder. Accuracy of future projection is not guaranteed.
  /// @dev NB! explanation does not consider auto-locking
  /// @param at is a timestamp (current or future) to calculate rewards
  /// @return details of rewards, see RewardExplained
  function explainReward(address holder, uint32 at) external view returns (RewardExplained memory);
}

/// @dev details of rewards of a holder, please refer to tokenomics on reward calculations
struct RewardExplained {
  /// @dev total amount of rewards that will be claimed (including boost)
  uint256 amountClaimable;
  /// @dev total amount of rewards allocated to the holder but are frozen now
  uint256 amountExtra;
  /// @dev maximum possible amount of boost generated by xAGF
  uint256 maxBoost;
  /// @dev maximum allowed amount of boost based on work rewards (from deposits, debts, stakes etc)
  uint256 boostLimit;
  /// @dev timestamp of the latest claim
  uint32 latestClaimAt;
  /// @dev a list of pools currently generating rewards to the holder
  RewardExplainEntry[] allocations;
}

/// @dev details of reward generation by a reward pool
struct RewardExplainEntry {
  /// @dev amount of rewards generated by the reward pool since last update (see `since`)
  uint256 amount;
  /// @dev amount of rewards frozen by the reward pool
  uint256 extra;
  /// @dev address of the reward pool
  address pool;
  /// @dev timestamp of a last update of the holder in the reward pool (e.g. claim or balance change)
  uint32 since;
  /// @dev multiplication factor in basis points (10000=100%) to calculate boost limit by outcome of the pool
  uint32 factor;
  /// @dev type of reward pool: boost (added to the max boost) or work (added to the claimable amount and to the boost limit)
  RewardType rewardType;
}

enum RewardType {
  WorkReward,
  BoostReward
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './StakeTokenConfig.sol';

interface IStakeConfigurator {
  struct InitStakeTokenData {
    address stakeTokenImpl;
    address stakedToken;
    address strategy;
    string stkTokenName;
    string stkTokenSymbol;
    uint32 cooldownPeriod;
    uint32 unstakePeriod;
    uint16 maxSlashable;
    uint8 stkTokenDecimals;
    bool depositStake;
  }

  struct UpdateStakeTokenData {
    address token;
    address stakeTokenImpl;
    string stkTokenName;
    string stkTokenSymbol;
  }

  struct StakeTokenData {
    address token;
    string stkTokenName;
    string stkTokenSymbol;
    StakeTokenConfig config;
  }

  event StakeTokenInitialized(address indexed token, InitStakeTokenData data);

  event StakeTokenUpgraded(address indexed token, UpdateStakeTokenData data);

  event StakeTokenAdded(address indexed token, address indexed underlying);

  event StakeTokenRemoved(address indexed token, address indexed underlying);

  function list() external view returns (address[] memory tokens);

  function dataOf(address stakeToken) external view returns (StakeTokenData memory data);

  function stakeTokenOf(address underlying) external view returns (address);

  function getStakeTokensData() external view returns (StakeTokenData[] memory dataList, uint256 count);

  function setCooldownForAll(uint32 cooldownPeriod, uint32 unstakePeriod) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../../interfaces/IDerivedToken.sol';
import '../../../interfaces/IRewardedToken.sol';
import '../../../interfaces/IUnderlyingBalance.sol';

interface IStakeToken is IDerivedToken, IRewardedToken, IUnderlyingBalance {
  event Staked(address indexed from, address indexed to, uint256 amount, uint256 indexed referal);
  event Redeemed(address indexed from, address indexed to, uint256 amount, uint256 underlyingAmount);
  event CooldownStarted(address indexed account, uint32 at);

  function stake(
    address to,
    uint256 underlyingAmount,
    uint256 referral
  ) external returns (uint256 stakeAmount);

  /**
   * @dev Redeems staked tokens, and stop earning rewards. Reverts if cooldown is not finished or is outside of the unstake window.
   * @param to Address to redeem to
   * @param stakeAmount Amount of stake to redeem
   **/
  function redeem(address to, uint256 maxStakeAmount) external returns (uint256 stakeAmount);

  /**
   * @dev Redeems staked tokens, and stop earning rewards. Reverts if cooldown is not finished or is outside of the unstake window.
   * @param to Address to redeem to
   * @param underlyingAmount Amount of underlying to redeem
   **/
  function redeemUnderlying(address to, uint256 maxUnderlyingAmount) external returns (uint256 underlyingAmount);

  /// @dev Activates the cooldown period to unstake. Reverts if the user has no stake.
  function cooldown() external;

  /// @dev Returns beginning of the current cooldown period or zero when cooldown was not triggered.
  function getCooldown(address) external view returns (uint32);

  function exchangeRate() external view returns (uint256);

  function isRedeemable() external view returns (bool);

  function getMaxSlashablePercentage() external view returns (uint16);

  function balanceAndCooldownOf(address holder)
    external
    view
    returns (
      uint256 balance,
      uint32 windowStart,
      uint32 windowEnd
    );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP excluding events to avoid linearization issues.
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
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IERC20Details {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IRemoteAccessBitmask.sol';
import '../../tools/upgradeability/IProxy.sol';

/// @dev Main registry of permissions and addresses
interface IAccessController is IRemoteAccessBitmask {
  function getAddress(uint256 id) external view returns (address);

  function createProxy(
    address admin,
    address impl,
    bytes calldata params
  ) external returns (IProxy);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IRemoteAccessBitmask {
  /**
   * @dev Returns access flags granted to the given address and limited by the filterMask. filterMask == 0 has a special meaning.
   * @param addr an to get access perfmissions for
   * @param filterMask limits a subset of flags to be checked.
   * NB! When filterMask == 0 then zero is returned no flags granted, or an unspecified non-zero value otherwise.
   * @return Access flags currently granted
   */
  function queryAccessControlMask(address addr, uint256 filterMask) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IProxy {
  function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../access/interfaces/IMarketAccessController.sol';
import '../protocol/libraries/types/DataTypes.sol';

interface ILendingPoolEvents {
  /// @dev Emitted on deposit()
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 indexed referral
  );

  /// @dev Emitted on withdraw()
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /// @dev Emitted on borrow() and flashLoan() when debt needs to be opened
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint256 indexed referral
  );

  /// @dev Emitted on repay()
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  /// @dev Emitted on swapBorrowRateMode()
  event Swap(address indexed reserve, address indexed user, uint256 rateMode);

  /// @dev Emitted on setUserUseReserveAsCollateral()
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /// @dev Emitted on setUserUseReserveAsCollateral()
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /// @dev Emitted on rebalanceStableBorrowRate()
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /// @dev Emitted on flashLoan()
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint256 referral
  );

  /// @dev Emitted when a borrower is liquidated.
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveDeposit
  );

  /// @dev Emitted when the state of a reserve is updated.
  event ReserveDataUpdated(
    address indexed underlying,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  event LendingPoolExtensionUpdated(address extension);

  event DisabledFeaturesUpdated(uint16 disabledFeatures);

  event FlashLoanPremiumUpdated(uint16 premium);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IEmergencyAccessGroup {
  function setPausedFor(address subject, bool paused) external;

  function isPausedFor(address subject) external view returns (bool);

  function listEmergencyGroup() external view returns (address[] memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IBalanceHook {
  function handleBalanceUpdate(
    address token,
    address holder,
    uint256 oldBalance,
    uint256 newBalance,
    uint256 providerSupply
  ) external;

  function handleScaledBalanceUpdate(
    address token,
    address holder,
    uint256 oldBalance,
    uint256 newBalance,
    uint256 providerSupply,
    uint256 scaleRay
  ) external;

  function isScaledBalanceUpdateNeeded() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IDerivedToken.sol';

// solhint-disable func-name-mixedcase
interface IPoolToken is IDerivedToken {
  function POOL() external view returns (address);

  function updatePool() external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IScaledBalanceToken {
  /**
   * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
   * updated stored balance divided by the reserve's liquidity index at the moment of the update
   * @param user The user whose balance is calculated
   * @return The scaled balance of the user
   **/
  function scaledBalanceOf(address user) external view returns (uint256);

  /**
   * @dev Returns the scaled balance of the user and the scaled total supply.
   * @param user The address of the user
   * @return The scaled balance of the user
   * @return The scaled balance and the scaled total supply
   **/
  function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

  /**
   * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
   * @return The scaled total supply
   **/
  function scaledTotalSupply() external view returns (uint256);

  function getScaleIndex() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @title Errors library
 * @notice Defines the error messages emitted by the different contracts
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - MATH = Math libraries
 *  - CT = Common errors between tokens (DepositToken, VariableDebtToken and StableDebtToken)
 *  - AT = DepositToken
 *  - SDT = StableDebtToken
 *  - VDT = VariableDebtToken
 *  - LP = LendingPool
 *  - LPAPR = AddressesProviderRegistry
 *  - LPC = LendingPoolConfiguration
 *  - RL = ReserveLogic
 *  - LPCM = LendingPoolExtension
 *  - ST = Stake
 */
library Errors {
  //contract specific errors
  string public constant VL_INVALID_AMOUNT = '1'; // Amount must be greater than 0
  string public constant VL_NO_ACTIVE_RESERVE = '2'; // Action requires an active reserve
  string public constant VL_RESERVE_FROZEN = '3'; // Action cannot be performed because the reserve is frozen
  string public constant VL_UNKNOWN_RESERVE = '4'; // Action requires an active reserve
  string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = '5'; // User cannot withdraw more than the available balance (above min limit)
  string public constant VL_TRANSFER_NOT_ALLOWED = '6'; // Transfer cannot be allowed.
  string public constant VL_BORROWING_NOT_ENABLED = '7'; // Borrowing is not enabled
  string public constant VL_INVALID_INTEREST_RATE_MODE_SELECTED = '8'; // Invalid interest rate mode selected
  string public constant VL_COLLATERAL_BALANCE_IS_0 = '9'; // The collateral balance is 0
  string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = '10'; // Health factor is lesser than the liquidation threshold
  string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = '11'; // There is not enough collateral to cover a new borrow
  string public constant VL_STABLE_BORROWING_NOT_ENABLED = '12'; // stable borrowing not enabled
  string public constant VL_COLLATERAL_SAME_AS_BORROWING_CURRENCY = '13'; // collateral is (mostly) the same currency that is being borrowed
  string public constant VL_AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = '14'; // The requested amount is exceeds max size of a stable loan
  string public constant VL_NO_DEBT_OF_SELECTED_TYPE = '15'; // to repay a debt, user needs to specify a correct debt type (variable or stable)
  string public constant VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = '16'; // To repay on behalf of an user an explicit amount to repay is needed
  string public constant VL_NO_STABLE_RATE_LOAN_IN_RESERVE = '17'; // User does not have a stable rate loan in progress on this reserve
  string public constant VL_NO_VARIABLE_RATE_LOAN_IN_RESERVE = '18'; // User does not have a variable rate loan in progress on this reserve
  string public constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = '19'; // The collateral balance needs to be greater than 0
  string public constant VL_DEPOSIT_ALREADY_IN_USE = '20'; // User deposit is already being used as collateral
  string public constant VL_RESERVE_MUST_BE_COLLATERAL = '21'; // This reserve must be enabled as collateral
  string public constant LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '22'; // Interest rate rebalance conditions were not met
  string public constant AT_OVERDRAFT_DISABLED = '23'; // User doesn't accept allocation of overdraft
  string public constant VL_INVALID_SUB_BALANCE_ARGS = '24';
  string public constant AT_INVALID_SLASH_DESTINATION = '25';

  string public constant LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR = '27'; // The caller of the function is not the lending pool configurator

  string public constant LENDING_POOL_REQUIRED = '28'; // The caller of this function must be a lending pool
  string public constant CALLER_NOT_LENDING_POOL = '29'; // The caller of this function must be a lending pool
  string public constant AT_SUB_BALANCE_RESTIRCTED_FUNCTION = '30'; // The caller of this function must be a lending pool or a sub-balance operator

  string public constant RL_RESERVE_ALREADY_INITIALIZED = '32'; // Reserve has already been initialized
  string public constant CALLER_NOT_POOL_ADMIN = '33'; // The caller must be the pool admin
  string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = '34'; // The liquidity of the reserve needs to be 0

  string public constant LPAPR_PROVIDER_NOT_REGISTERED = '41'; // Provider is not registered
  string public constant LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '42'; // Health factor is not below the threshold
  string public constant LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED = '43'; // The collateral chosen cannot be liquidated
  string public constant LPCM_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = '44'; // User did not borrow the specified currency
  string public constant LPCM_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE = '45'; // There isn't enough liquidity available to liquidate

  string public constant MATH_MULTIPLICATION_OVERFLOW = '48';
  string public constant MATH_ADDITION_OVERFLOW = '49';
  string public constant MATH_DIVISION_BY_ZERO = '50';
  string public constant RL_LIQUIDITY_INDEX_OVERFLOW = '51'; //  Liquidity index overflows uint128
  string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = '52'; //  Variable borrow index overflows uint128
  string public constant RL_LIQUIDITY_RATE_OVERFLOW = '53'; //  Liquidity rate overflows uint128
  string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = '54'; //  Variable borrow rate overflows uint128
  string public constant RL_STABLE_BORROW_RATE_OVERFLOW = '55'; //  Stable borrow rate overflows uint128
  string public constant CT_INVALID_MINT_AMOUNT = '56'; //invalid amount to mint
  string public constant CALLER_NOT_STAKE_ADMIN = '57';
  string public constant CT_INVALID_BURN_AMOUNT = '58'; //invalid amount to burn
  string public constant BORROW_ALLOWANCE_NOT_ENOUGH = '59'; // User borrows on behalf, but allowance are too small
  string public constant CALLER_NOT_LIQUIDITY_CONTROLLER = '60';
  string public constant CALLER_NOT_REF_ADMIN = '61';
  string public constant VL_INSUFFICIENT_REWARD_AVAILABLE = '62';
  string public constant LP_CALLER_MUST_BE_DEPOSIT_TOKEN = '63';
  string public constant LP_IS_PAUSED = '64'; // Pool is paused
  string public constant LP_NO_MORE_RESERVES_ALLOWED = '65';
  string public constant LP_INVALID_FLASH_LOAN_EXECUTOR_RETURN = '66';
  string public constant RC_INVALID_LTV = '67';
  string public constant RC_INVALID_LIQ_THRESHOLD = '68';
  string public constant RC_INVALID_LIQ_BONUS = '69';
  string public constant RC_INVALID_DECIMALS = '70';
  string public constant RC_INVALID_RESERVE_FACTOR = '71';
  string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = '72';
  string public constant VL_INCONSISTENT_FLASHLOAN_PARAMS = '73';
  string public constant VL_TREASURY_REQUIRED = '74';
  string public constant LPC_INVALID_CONFIGURATION = '75'; // Invalid risk parameters for the reserve
  string public constant CALLER_NOT_EMERGENCY_ADMIN = '76'; // The caller must be the emergency admin
  string public constant UL_INVALID_INDEX = '77';
  string public constant VL_CONTRACT_REQUIRED = '78';
  string public constant SDT_STABLE_DEBT_OVERFLOW = '79';
  string public constant SDT_BURN_EXCEEDS_BALANCE = '80';
  string public constant CALLER_NOT_REWARD_CONFIG_ADMIN = '81'; // The caller of this function must be a reward admin
  string public constant LP_INVALID_PERCENTAGE = '82'; // Percentage can't be more than 100%
  string public constant LP_IS_NOT_TRUSTED_FLASHLOAN = '83';
  string public constant CALLER_NOT_SWEEP_ADMIN = '84';
  string public constant LP_TOO_MANY_NESTED_CALLS = '85';
  string public constant LP_RESTRICTED_FEATURE = '86';
  string public constant LP_TOO_MANY_FLASHLOAN_CALLS = '87';
  string public constant RW_BASELINE_EXCEEDED = '88';
  string public constant CALLER_NOT_REWARD_RATE_ADMIN = '89';
  string public constant CALLER_NOT_REWARD_CONTROLLER = '90';
  string public constant RW_REWARD_PAUSED = '91';
  string public constant CALLER_NOT_TEAM_MANAGER = '92';
  string public constant STK_REDEEM_PAUSED = '93';
  string public constant STK_INSUFFICIENT_COOLDOWN = '94';
  string public constant STK_UNSTAKE_WINDOW_FINISHED = '95';
  string public constant STK_INVALID_BALANCE_ON_COOLDOWN = '96';
  string public constant STK_EXCESSIVE_SLASH_PCT = '97';
  string public constant STK_WRONG_COOLDOWN_OR_UNSTAKE = '98';
  string public constant STK_PAUSED = '99';

  string public constant TXT_OWNABLE_CALLER_NOT_OWNER = 'Ownable: caller is not the owner';
  string public constant TXT_CALLER_NOT_PROXY_OWNER = 'ProxyOwner: caller is not the owner';
  string public constant TXT_ACCESS_RESTRICTED = 'RESTRICTED';
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IReserveStrategy {
  function isDelegatedReserve() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IPriceOracleProvider {
  function getPriceOracle() external view returns (address);

  function getLendingRateOracle() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IEmergencyAccess {
  function setPaused(bool paused) external;

  function isPaused() external view returns (bool);

  event EmergencyPaused(address indexed by, bool paused);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import '../../../access/interfaces/IMarketAccessController.sol';
import '../../../interfaces/IUnderlyingStrategy.sol';

struct StakeTokenConfig {
  IMarketAccessController stakeController;
  IERC20 stakedToken;
  IUnderlyingStrategy strategy;
  uint32 cooldownPeriod;
  uint32 unstakePeriod;
  uint16 maxSlashable;
  uint8 stakedTokenDecimals;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IUnderlyingStrategy {
  function getUnderlying(address asset) external view returns (address);

  function delegatedWithdrawUnderlying(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);
}

