/**
 *Submitted for verification at polygonscan.com on 2022-01-12
*/

// SPDX-License-Identifier: AGPL-3.0
// are we business license yet
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IProposalGenericExecutor {
  struct ProposalPayload {
    address underlyingAsset;
    address interestRateStrategy;
    address oracle;
    uint256 ltv;
    uint256 lt;
    uint256 lb;
    uint256 rf;
    uint8 decimals;
    bool borrowEnabled;
    bool stableBorrowEnabled;
    string underlyingAssetName;
  }

  function execute() external;
}

interface ILendingPoolConfigurator {
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

  function enableBorrowingOnReserve(address asset, bool stableBorrowRateEnabled) external;

  function setReserveFactor(address asset, uint256 reserveFactor) external;

  function configureReserveAsCollateral(
    address asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  ) external;
}

interface IOracle {
  function setAssetSources(address[] calldata _assets, address[] calldata _sources) external;

  function getSourceOfAsset(address _asset) external view returns (address);

  function getAssetPrice(address _asset) external view returns (uint256);
}

interface ILendingPoolAddressesProvider {
  function getLendingPool() external view returns (address);

  function getLendingPoolConfigurator() external view returns (address);
}

/**
 * @title AssetListingProposalGenericExecutor
 * @notice Proposal payload to be executed by the Aave Governance contract via DELEGATECALL
 * @author Patrick Kim & AAVE
 **/
contract PolygonAssetDeploymentGenericExecutor is IProposalGenericExecutor {
  event ProposalExecuted();

  ILendingPoolAddressesProvider public constant LENDING_POOL_ADDRESSES_PROVIDER =
    ILendingPoolAddressesProvider(0xd05e3E715d945B59290df0ae8eF85c1BdB684744);
  IOracle public constant AAVE_ORACLE = IOracle(0x0229F777B0fAb107F9591a41d5F02E4e98dB6f2d);

  address public constant TREASURY_ADDRESS = 0x7734280A4337F37Fbf4651073Db7c28C80B339e9;
  address public constant INCENTIVES_CONTROLLER_ADDRESS = 0x357D51124f59836DeD84c8a1730D72B749d8BC23;
  address public constant ATOKEN_ADDRESS = 0x3CB4cA3c9DC0e02D252098eEbb3871AC7a43c54d;
  address public constant VAR_IMPL_ADDRESS = 0x1d22AE684F479d3Da97CA19fFB03E6349D345F24;
  address public constant STABLE_IMPL_ADDRESS = 0x72a053fA208eaAFa53ADB1a1EA6b4b2175B5735E;

  string public constant ATOKEN_NAME_PREFIX = "Aave Matic Market ";
  string public constant ATOKEN_SYMBOL_PREFIX = "am";
  string public constant VAR_DEBT_NAME_PREFIX = "Aave Matic Market variable debt ";
  string public constant VAR_DEBT_SYMBOL_PREFIX = "variableDebtm";
  string public constant STABLE_DEBT_NAME_PREFIX = "Aave Matic Market stable debt ";
  string public constant STABLE_DEBT_SYMBOL_PREFIX = "stableDebtm";
  bytes public constant param = "";

  // GHST constants
  address public constant GHST_UNDERLYING_ASSET = 0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7;
  address public constant GHST_INTEREST_RATE_STRATEGY = 0xBb480ae4e2cf28FBE80C9b61ab075f6e7C4dB468;
  address public constant GHST_ORACLE = 0xe638249AF9642CdA55A92245525268482eE4C67b;
  uint256 public constant GHST_LTV = 2500;
  uint256 public constant GHST_LT = 4500;
  uint256 public constant GHST_LB = 11250;
  uint256 public constant GHST_RF = 2000;
  uint8 public constant GHST_DECIMALS = 18;
  bool public constant GHST_BORROW_ENABLED = true;
  bool public constant GHST_STABLE_BORROW_ENABLED = false;
  string public constant GHST_UNDERLYING_ASSET_NAME = "GHST";

  // BAL constants
  address public constant BAL_UNDERLYING_ASSET = 0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3;
  address public constant BAL_INTEREST_RATE_STRATEGY = 0x9025C2d672afA29f43cB59b3035CaCfC401F5D62;
  address public constant BAL_ORACLE = 0x03CD157746c61F44597dD54C6f6702105258C722;
  uint256 public constant BAL_LTV = 2000;
  uint256 public constant BAL_LT = 4500;
  uint256 public constant BAL_LB = 11000;
  uint256 public constant BAL_RF = 2000;
  uint8 public constant BAL_DECIMALS = 18;
  bool public constant BAL_BORROW_ENABLED = true;
  bool public constant BAL_STABLE_BORROW_ENABLED = false;
  string public constant BAL_UNDERLYING_ASSET_NAME = "BAL";

  // DPI constants
  address public constant DPI_UNDERLYING_ASSET = 0x85955046DF4668e1DD369D2DE9f3AEB98DD2A369;
  address public constant DPI_INTEREST_RATE_STRATEGY = 0x6405F880E431403588e92b241Ca15603047ef8a4;
  address public constant DPI_ORACLE = 0xC70aAF9092De3a4E5000956E672cDf5E996B4610;
  uint256 public constant DPI_LTV = 2000;
  uint256 public constant DPI_LT = 4500;
  uint256 public constant DPI_LB = 11000;
  uint256 public constant DPI_RF = 2000;
  uint8 public constant DPI_DECIMALS = 18;
  bool public constant DPI_BORROW_ENABLED = false;
  bool public constant DPI_STABLE_BORROW_ENABLED = false;
  string public constant DPI_UNDERLYING_ASSET_NAME = "DPI";

  // CRV constants
  address public constant CRV_UNDERLYING_ASSET = 0x172370d5Cd63279eFa6d502DAB29171933a610AF;
  address public constant CRV_INTEREST_RATE_STRATEGY = 0xBD67eB7e00f43DAe9e3d51f7d509d4730Fe5988e;
  address public constant CRV_ORACLE = 0x1CF68C76803c9A415bE301f50E82e44c64B7F1D4;
  uint256 public constant CRV_LTV = 2000;
  uint256 public constant CRV_LT = 4500;
  uint256 public constant CRV_LB = 11000;
  uint256 public constant CRV_RF = 2000;
  uint8 public constant CRV_DECIMALS = 18;
  bool public constant CRV_BORROW_ENABLED = true;
  bool public constant CRV_STABLE_BORROW_ENABLED = false;
  string public constant CRV_UNDERLYING_ASSET_NAME = "CRV";

  // SUSHI constants
  address public constant SUSHI_UNDERLYING_ASSET = 0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a;
  address public constant SUSHI_INTEREST_RATE_STRATEGY = 0x835699Bf98f6a7fDe5713c42c118Fb80fA059737;
  address public constant SUSHI_ORACLE = 0x17414Eb5159A082e8d41D243C1601c2944401431;
  uint256 public constant SUSHI_LTV = 2000;
  uint256 public constant SUSHI_LT = 4500;
  uint256 public constant SUSHI_LB = 11000;
  uint256 public constant SUSHI_RF = 3500;
  uint8 public constant SUSHI_DECIMALS = 18;
  bool public constant SUSHI_BORROW_ENABLED = false;
  bool public constant SUSHI_STABLE_BORROW_ENABLED = false;
  string public constant SUSHI_UNDERLYING_ASSET_NAME = "SUSHI";

  // LINK constants
  address public constant LINK_UNDERLYING_ASSET = 0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39;
  address public constant LINK_INTEREST_RATE_STRATEGY = 0x5641Bb58f4a92188A6F16eE79C8886Cf42C561d3;
  address public constant LINK_ORACLE = 0xb77fa460604b9C6435A235D057F7D319AC83cb53;
  uint256 public constant LINK_LTV = 5000;
  uint256 public constant LINK_LT = 6500;
  uint256 public constant LINK_LB = 10750;
  uint256 public constant LINK_RF = 1000;
  uint8 public constant LINK_DECIMALS = 18;
  bool public constant LINK_BORROW_ENABLED = true;
  bool public constant LINK_STABLE_BORROW_ENABLED = false;
  string public constant LINK_UNDERLYING_ASSET_NAME = "LINK";

  // MATIC constants
  address public constant MATIC_UNDERLYING_ASSET = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
  uint256 public constant MATIC_LTV = 6500;
  uint256 public constant MATIC_LT = 7000;
  uint256 public constant MATIC_LB = 11000;

  /**
   * @dev Payload execution function, called once a proposal passed in the Aave governance
   */
  function execute() external override {
    IProposalGenericExecutor.ProposalPayload[6] memory proposalPayloads;
    proposalPayloads[0] = ProposalPayload({
      underlyingAsset: GHST_UNDERLYING_ASSET,
      interestRateStrategy: GHST_INTEREST_RATE_STRATEGY,
      oracle: GHST_ORACLE,
      ltv: GHST_LTV,
      lt: GHST_LT,
      lb: GHST_LB,
      rf: GHST_RF,
      decimals: GHST_DECIMALS,
      borrowEnabled: GHST_BORROW_ENABLED,
      stableBorrowEnabled: GHST_STABLE_BORROW_ENABLED,
      underlyingAssetName: GHST_UNDERLYING_ASSET_NAME
    });
    proposalPayloads[1] = ProposalPayload({
      underlyingAsset: BAL_UNDERLYING_ASSET,
      interestRateStrategy: BAL_INTEREST_RATE_STRATEGY,
      oracle: BAL_ORACLE,
      ltv: BAL_LTV,
      lt: BAL_LT,
      lb: BAL_LB,
      rf: BAL_RF,
      decimals: BAL_DECIMALS,
      borrowEnabled: BAL_BORROW_ENABLED,
      stableBorrowEnabled: BAL_STABLE_BORROW_ENABLED,
      underlyingAssetName: BAL_UNDERLYING_ASSET_NAME
    });
    proposalPayloads[2] = ProposalPayload({
      underlyingAsset: DPI_UNDERLYING_ASSET,
      interestRateStrategy: DPI_INTEREST_RATE_STRATEGY,
      oracle: DPI_ORACLE,
      ltv: DPI_LTV,
      lt: DPI_LT,
      lb: DPI_LB,
      rf: DPI_RF,
      decimals: DPI_DECIMALS,
      borrowEnabled: DPI_BORROW_ENABLED,
      stableBorrowEnabled: DPI_STABLE_BORROW_ENABLED,
      underlyingAssetName: DPI_UNDERLYING_ASSET_NAME
    });
    proposalPayloads[3] = ProposalPayload({
      underlyingAsset: CRV_UNDERLYING_ASSET,
      interestRateStrategy: CRV_INTEREST_RATE_STRATEGY,
      oracle: CRV_ORACLE,
      ltv: CRV_LTV,
      lt: CRV_LT,
      lb: CRV_LB,
      rf: CRV_RF,
      decimals: CRV_DECIMALS,
      borrowEnabled: CRV_BORROW_ENABLED,
      stableBorrowEnabled: CRV_STABLE_BORROW_ENABLED,
      underlyingAssetName: CRV_UNDERLYING_ASSET_NAME
    });
    proposalPayloads[4] = ProposalPayload({
      underlyingAsset: SUSHI_UNDERLYING_ASSET,
      interestRateStrategy: SUSHI_INTEREST_RATE_STRATEGY,
      oracle: SUSHI_ORACLE,
      ltv: SUSHI_LTV,
      lt: SUSHI_LT,
      lb: SUSHI_LB,
      rf: SUSHI_RF,
      decimals: SUSHI_DECIMALS,
      borrowEnabled: SUSHI_BORROW_ENABLED,
      stableBorrowEnabled: SUSHI_STABLE_BORROW_ENABLED,
      underlyingAssetName: SUSHI_UNDERLYING_ASSET_NAME
    });
    proposalPayloads[5] = ProposalPayload({
      underlyingAsset: LINK_UNDERLYING_ASSET,
      interestRateStrategy: LINK_INTEREST_RATE_STRATEGY,
      oracle: LINK_ORACLE,
      ltv: LINK_LTV,
      lt: LINK_LT,
      lb: LINK_LB,
      rf: LINK_RF,
      decimals: LINK_DECIMALS,
      borrowEnabled: LINK_BORROW_ENABLED,
      stableBorrowEnabled: LINK_STABLE_BORROW_ENABLED,
      underlyingAssetName: LINK_UNDERLYING_ASSET_NAME
    });

    ILendingPoolConfigurator LENDING_POOL_CONFIGURATOR = ILendingPoolConfigurator(
      LENDING_POOL_ADDRESSES_PROVIDER.getLendingPoolConfigurator()
    );

    ILendingPoolConfigurator.InitReserveInput[]
      memory initReserveInput = new ILendingPoolConfigurator.InitReserveInput[](6);
    address[] memory assets = new address[](6);
    address[] memory sources = new address[](6);

    //Fill up the init reserve input
    for (uint256 i = 0; i < 6; i++) {
      ProposalPayload memory payload = proposalPayloads[i];
      assets[i] = payload.underlyingAsset;
      sources[i] = payload.oracle;
      initReserveInput[i] = ILendingPoolConfigurator.InitReserveInput(
        ATOKEN_ADDRESS,
        STABLE_IMPL_ADDRESS,
        VAR_IMPL_ADDRESS,
        payload.decimals,
        payload.interestRateStrategy,
        payload.underlyingAsset,
        TREASURY_ADDRESS,
        INCENTIVES_CONTROLLER_ADDRESS,
        payload.underlyingAssetName,
        string(abi.encodePacked(ATOKEN_NAME_PREFIX, payload.underlyingAssetName)),
        string(abi.encodePacked(ATOKEN_SYMBOL_PREFIX, payload.underlyingAssetName)),
        string(abi.encodePacked(VAR_DEBT_NAME_PREFIX, payload.underlyingAssetName)),
        string(abi.encodePacked(VAR_DEBT_SYMBOL_PREFIX, payload.underlyingAssetName)),
        string(abi.encodePacked(STABLE_DEBT_NAME_PREFIX, payload.underlyingAssetName)),
        string(abi.encodePacked(STABLE_DEBT_SYMBOL_PREFIX, payload.underlyingAssetName)),
        param
      );
    }

    //initiate the reserves and add oracles
    LENDING_POOL_CONFIGURATOR.batchInitReserve(initReserveInput);
    AAVE_ORACLE.setAssetSources(assets, sources);

    //now initialize the rest of the parameters
    for (uint256 i = 0; i < 6; i++) {
      ProposalPayload memory payload = proposalPayloads[i];
      LENDING_POOL_CONFIGURATOR.configureReserveAsCollateral(
        payload.underlyingAsset,
        payload.ltv,
        payload.lt,
        payload.lb
      );
      if (payload.borrowEnabled) {
        LENDING_POOL_CONFIGURATOR.enableBorrowingOnReserve(
          payload.underlyingAsset,
          payload.stableBorrowEnabled
        );
      }
      LENDING_POOL_CONFIGURATOR.setReserveFactor(payload.underlyingAsset, payload.rf);
    }

    LENDING_POOL_CONFIGURATOR.configureReserveAsCollateral(
      MATIC_UNDERLYING_ASSET,
      MATIC_LTV,
      MATIC_LT,
      MATIC_LB
    );
    emit ProposalExecuted();
  }
}