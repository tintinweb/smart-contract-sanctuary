// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

/**
 * @title IACLManager
 * @author Aave
 * @notice Defines the basic interface for the ACL Manager
 **/
interface IACLManager {
  function POOL_ADMIN_ROLE() external view returns (bytes32);

  function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

  function RISK_ADMIN_ROLE() external view returns (bytes32);

  function FLASH_BORROWER_ROLE() external view returns (bytes32);

  function BRIDGE_ROLE() external view returns (bytes32);

  function ASSET_LISTING_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Set the role as admin of a specific role.
   * @dev By default the admin role for all roles is `DEFAULT_ADMIN_ROLE`.
   * @param role The role to be managed by the admin role
   * @param adminRole The admin role
   */
  function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

  /**
   * @notice Adds a new admin as PoolAdmin
   * @param admin The address of the new admin
   */
  function addPoolAdmin(address admin) external;

  /**
   * @notice Removes an admin as PoolAdmin
   * @param admin The address of the admin to remove
   */
  function removePoolAdmin(address admin) external;

  /**
   * @notice Returns true if the address is PoolAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is PoolAdmin, false otherwise
   */
  function isPoolAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new admin as EmergencyAdmin
   * @param admin The address of the new admin
   */
  function addEmergencyAdmin(address admin) external;

  /**
   * @notice Removes an admin as EmergencyAdmin
   * @param admin The address of the admin to remove
   */
  function removeEmergencyAdmin(address admin) external;

  /**
   * @notice Returns true if the address is EmergencyAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is EmergencyAdmin, false otherwise
   */
  function isEmergencyAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new admin as RiskAdmin
   * @param admin The address of the new admin
   */
  function addRiskAdmin(address admin) external;

  /**
   * @notice Removes an admin as RiskAdmin
   * @param admin The address of the admin to remove
   */
  function removeRiskAdmin(address admin) external;

  /**
   * @notice Returns true if the address is RiskAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is RiskAdmin, false otherwise
   */
  function isRiskAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new address as FlashBorrower
   * @param borrower The address of the new FlashBorrower
   */
  function addFlashBorrower(address borrower) external;

  /**
   * @notice Removes an admin as FlashBorrower
   * @param borrower The address of the FlashBorrower to remove
   */
  function removeFlashBorrower(address borrower) external;

  /**
   * @notice Returns true if the address is FlashBorrower, false otherwise
   * @param borrower The address to check
   * @return True if the given address is FlashBorrower, false otherwise
   */
  function isFlashBorrower(address borrower) external view returns (bool);

  /**
   * @notice Adds a new address as Bridge
   * @param bridge The address of the new Bridge
   */
  function addBridge(address bridge) external;

  /**
   * @notice Removes an address as Bridge
   * @param bridge The address of the bridge to remove
   */
  function removeBridge(address bridge) external;

  /**
   * @notice Returns true if the address is Bridge, false otherwise
   * @param bridge The address to check
   * @return True if the given address is Bridge, false otherwise
   */
  function isBridge(address bridge) external view returns (bool);

  /**
   * @notice Adds a new admin as AssetListingAdmin
   * @param admin The address of the new admin
   */
  function addAssetListingAdmin(address admin) external;

  /**
   * @notice Removes an admin as AssetListingAdmin
   * @param admin The address of the admin to remove
   */
  function removeAssetListingAdmin(address admin) external;

  /**
   * @notice Returns true if the address is AssetListingAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is AssetListingAdmin, false otherwise
   */
  function isAssetListingAdmin(address admin) external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

interface IChainlinkAggregator {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 **/
interface IPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event PoolUpdated(address indexed newAddress);
  event PoolConfiguratorUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event ACLManagerUpdated(address indexed newAddress);
  event ACLAdminUpdated(address indexed newAddress);
  event PriceOracleSentinelUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event BridgeAccessControlUpdated(address indexed newAddress);
  event PoolDataProviderUpdated(address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  /**
   * @notice Returns the id of the Aave market to which this contract points to
   * @return The market id
   **/
  function getMarketId() external view returns (string memory);

  /**
   * @notice Allows to set the market which this PoolAddressesProvider represents
   * @param marketId The market id
   */
  function setMarketId(string calldata marketId) external;

  /**
   * @notice Sets an address for an id replacing the address saved in the addresses map
   * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @notice General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `impl`
   * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * @param id The id
   * @param impl The address of the new implementation
   */
  function setAddressAsProxy(bytes32 id, address impl) external;

  /**
   * @notice Returns an address by id
   * @return The address
   */
  function getAddress(bytes32 id) external view returns (address);

  /**
   * @notice Returns the address of the Pool proxy
   * @return The Pool proxy address
   **/
  function getPool() external view returns (address);

  /**
   * @notice Updates the implementation of the Pool, or creates the proxy
   * setting the new `pool` implementation on the first time calling it
   * @param pool The new Pool implementation
   **/
  function setPoolImpl(address pool) external;

  /**
   * @notice Returns the address of the PoolConfigurator proxy
   * @return The PoolConfigurator proxy address
   **/
  function getPoolConfigurator() external view returns (address);

  /**
   * @notice Updates the implementation of the PoolConfigurator, or creates the proxy
   * setting the new `configurator` implementation on the first time calling it
   * @param configurator The new PoolConfigurator implementation
   **/
  function setPoolConfiguratorImpl(address configurator) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  /**
   * @notice Returns the address of the ACL manager proxy
   * @return The ACLManager proxy address
   */
  function getACLManager() external view returns (address);

  /**
   * @notice Updates the address of the ACLManager
   * @param aclManager The address of the new ACLManager
   **/
  function setACLManager(address aclManager) external;

  /**
   * @notice Returns the address of the ACL admin
   * @return The address of the ACL admin
   */
  function getACLAdmin() external view returns (address);

  /**
   * @notice Updates the address of the ACL admin
   * @param aclAdmin The address of the new ACL admin
   */
  function setACLAdmin(address aclAdmin) external;

  /**
   * @notice Returns the address of the PriceOracleSentinel
   * @return The PriceOracleSentinel address
   */
  function getPriceOracleSentinel() external view returns (address);

  /**
   * @notice Updates the address of the PriceOracleSentinel
   * @param oracleSentinel The address of the new PriceOracleSentinel
   **/
  function setPriceOracleSentinel(address oracleSentinel) external;

  /**
   * @notice Updates the address of the DataProvider
   * @param dataProvider The address of the new DataProvider
   **/
  function setPoolDataProvider(address dataProvider) external;

  /**
   * @notice Returns the address of the DataProvider
   * @return The DataProvider address
   */
  function getPoolDataProvider() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

/**
 * @title IPriceOracleGetter
 * @author Aave
 * @notice Interface for the Aave price oracle.
 **/
interface IPriceOracleGetter {
  /**
   * @notice Returns the base currency address
   * @return Returns the base currency address. MOCK_USD_ADDRESS if usd market
   **/
  function BASE_CURRENCY() external view returns (address);

  /**
   * @notice Returns the base currency unit
   * @return Returns the base currency unit. 1 ether if eth market and 100000000 if usd market
   **/
  function BASE_CURRENCY_UNIT() external view returns (uint256);

  /**
   * @notice Returns the asset price in the base currency
   * @param asset The address of the asset
   * @return The price of the asset
   **/
  function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import {IACLManager} from '../interfaces/IACLManager.sol';
import {IPoolAddressesProvider} from '../interfaces/IPoolAddressesProvider.sol';
import {IPriceOracleGetter} from '../interfaces/IPriceOracleGetter.sol';
import {IChainlinkAggregator} from '../interfaces/IChainlinkAggregator.sol';
import {Errors} from '../protocol/libraries/helpers/Errors.sol';

/**
 * @title AaveOracle
 * @author Aave
 * @notice Contract to get asset prices, manage price sources and update the fallback oracle
 * - Use of Chainlink Aggregators as first source of price
 * - If the returned price by a Chainlink aggregator is <= 0, the call is forwarded to a fallback oracle
 * - Owned by the Aave governance
 */
contract AaveOracle is IPriceOracleGetter {
  /**
   * @notice Emitted after the base currency is set
   * @param baseCurrency The base currency of used for price quotes
   * @param baseCurrencyUnit The unit of the base currency
   */
  event BaseCurrencySet(address indexed baseCurrency, uint256 baseCurrencyUnit);

  /**
   * @notice Emitted after the price source of an asset is updated
   * @param asset The address of the asset
   * @param source The price source of the asset
   */
  event AssetSourceUpdated(address indexed asset, address indexed source);

  /**
   * @notice Emitted after the address of fallback oracle is updated
   * @param fallbackOracle The address of the fallback oracle
   */
  event FallbackOracleUpdated(address indexed fallbackOracle);

  IPoolAddressesProvider internal _addressesProvider;
  mapping(address => IChainlinkAggregator) private assetsSources;
  IPriceOracleGetter private _fallbackOracle;
  address public immutable override BASE_CURRENCY;
  uint256 public immutable override BASE_CURRENCY_UNIT;

  modifier onlyAssetListingOrPoolAdmins() {
    _onlyAssetListingOrPoolAdmins();
    _;
  }

  /**
   * @notice Constructor
   * @param provider The address of the new PoolAddressesProvider
   * @param assets The addresses of the assets
   * @param sources The address of the source of each asset
   * @param fallbackOracle The address of the fallback oracle to use if the data of an
   *        aggregator is not consistent
   * @param baseCurrency The base currency used for the price quotes. If USD is used, base currency is 0x0
   * @param baseCurrencyUnit The unit of the base currency
   */
  constructor(
    IPoolAddressesProvider provider,
    address[] memory assets,
    address[] memory sources,
    address fallbackOracle,
    address baseCurrency,
    uint256 baseCurrencyUnit
  ) {
    _addressesProvider = provider;
    _setFallbackOracle(fallbackOracle);
    _setAssetsSources(assets, sources);
    BASE_CURRENCY = baseCurrency;
    BASE_CURRENCY_UNIT = baseCurrencyUnit;
    emit BaseCurrencySet(baseCurrency, baseCurrencyUnit);
  }

  /**
   * @notice External function called by the Aave governance to set or replace sources of assets
   * @param assets The addresses of the assets
   * @param sources The address of the source of each asset
   */
  function setAssetSources(address[] calldata assets, address[] calldata sources)
    external
    onlyAssetListingOrPoolAdmins
  {
    _setAssetsSources(assets, sources);
  }

  /**
   * @notice Sets the fallback oracle
   * - Callable only by the Aave governance
   * @param fallbackOracle The address of the fallback oracle
   */
  function setFallbackOracle(address fallbackOracle) external onlyAssetListingOrPoolAdmins {
    _setFallbackOracle(fallbackOracle);
  }

  /**
   * @notice Internal function to set the sources for each asset
   * @param assets The addresses of the assets
   * @param sources The address of the source of each asset
   */
  function _setAssetsSources(address[] memory assets, address[] memory sources) internal {
    require(assets.length == sources.length, 'INCONSISTENT_PARAMS_LENGTH');
    for (uint256 i = 0; i < assets.length; i++) {
      assetsSources[assets[i]] = IChainlinkAggregator(sources[i]);
      emit AssetSourceUpdated(assets[i], sources[i]);
    }
  }

  /**
   * @notice Internal function to set the fallback oracle
   * @param fallbackOracle The address of the fallback oracle
   */
  function _setFallbackOracle(address fallbackOracle) internal {
    _fallbackOracle = IPriceOracleGetter(fallbackOracle);
    emit FallbackOracleUpdated(fallbackOracle);
  }

  /// @inheritdoc IPriceOracleGetter
  function getAssetPrice(address asset) public view override returns (uint256) {
    IChainlinkAggregator source = assetsSources[asset];

    if (asset == BASE_CURRENCY) {
      return BASE_CURRENCY_UNIT;
    } else if (address(source) == address(0)) {
      return _fallbackOracle.getAssetPrice(asset);
    } else {
      int256 price = IChainlinkAggregator(source).latestAnswer();
      if (price > 0) {
        return uint256(price);
      } else {
        return _fallbackOracle.getAssetPrice(asset);
      }
    }
  }

  /**
   * @notice Returns a list of prices from a list of assets addresses
   * @param assets The list of assets addresses
   * @return The prices of te given assets
   */
  function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory) {
    uint256[] memory prices = new uint256[](assets.length);
    for (uint256 i = 0; i < assets.length; i++) {
      prices[i] = getAssetPrice(assets[i]);
    }
    return prices;
  }

  /**
   * @notice Returns the address of the source for an asset address
   * @param asset The address of the asset
   * @return The address of the source
   */
  function getSourceOfAsset(address asset) external view returns (address) {
    return address(assetsSources[asset]);
  }

  /**
   * @notice Returns the address of the fallback oracle
   * @return The address of the fallback oracle
   */
  function getFallbackOracle() external view returns (address) {
    return address(_fallbackOracle);
  }

  function _onlyAssetListingOrPoolAdmins() internal view {
    IACLManager aclManager = IACLManager(_addressesProvider.getACLManager());
    require(
      aclManager.isAssetListingAdmin(msg.sender) || aclManager.isPoolAdmin(msg.sender),
      Errors.PC_CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN
    );
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

/**
 * @title Errors library
 * @author Aave
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - MATH = Math libraries
 *  - CT = Common errors between tokens (AToken, VariableDebtToken and StableDebtToken)
 *  - AT = AToken
 *  - SDT = StableDebtToken
 *  - VDT = VariableDebtToken
 *  - P = Pool
 *  - PAPR = PoolAddressesProviderRegistry
 *  - PC = PoolConfiguration
 *  - RL = ReserveLogic
 *  - P = Pausable
 */
library Errors {
  //common errors
  string public constant CALLER_NOT_POOL_ADMIN = '33'; // 'The caller must be the pool admin'

  //contract specific errors
  string public constant VL_INVALID_AMOUNT = '1'; // 'Amount must be greater than 0'
  string public constant VL_NO_ACTIVE_RESERVE = '2'; // 'Action requires an active reserve'
  string public constant VL_RESERVE_FROZEN = '3'; // 'Action cannot be performed because the reserve is frozen'
  string public constant VL_CURRENT_AVAILABLE_LIQUIDITY_NOT_ENOUGH = '4'; // 'The current liquidity is not enough'
  string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = '5'; // 'User cannot withdraw more than the available balance'
  string public constant VL_BORROWING_NOT_ENABLED = '7'; // 'Borrowing is not enabled'
  string public constant VL_INVALID_INTEREST_RATE_MODE_SELECTED = '8'; // 'Invalid interest rate mode selected'
  string public constant VL_COLLATERAL_BALANCE_IS_0 = '9'; // 'The collateral balance is 0'
  string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = '10'; // 'Health factor is lesser than the liquidation threshold'
  string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = '11'; // 'There is not enough collateral to cover a new borrow'
  string public constant VL_STABLE_BORROWING_NOT_ENABLED = '12'; // stable borrowing not enabled
  string public constant VL_COLLATERAL_SAME_AS_BORROWING_CURRENCY = '13'; // collateral is (mostly) the same currency that is being borrowed
  string public constant VL_AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = '14'; // 'The requested amount is greater than the max loan size in stable rate mode
  string public constant VL_NO_DEBT_OF_SELECTED_TYPE = '15'; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
  string public constant VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = '16'; // 'To repay on behalf of a user an explicit amount to repay is needed'
  string public constant VL_NO_STABLE_RATE_LOAN_IN_RESERVE = '17'; // 'User does not have a stable rate loan in progress on this reserve'
  string public constant VL_NO_VARIABLE_RATE_LOAN_IN_RESERVE = '18'; // 'User does not have a variable rate loan in progress on this reserve'
  string public constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = '19'; // 'The underlying balance needs to be greater than 0'
  string public constant VL_SUPPLIED_ASSETS_ALREADY_IN_USE = '20'; // 'User supplied assets are already being used as collateral'
  string public constant P_NOT_ENOUGH_STABLE_BORROW_BALANCE = '21'; // 'User does not have any stable rate loan for this reserve'
  string public constant P_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '22'; // 'Interest rate rebalance conditions were not met'
  string public constant P_LIQUIDATION_CALL_FAILED = '23'; // 'Liquidation call failed'
  string public constant P_NOT_ENOUGH_LIQUIDITY_TO_BORROW = '24'; // 'There is not enough liquidity available to borrow'
  string public constant P_REQUESTED_AMOUNT_TOO_SMALL = '25'; // 'The requested amount is too small for a FlashLoan.'
  string public constant P_INCONSISTENT_PROTOCOL_ACTUAL_BALANCE = '26'; // 'The actual balance of the protocol is inconsistent'
  string public constant P_CALLER_NOT_POOL_CONFIGURATOR = '27'; // 'The caller of the function is not the pool configurator'
  string public constant P_INCONSISTENT_FLASHLOAN_PARAMS = '28';
  string public constant CT_CALLER_MUST_BE_POOL = '29'; // 'The caller of this function must be a pool'
  string public constant CT_CANNOT_GIVE_ALLOWANCE_TO_HIMSELF = '30'; // 'User cannot give allowance to himself'
  string public constant CT_TRANSFER_AMOUNT_NOT_GT_0 = '31'; // 'Transferred amount needs to be greater than zero'
  string public constant RL_RESERVE_ALREADY_INITIALIZED = '32'; // 'Reserve has already been initialized'
  string public constant PC_RESERVE_LIQUIDITY_NOT_0 = '34'; // 'The liquidity of the reserve needs to be 0'
  string public constant PC_INVALID_ATOKEN_POOL_ADDRESS = '35'; // 'The liquidity of the reserve needs to be 0'
  string public constant PC_INVALID_STABLE_DEBT_TOKEN_POOL_ADDRESS = '36'; // 'The liquidity of the reserve needs to be 0'
  string public constant PC_INVALID_VARIABLE_DEBT_TOKEN_POOL_ADDRESS = '37'; // 'The liquidity of the reserve needs to be 0'
  string public constant PC_INVALID_STABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = '38'; // 'The liquidity of the reserve needs to be 0'
  string public constant PC_INVALID_VARIABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = '39'; // 'The liquidity of the reserve needs to be 0'
  string public constant PC_INVALID_ADDRESSES_PROVIDER_ID = '40'; // 'The liquidity of the reserve needs to be 0'
  string public constant PC_INVALID_CONFIGURATION = '75'; // 'Invalid risk parameters for the reserve'
  string public constant PC_CALLER_NOT_EMERGENCY_ADMIN = '76'; // 'The caller must be the emergency admin'
  string public constant PAPR_PROVIDER_NOT_REGISTERED = '41'; // 'Provider is not registered'
  string public constant VL_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '42'; // 'Health factor is not below the threshold'
  string public constant VL_COLLATERAL_CANNOT_BE_LIQUIDATED = '43'; // 'The collateral chosen cannot be liquidated'
  string public constant VL_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = '44'; // 'User did not borrow the specified currency'
  string public constant VL_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE = '45'; // "There isn't enough liquidity available to liquidate"
  string public constant P_INVALID_FLASHLOAN_MODE = '47'; //Invalid flashloan mode selected
  string public constant MATH_MULTIPLICATION_OVERFLOW = '48';
  string public constant MATH_ADDITION_OVERFLOW = '49';
  string public constant MATH_DIVISION_BY_ZERO = '50';
  string public constant CT_INVALID_MINT_AMOUNT = '56'; //invalid amount to mint
  string public constant CT_INVALID_BURN_AMOUNT = '58'; //invalid amount to burn
  string public constant P_REENTRANCY_NOT_ALLOWED = '62';
  string public constant P_CALLER_MUST_BE_AN_ATOKEN = '63';
  string public constant P_IS_PAUSED = '64'; // Deprecated 'Pool is paused'
  string public constant P_NO_MORE_RESERVES_ALLOWED = '65';
  string public constant P_INVALID_FLASH_LOAN_EXECUTOR_RETURN = '66';
  string public constant RC_INVALID_LTV = '67';
  string public constant RC_INVALID_LIQ_THRESHOLD = '68';
  string public constant RC_INVALID_LIQ_BONUS = '69';
  string public constant RC_INVALID_DECIMALS = '70';
  string public constant RC_INVALID_RESERVE_FACTOR = '71';
  string public constant PAPR_INVALID_ADDRESSES_PROVIDER_ID = '72';
  string public constant VL_INCONSISTENT_FLASHLOAN_PARAMS = '73';
  string public constant P_INCONSISTENT_PARAMS_LENGTH = '74';
  string public constant UL_INVALID_INDEX = '77';
  string public constant P_NOT_CONTRACT = '78';
  string public constant SDT_STABLE_DEBT_OVERFLOW = '79'; // Deprecated moved to general `HLP_UINT128_OVERFLOW`
  string public constant SDT_BURN_EXCEEDS_BALANCE = '80';
  string public constant VL_BORROW_CAP_EXCEEDED = '81';
  string public constant RC_INVALID_BORROW_CAP = '82';
  string public constant VL_SUPPLY_CAP_EXCEEDED = '83';
  string public constant RC_INVALID_SUPPLY_CAP = '84';
  string public constant PC_CALLER_NOT_EMERGENCY_OR_POOL_ADMIN = '85';
  string public constant VL_RESERVE_PAUSED = '86';
  string public constant PC_CALLER_NOT_RISK_OR_POOL_ADMIN = '87';
  string public constant RL_ATOKEN_SUPPLY_NOT_ZERO = '88';
  string public constant RL_STABLE_DEBT_NOT_ZERO = '89';
  string public constant RL_VARIABLE_DEBT_SUPPLY_NOT_ZERO = '90';
  string public constant VL_LTV_VALIDATION_FAILED = '93';
  string public constant VL_SAME_BLOCK_BORROW_REPAY = '94';
  string public constant PC_FLASHLOAN_PREMIUMS_MISMATCH = '95';
  string public constant PC_FLASHLOAN_PREMIUM_INVALID = '96';
  string public constant RC_INVALID_LIQUIDATION_PROTOCOL_FEE = '97';
  string public constant RC_INVALID_EMODE_CATEGORY = '98';
  string public constant VL_INCONSISTENT_EMODE_CATEGORY = '99';
  string public constant HLP_UINT128_OVERFLOW = '100';
  string public constant PC_CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN = '101';
  string public constant P_CALLER_NOT_BRIDGE = '102';
  string public constant RC_INVALID_UNBACKED_MINT_CAP = '103';
  string public constant VL_UNBACKED_MINT_CAP_EXCEEDED = '104';
  string public constant VL_PRICE_ORACLE_SENTINEL_CHECK_FAILED = '105';
  string public constant RC_INVALID_DEBT_CEILING = '106';
  string public constant VL_ASSET_NOT_BORROWABLE_IN_ISOLATION = '107';
  string public constant VL_DEBT_CEILING_CROSSED = '108';
  string public constant SL_USER_IN_ISOLATION_MODE = '109';
  string public constant PC_BRIDGE_PROTOCOL_FEE_INVALID = '110';
}