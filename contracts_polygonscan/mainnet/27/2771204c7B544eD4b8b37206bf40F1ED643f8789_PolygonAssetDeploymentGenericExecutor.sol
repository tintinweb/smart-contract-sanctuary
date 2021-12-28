/**
 *Submitted for verification at polygonscan.com on 2021-12-27
*/

// SPDX-License-Identifier: AGPL-3.0
// are we business license yet
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IOwnable {
    function transferOwnership(address newOwner) external;
    function owner() external view returns (address);
}

interface IAaveOracle is IOwnable {
    function setAssetSources(address[] calldata _assets, address[] calldata _sources) external;
    function getSourceOfAsset(address _asset) external view returns (address);
    function getAssetPrice(address _asset) external view returns (uint256);
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

interface IProposalDataProvider {
  function getPayload(uint256 id) external view returns (IProposalGenericExecutor.ProposalPayload memory);
}

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
  IAaveOracle public constant AAVE_ORACLE = 
    IAaveOracle(0x0229F777B0fAb107F9591a41d5F02E4e98dB6f2d);
  IProposalDataProvider public constant PROPOSAL_DATA_PROVIDER = 
    IProposalDataProvider(0x3EC1580919A1e7980ac171A079E3F1826A26fA63);
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
    ILendingPoolConfigurator LENDING_POOL_CONFIGURATOR =
      ILendingPoolConfigurator(LENDING_POOL_ADDRESSES_PROVIDER.getLendingPoolConfigurator());

    ILendingPoolConfigurator.InitReserveInput[] memory initReserveInput =
      new ILendingPoolConfigurator.InitReserveInput[](6);
    address[] memory assets = new address[](6);
    address[] memory sources = new address[](6);

    //Fill up the init reserve input
    for (uint256 i = 0; i < 6; i++) {
      ProposalPayload memory payload = PROPOSAL_DATA_PROVIDER.getPayload(i);
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
      ProposalPayload memory payload = PROPOSAL_DATA_PROVIDER.getPayload(i);
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