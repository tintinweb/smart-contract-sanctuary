/**
 *Submitted for verification at polygonscan.com on 2022-01-05
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
  function configureReserveAsCollateral(address asset, uint256 ltv, uint256 liquidationThreshold, uint256 liquidationBonus) external;
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
  address public constant TREASURY_ADDRESS = 0x7734280A4337F37Fbf4651073Db7c28C80B339e9;
  address public constant INCENTIVES_CONTROLLER_ADDRESS = 0x357D51124f59836DeD84c8a1730D72B749d8BC23;
  address public constant ATOKEN_ADDRESS = 0x3CB4cA3c9DC0e02D252098eEbb3871AC7a43c54d;
  address public constant VAR_IMPL_ADDRESS = 0x1d22AE684F479d3Da97CA19fFB03E6349D345F24;
  address public constant STABLE_IMPL_ADDRESS = 0x72a053fA208eaAFa53ADB1a1EA6b4b2175B5735E;
  ILendingPoolAddressesProvider public constant LENDING_POOL_ADDRESSES_PROVIDER = 
    ILendingPoolAddressesProvider(0xd05e3E715d945B59290df0ae8eF85c1BdB684744);
  IOracle public constant AAVE_ORACLE = 
    IOracle(0x0229F777B0fAb107F9591a41d5F02E4e98dB6f2d);
  string public constant ATOKEN_NAME_PREFIX = "Aave Matic Market ";
  string public constant ATOKEN_SYMBOL_PREFIX = "am";
  string public constant VAR_DEBT_NAME_PREFIX = "Aave Matic Market variable debt ";
  string public constant VAR_DEBT_SYMBOL_PREFIX = "variableDebtm";
  string public constant STABLE_DEBT_NAME_PREFIX = "Aave Matic Market stable debt ";
  string public constant STABLE_DEBT_SYMBOL_PREFIX = "stableDebtm";

  uint8 public constant decimals = 18;
  bytes public constant param = abi.encodePacked('0x10');
  
  /**
   * @dev Payload execution function, called once a proposal passed in the Aave governance
   */
  function execute() external override {
    IProposalGenericExecutor.ProposalPayload[6] memory proposalPayloads;
    proposalPayloads[0] = ProposalPayload(
      {
        underlyingAsset: 0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7,
        interestRateStrategy: 0xBb480ae4e2cf28FBE80C9b61ab075f6e7C4dB468,
        oracle: 0xe638249AF9642CdA55A92245525268482eE4C67b,
        ltv: 2500,
        lt: 4500,
        lb: 11250,
        rf: 2000,
        decimals: 18,
        borrowEnabled: true,
        stableBorrowEnabled: false,
        underlyingAssetName: 'GHST'
      }
    );
    proposalPayloads[1] = ProposalPayload(
      {
        underlyingAsset: 0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3,
        interestRateStrategy: 0x9025C2d672afA29f43cB59b3035CaCfC401F5D62,
        oracle: 0x03CD157746c61F44597dD54C6f6702105258C722,
        ltv: 2000,
        lt: 4500,
        lb: 11000,
        rf: 2000,
        decimals: 18,
        borrowEnabled: true,
        stableBorrowEnabled: false,
        underlyingAssetName: 'BAL'
      }
    );
    proposalPayloads[2] = ProposalPayload(
      {
        underlyingAsset: 0x85955046DF4668e1DD369D2DE9f3AEB98DD2A369,
        interestRateStrategy: 0x6405F880E431403588e92b241Ca15603047ef8a4,
        oracle: 0xC70aAF9092De3a4E5000956E672cDf5E996B4610,
        ltv: 2000,
        lt: 4500,
        lb: 11000,
        rf: 2000,
        decimals: 18,
        borrowEnabled: false,
        stableBorrowEnabled: false,
        underlyingAssetName: 'DPI'
      }
    );
    proposalPayloads[3] = ProposalPayload(
      {
        underlyingAsset: 0x172370d5Cd63279eFa6d502DAB29171933a610AF,
        interestRateStrategy: 0xBD67eB7e00f43DAe9e3d51f7d509d4730Fe5988e,
        oracle: 0x1CF68C76803c9A415bE301f50E82e44c64B7F1D4,
        ltv: 2000,
        lt: 4500,
        lb: 11000,
        rf: 2000,
        decimals: 18,
        borrowEnabled: true,
        stableBorrowEnabled: false,
        underlyingAssetName: 'CRV'
      }
    );
    proposalPayloads[4] = ProposalPayload(
      {
        underlyingAsset: 0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a,
        interestRateStrategy: 0x835699Bf98f6a7fDe5713c42c118Fb80fA059737,
        oracle: 0x17414Eb5159A082e8d41D243C1601c2944401431,
        ltv: 2000,
        lt: 4500,
        lb: 11000,
        rf: 3500,
        decimals: 18,
        borrowEnabled: false,
        stableBorrowEnabled: false,
        underlyingAssetName: 'SUSHI'
      }
    );
    proposalPayloads[5] = ProposalPayload(
      {
        underlyingAsset: 0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39,
        interestRateStrategy: 0x5641Bb58f4a92188A6F16eE79C8886Cf42C561d3,
        oracle: 0xb77fa460604b9C6435A235D057F7D319AC83cb53,
        ltv: 6500,
        lt: 7000,
        lb: 11000,
        rf: 1000,
        decimals: 18,
        borrowEnabled: true,
        stableBorrowEnabled: false,
        underlyingAssetName: 'LINK'
      }
    );

    ILendingPoolConfigurator LENDING_POOL_CONFIGURATOR =
      ILendingPoolConfigurator(LENDING_POOL_ADDRESSES_PROVIDER.getLendingPoolConfigurator());

    ILendingPoolConfigurator.InitReserveInput[] memory initReserveInput =
      new ILendingPoolConfigurator.InitReserveInput[](6);
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
      if(payload.borrowEnabled) {
        LENDING_POOL_CONFIGURATOR.enableBorrowingOnReserve(
          payload.underlyingAsset,
          payload.stableBorrowEnabled);
      }
      LENDING_POOL_CONFIGURATOR.setReserveFactor(
        payload.underlyingAsset,
        payload.rf
      );
    }
    //MATIC Parameters update
    LENDING_POOL_CONFIGURATOR.configureReserveAsCollateral(
      0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270,
      6500,
      7000,
      11000
    );
    emit ProposalExecuted();
  }
}