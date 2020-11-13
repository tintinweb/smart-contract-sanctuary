// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

library CoreLibrary {
  enum InterestRateMode {NONE, STABLE, VARIABLE}
}


interface ILendingPoolAddressesProvider {
  function getLendingPool() external view returns (address);

  function getLendingPoolCore() external view returns (address payable);

  function getLendingPoolDataProvider() external view returns (address);

  function getLendingPoolParametersProvider() external view returns (address);

  function getPriceOracle() external view returns (address);
}

interface ILendingPoolCore {
  function getReserves() external view returns (address[] memory);

  function getReserveTotalLiquidity(address _reserve) external view returns (uint256);

  function getReserveAvailableLiquidity(address _reserve) external view returns (uint256);

  function getReserveTotalBorrowsStable(address _reserve) external view returns (uint256);

  function getReserveTotalBorrowsVariable(address _reserve) external view returns (uint256);

  function getReserveCurrentLiquidityRate(address _reserve) external view returns (uint256);

  function getReserveCurrentVariableBorrowRate(address _reserve) external view returns (uint256);

  function getReserveCurrentStableBorrowRate(address _reserve) external view returns (uint256);

  function getReserveCurrentAverageStableBorrowRate(address _reserve)
    external
    view
    returns (uint256);

  function getReserveUtilizationRate(address _reserve) external view returns (uint256);

  function getReserveLiquidityCumulativeIndex(address _reserve) external view returns (uint256);

  function getReserveVariableBorrowsCumulativeIndex(address _reserve)
    external
    view
    returns (uint256);

  function getReserveATokenAddress(address _reserve) external view returns (address);

  function getReserveLastUpdate(address _reserve) external view returns (uint40);

  // configuration
  function getReserveConfiguration(address _reserve)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      bool
    );

  function getReserveIsStableBorrowRateEnabled(address _reserve) external view returns (bool);

  function isReserveBorrowingEnabled(address _reserve) external view returns (bool);

  function getReserveIsActive(address _reserve) external view returns (bool);

  function getReserveIsFreezed(address _reserve) external view returns (bool);

  function getReserveLiquidationBonus(address _reserve) external view returns (uint256);

  // user related
  function getUserOriginationFee(address _reserve, address _user) external view returns (uint256);

  function getUserBorrowBalances(address _reserve, address _user)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  function getUserCurrentBorrowRateMode(address _reserve, address _user)
    external
    view
    returns (CoreLibrary.InterestRateMode);

  function getUserCurrentStableBorrowRate(address _reserve, address _user)
    external
    view
    returns (uint256);

  function getUserVariableBorrowCumulativeIndex(address _reserve, address _user)
    external
    view
    returns (uint256);

  function getUserLastUpdate(address _reserve, address _user) external view returns (uint40);

  function isUserUseReserveAsCollateralEnabled(address _reserve, address _user)
    external
    view
    returns (bool);
}


interface IAToken {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function underlyingAssetAddress() external view returns (address);

  function principalBalanceOf(address _user) external view returns (uint256);

  function getUserIndex(address _user) external view returns (uint256);

  function getInterestRedirectionAddress(address _user) external view returns (address);

  function getRedirectedBalance(address _user) external view returns (uint256);
}


interface IPoolDataProvider {
  struct ReserveData {
    address underlyingAsset;
    string name;
    string symbol;
    uint8 decimals;
    bool isActive;
    bool isFreezed;
    bool usageAsCollateralEnabled;
    bool borrowingEnabled;
    bool stableBorrowRateEnabled;
    uint256 baseLTVasCollateral;
    uint256 averageStableBorrowRate;
    uint256 liquidityIndex;
    uint256 reserveLiquidationThreshold;
    uint256 reserveLiquidationBonus;
    uint256 variableBorrowIndex;
    uint256 variableBorrowRate;
    uint256 availableLiquidity;
    uint256 stableBorrowRate;
    uint256 liquidityRate;
    uint256 totalBorrowsStable;
    uint256 totalBorrowsVariable;
    uint256 totalLiquidity;
    uint256 utilizationRate;
    uint40 lastUpdateTimestamp;
    uint256 priceInEth;
    address aTokenAddress;
  }

  struct UserReserveData {
    address underlyingAsset;
    uint256 principalATokenBalance;
    uint256 userBalanceIndex;
    uint256 redirectedBalance;
    address interestRedirectionAddress;
    bool usageAsCollateralEnabledOnUser;
    uint256 borrowRate;
    CoreLibrary.InterestRateMode borrowRateMode;
    uint256 originationFee;
    uint256 principalBorrows;
    uint256 variableBorrowIndex;
    uint256 lastUpdateTimestamp;
  }

  struct ATokenSupplyData {
    string name;
    string symbol;
    uint8 decimals;
    uint256 totalSupply;
    address aTokenAddress;
  }

  function getReservesData(ILendingPoolAddressesProvider provider)
    external
    view
    returns (ReserveData[] memory, uint256);

  function getUserReservesData(ILendingPoolAddressesProvider provider, address user)
    external
    view
    returns (UserReserveData[] memory);

  function getAllATokenSupply(ILendingPoolAddressesProvider provider)
    external
    view
    returns (ATokenSupplyData[] memory);

  function getATokenSupply(address[] calldata aTokens)
    external
    view
    returns (ATokenSupplyData[] memory);
}


interface IChainlinkProxyPriceProvider {
  function getAssetPrice(address _asset) external view returns (uint256);
}




contract PoolDataProvider is IPoolDataProvider {
  constructor() public {}

  address public constant MOCK_USD_ADDRESS = 0x10F7Fc1F91Ba351f9C629c5947AD69bD03C05b96;

  function getReservesData(ILendingPoolAddressesProvider provider)
    external
    override
    view
    returns (ReserveData[] memory, uint256)
  {
    ILendingPoolCore core = ILendingPoolCore(provider.getLendingPoolCore());
    IChainlinkProxyPriceProvider oracle = IChainlinkProxyPriceProvider(provider.getPriceOracle());

    address[] memory reserves = core.getReserves();
    ReserveData[] memory reservesData = new ReserveData[](reserves.length);

    address reserve;
    for (uint256 i = 0; i < reserves.length; i++) {
      reserve = reserves[i];
      ReserveData memory reserveData = reservesData[i];

      // base asset info
      reserveData.aTokenAddress = core.getReserveATokenAddress(reserve);
      IAToken assetDetails = IAToken(reserveData.aTokenAddress);
      reserveData.decimals = assetDetails.decimals();
      // we're getting this info from the aToken, because some of assets can be not compliant with ETC20Detailed
      reserveData.symbol = assetDetails.symbol();
      reserveData.name = '';

      // reserve configuration
      reserveData.underlyingAsset = reserve;
      reserveData.isActive = core.getReserveIsActive(reserve);
      reserveData.isFreezed = core.getReserveIsFreezed(reserve);
      (
        ,
        reserveData.baseLTVasCollateral,
        reserveData.reserveLiquidationThreshold,
        reserveData.usageAsCollateralEnabled
      ) = core.getReserveConfiguration(reserve);
      reserveData.stableBorrowRateEnabled = core.getReserveIsStableBorrowRateEnabled(reserve);
      reserveData.borrowingEnabled = core.isReserveBorrowingEnabled(reserve);
      reserveData.reserveLiquidationBonus = core.getReserveLiquidationBonus(reserve);
      reserveData.priceInEth = oracle.getAssetPrice(reserve);

      // reserve current state
      reserveData.totalLiquidity = core.getReserveTotalLiquidity(reserve);
      reserveData.availableLiquidity = core.getReserveAvailableLiquidity(reserve);
      reserveData.totalBorrowsStable = core.getReserveTotalBorrowsStable(reserve);
      reserveData.totalBorrowsVariable = core.getReserveTotalBorrowsVariable(reserve);
      reserveData.liquidityRate = core.getReserveCurrentLiquidityRate(reserve);
      reserveData.variableBorrowRate = core.getReserveCurrentVariableBorrowRate(reserve);
      reserveData.stableBorrowRate = core.getReserveCurrentStableBorrowRate(reserve);
      reserveData.averageStableBorrowRate = core.getReserveCurrentAverageStableBorrowRate(reserve);
      reserveData.utilizationRate = core.getReserveUtilizationRate(reserve);
      reserveData.liquidityIndex = core.getReserveLiquidityCumulativeIndex(reserve);
      reserveData.variableBorrowIndex = core.getReserveVariableBorrowsCumulativeIndex(reserve);
      reserveData.lastUpdateTimestamp = core.getReserveLastUpdate(reserve);
    }
    return (reservesData, oracle.getAssetPrice(MOCK_USD_ADDRESS));
  }

  function getUserReservesData(ILendingPoolAddressesProvider provider, address user)
    external
    override
    view
    returns (UserReserveData[] memory)
  {
    ILendingPoolCore core = ILendingPoolCore(provider.getLendingPoolCore());

    address[] memory reserves = core.getReserves();
    UserReserveData[] memory userReservesData = new UserReserveData[](reserves.length);

    address reserve;
    for (uint256 i = 0; i < reserves.length; i++) {
      reserve = reserves[i];
      IAToken aToken = IAToken(core.getReserveATokenAddress(reserve));
      UserReserveData memory userReserveData = userReservesData[i];

      userReserveData.underlyingAsset = reserve;
      userReserveData.principalATokenBalance = aToken.principalBalanceOf(user);
      (userReserveData.principalBorrows, , ) = core.getUserBorrowBalances(reserve, user);
      userReserveData.borrowRateMode = core.getUserCurrentBorrowRateMode(reserve, user);
      if (userReserveData.borrowRateMode == CoreLibrary.InterestRateMode.STABLE) {
        userReserveData.borrowRate = core.getUserCurrentStableBorrowRate(reserve, user);
      }
      userReserveData.originationFee = core.getUserOriginationFee(reserve, user);
      userReserveData.variableBorrowIndex = core.getUserVariableBorrowCumulativeIndex(
        reserve,
        user
      );
      userReserveData.userBalanceIndex = aToken.getUserIndex(user);
      userReserveData.redirectedBalance = aToken.getRedirectedBalance(user);
      userReserveData.interestRedirectionAddress = aToken.getInterestRedirectionAddress(user);
      userReserveData.lastUpdateTimestamp = core.getUserLastUpdate(reserve, user);
      userReserveData.usageAsCollateralEnabledOnUser = core.isUserUseReserveAsCollateralEnabled(
        reserve,
        user
      );
    }
    return userReservesData;
  }

  /**
    Gets the total supply of all aTokens for a specific market
    @param provider The LendingPoolAddressProvider contract, different for each market.
   */
  function getAllATokenSupply(ILendingPoolAddressesProvider provider)
    external
    override
    view
    returns (ATokenSupplyData[] memory)
  {
    ILendingPoolCore core = ILendingPoolCore(provider.getLendingPoolCore());
    address[] memory allReserves = core.getReserves();
    address[] memory allATokens = new address[](allReserves.length);

    for (uint256 i = 0; i < allReserves.length; i++) {
      allATokens[i] = core.getReserveATokenAddress(allReserves[i]);
    }
    return getATokenSupply(allATokens);
  }

  /**
    Gets the total supply of associated reserve aTokens
    @param aTokens An array of aTokens addresses
   */
  function getATokenSupply(address[] memory aTokens)
    public
    override
    view
    returns (ATokenSupplyData[] memory)
  {
    ATokenSupplyData[] memory totalSuppliesData = new ATokenSupplyData[](aTokens.length);

    address aTokenAddress;
    for (uint256 i = 0; i < aTokens.length; i++) {
      aTokenAddress = aTokens[i];
      IAToken aToken = IAToken(aTokenAddress);

      totalSuppliesData[i] = ATokenSupplyData({
        name: aToken.name(),
        symbol: aToken.symbol(),
        decimals: aToken.decimals(),
        totalSupply: aToken.totalSupply(),
        aTokenAddress: aTokenAddress
      });
    }
    return totalSuppliesData;
  }
}