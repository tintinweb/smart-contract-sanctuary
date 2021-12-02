// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

interface IAaveOracle {
  function setAssetSources(address[] calldata assets, address[] calldata sources) external;
}

interface IAmmPoolConfigurator {
  struct InitReserveInput {
    address aTokenImpl;
    address stableDebtTokenImpl;
    address variableDebtTokenImpl;
    uint8 underlyingAssetDecimals;
    address interestRateStrategyAddress;
    address underlyingAsset;
    address treasury;
    address incentivesController;
    string underlyingAssetName;
    string aTokenName;
    string aTokenSymbol;
    string variableDebtTokenName;
    string variableDebtTokenSymbol;
    string stableDebtTokenName;
    string stableDebtTokenSymbol;
    bytes params;
  }

  function batchInitReserve(InitReserveInput[] calldata input) external;

  function configureReserveAsCollateral(
    address asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  ) external;

  function setReserveFactor(address asset, uint256 reserveFactor) external;
}

interface IProposalIncentivesExecutor {
  function execute() external;
}

// solhint-disable
contract AssetListingGUni is IProposalIncentivesExecutor {
  address constant POOL_CONFIGURATOR = 0x23A875eDe3F1030138701683e42E9b16A7F87768;
  address constant AAVE_ORACLE = 0xA50ba011c48153De246E5192C8f9258A2ba79Ca9;

  // G-UNI to list
  address constant GUniDAIUSDC_ORACLE = 0x7843eA2E3e60b24cc12B56C5627Adc7F9f0749D6;
  address constant GUniUSDCUSDT_ORACLE = 0x399e3bb2BBd49c570aa6edc6ac390E0D0aCbbD5e;

  address constant GUniDAIUSDC = 0x50379f632ca68D36E50cfBC8F78fe16bd1499d1e;
  address constant GUniUSDCUSDT = 0xD2eeC91055F07fE24C9cCB25828ecfEFd4be0c41;

  // Reserves configuration
  address constant ATOKEN_IMPL = 0x517AD97cD3543eE616cDb3D7765b201D6c9dFFdd;
  address constant STABLE_DEBT_TOKEN_IMPL = 0x135bb9dfd7880a53ef86b6f281AA4C3a9ADdB85c;
  address constant VARIABLE_DEBT_TOKEN_IMPL = 0x104e375E7A62ac88317b93A2288865513c1DC511;
  address constant RATE_STRATEGTY_ADDRESS = 0x52E39422cd86a12a13773D86af5FdBF5665989aD;
  address constant TREASURY_ADDRESS = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;
  address constant INCENTIVES_CONTROLLER_ADDRESS = 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;

  uint256 constant LIQUIDATION_BONUS = 11500;
  uint256 constant RESERVE_FACTOR = 1000;

  struct NamingConvention {
    string aTokenSymbolPrefix;
    string variableSymbolPrefix;
    string stableSymbolPrefix;
    string aTokenNamePrefix;
    string variableNamePrefix;
    string stableNamePrefix;
  }

  struct CollateralConfig {
    uint256 ltv;
    uint256 liquidationThreshold;
  }

  function execute() external override {
    NamingConvention memory namingConvention = NamingConvention(
      'aAmm',
      'variableDebtAmm',
      'stableDebtAmm',
      'Aave AMM Market ',
      'Aave AMM Market Variable Debt ',
      'Aave AMM Market Stable Debt '
    );
    address[2] memory LP_TOKENS_TO_LIST_MARKET = [GUniDAIUSDC, GUniUSDCUSDT];

    address[2] memory TOKENS_TO_LIST_ORACLE = [GUniDAIUSDC, GUniUSDCUSDT];

    address[2] memory TOKEN_ORACLE_SOURCES = [GUniDAIUSDC_ORACLE, GUniUSDCUSDT_ORACLE];

    string[2] memory LP_TOKEN_NAMES = ['GUniDAIUSDC', 'GUniUSDCUSDT'];

    CollateralConfig[2] memory LP_COLLATERAL_CONFIGS = [
      CollateralConfig(6000, 7000),
      CollateralConfig(6000, 7000)
    ];

    IAmmPoolConfigurator.InitReserveInput[]
      memory batchInit = new IAmmPoolConfigurator.InitReserveInput[](2);

    for (uint256 i; i < batchInit.length; i++) {
      batchInit[i] = IAmmPoolConfigurator.InitReserveInput({
        aTokenImpl: ATOKEN_IMPL,
        stableDebtTokenImpl: STABLE_DEBT_TOKEN_IMPL,
        variableDebtTokenImpl: VARIABLE_DEBT_TOKEN_IMPL,
        underlyingAssetDecimals: 18,
        interestRateStrategyAddress: RATE_STRATEGTY_ADDRESS,
        underlyingAsset: LP_TOKENS_TO_LIST_MARKET[i],
        treasury: TREASURY_ADDRESS,
        incentivesController: INCENTIVES_CONTROLLER_ADDRESS,
        underlyingAssetName: LP_TOKEN_NAMES[i],
        aTokenName: concat(namingConvention.aTokenNamePrefix, LP_TOKEN_NAMES[i]),
        aTokenSymbol: concat(namingConvention.aTokenSymbolPrefix, LP_TOKEN_NAMES[i]),
        variableDebtTokenName: concat(namingConvention.variableNamePrefix, LP_TOKEN_NAMES[i]),
        variableDebtTokenSymbol: concat(namingConvention.variableSymbolPrefix, LP_TOKEN_NAMES[i]),
        stableDebtTokenName: concat(namingConvention.stableNamePrefix, LP_TOKEN_NAMES[i]),
        stableDebtTokenSymbol: concat(namingConvention.stableSymbolPrefix, LP_TOKEN_NAMES[i]),
        params: '0x'
      });
    }

    // 1. Setup G-UNI LP tokens with their price sources at the Aave Oracle
    address[] memory tokensToListOracle = new address[](2);
    address[] memory tokenOracleSources = new address[](2);
    for (uint256 o; o < TOKENS_TO_LIST_ORACLE.length; o++) {
      tokensToListOracle[o] = TOKENS_TO_LIST_ORACLE[o];
      tokenOracleSources[o] = TOKEN_ORACLE_SOURCES[o];
    }
    IAaveOracle(AAVE_ORACLE).setAssetSources(tokensToListOracle, tokenOracleSources);

    // 2. Batch init reserve G-UNI LP tokens
    IAmmPoolConfigurator(POOL_CONFIGURATOR).batchInitReserve(batchInit);

    // 3. Set reserve collateral configuration and reserve factor for each G-UNI LP token
    for (uint256 y; y < batchInit.length; y++) {
      IAmmPoolConfigurator(POOL_CONFIGURATOR).configureReserveAsCollateral(
        LP_TOKENS_TO_LIST_MARKET[y],
        LP_COLLATERAL_CONFIGS[y].ltv,
        LP_COLLATERAL_CONFIGS[y].liquidationThreshold,
        LIQUIDATION_BONUS
      );
      IAmmPoolConfigurator(POOL_CONFIGURATOR).setReserveFactor(
        LP_TOKENS_TO_LIST_MARKET[y],
        RESERVE_FACTOR
      );
    }
  }

  function concat(string memory a, string memory b) internal pure returns (string memory) {
    return string(abi.encodePacked(a, b));
  }
}