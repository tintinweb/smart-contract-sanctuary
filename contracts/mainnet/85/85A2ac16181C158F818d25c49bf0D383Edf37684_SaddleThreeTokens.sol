pragma solidity ^0.8.5;

import "./interfaces/ICToken.sol";
import "./interfaces/ITrigger.sol";

/**
 * @notice Defines a trigger that is toggled if the Compound exchange rate decreases between consecutive checks. Under
 * normal operation, this value should only increase
 */
contract CompoundExchangeRate is ITrigger {
  uint256 internal constant WAD = 10**18;

  /// @notice Address of CToken market protected by this trigger
  ICToken public immutable market;

  /// @notice Last read exchangeRateStored
  uint256 public lastExchangeRate;

  /// @dev Due to rounding errors in the Compound Protocol, the exchangeRateStored may occassionally decrease by small
  /// amount even when nothing is wrong. A large, very conservative tolerance is applied to ensure we do not
  /// accidentally trigger in these cases. Even though a smaller tolerance would likely be ok, a non-trivial exploit
  ///  will most likely cause the exchangeRateStored to decrease by more than 10,000 wei
  uint256 public constant tolerance = 10000; // 10,000 wei tolerance

  /**
   * @param _market Is the address of the Compound market this trigger should protect
   * @dev For definitions of other constructor parameters, see ITrigger.sol
   */
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _description,
    uint256[] memory _platformIds,
    address _recipient,
    address _market
  ) ITrigger(_name, _symbol, _description, _platformIds, _recipient) {
    // Set market
    market = ICToken(_market);

    // Save current exchange rate (immutables can't be read at construction, so we don't use `market` directly)
    lastExchangeRate = ICToken(_market).exchangeRateStored();
  }

  /**
   * @dev Checks if a CToken's exchange rate decreased. The exchange rate should never decrease, but may occasionally
   * decrease slightly due to rounding errors
   * @return True if trigger condition occured (i.e. exchange rate decreased), false otherwise
   */
  function checkTriggerCondition() internal override returns (bool) {
    // Read this blocks exchange rate
    uint256 _currentExchangeRate = market.exchangeRateStored();

    // Check if current exchange rate is below current exchange rate, accounting for tolerance
    bool _status = _currentExchangeRate < (lastExchangeRate - tolerance);

    // Save the new exchange rate
    lastExchangeRate = _currentExchangeRate;

    // Return status
    return _status;
  }
}

pragma solidity ^0.8.5;

interface ICToken {
  function totalReserves() external view returns (uint256);

  function totalBorrows() external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function getCash() external view returns (uint256);

  function exchangeRateStored() external view returns (uint256);
}

pragma solidity ^0.8.5;

/**
 * @notice Abstract contract for creating or interacting with a Trigger contract
 * @dev All trigger contracts created must inerit from this contract and conform to this interface
 */
abstract contract ITrigger {
  /// @notice Trigger name, analgous to an ERC-20 token's name
  string public name;

  /// @notice Trigger symbol, analgous to an ERC-20 token's symbol
  string public symbol;

  /// @notice Trigger description
  string public description;

  /// @notice Array of IDs of platforms covered by this trigger
  uint256[] public platformIds;

  /// @notice Returns address of recipient who receives subsidies for creating a protection market using this trigger
  address public immutable recipient;

  /// @notice Returns true if trigger condition has been met
  bool public isTriggered;

  /// @notice Emitted when the trigger is activated
  event TriggerActivated();

  /**
   * @notice Returns array of IDs, where each ID corresponds to a platform covered by this trigger
   * @dev See documentation for mapping of ID numbers to platforms
   */
  function getPlatformIds() external view returns (uint256[] memory) {
    return platformIds;
  }

  /**
   * @dev Executes trigger-specific logic to check if market has been triggered
   * @return True if trigger condition occured, false otherwise
   */
  function checkTriggerCondition() internal virtual returns (bool);

  /**
   * @notice Checks trigger condition, sets isTriggered flag to true if condition is met, and returns the trigger status
   * @return True if trigger condition occured, false otherwise
   */
  function checkAndToggleTrigger() external returns (bool) {
    // Return true if trigger already toggled
    if (isTriggered) return true;

    // Return false if market has not been triggered
    if (!checkTriggerCondition()) return false;

    // Otherwise, market has been triggered
    emit TriggerActivated();
    isTriggered = true;
    return isTriggered;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _description,
    uint256[] memory _platformIds,
    address _recipient
  ) {
    name = _name;
    description = _description;
    symbol = _symbol;
    platformIds = _platformIds;
    recipient = _recipient;
  }
}

pragma solidity ^0.8.5;

import "./interfaces/IYVaultV2.sol";
import "./interfaces/ITrigger.sol";

/**
 * @notice Defines a trigger that is toggled if the price per share for the V2 yVault decreases between consecutive
 * checks. Under normal operation, this value should only increase
 */
contract YearnV2SharePrice is ITrigger {
  uint256 internal constant WAD = 10**18;

  /// @notice Vault this trigger is for
  IYVaultV2 public immutable market;

  /// @notice Last read pricePerShare
  uint256 public lastPricePerShare;

  /// @dev In Yearn V2 vaults, the pricePerShare decreases immediately after a harvest, and typically ramps up over the
  /// next six hours. Therefore we cannot simply check that the pricePerShare increases. Instead, we consider the vault
  /// triggered if the pricePerShare drops by more than 50% from it's previous value. This is conservative, but
  /// previous Yearn bugs resulted in pricePerShare drops of 0.5% – 10%, and were only temporary drops with users able
  /// to be made whole. Therefore this trigger requires a large 50% drop to minimize false positives. The tolerance
  /// is defined such that we trigger if: currentPricePerShare < lastPricePerShare * tolerance / 1e18. This means
  /// if you want to trigger after a 20% drop, you should set the tolerance to 1e18 - 0.2e18 = 0.8e18 = 8e17
  uint256 public constant tolerance = 5e17; // 50%, represented on a scale where 1e18 = 100%

  /**
   * @param _market Is the address of the Yearn V2 vault this trigger should protect
   * @dev For definitions of other constructor parameters, see ITrigger.sol
   */
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _description,
    uint256[] memory _platformIds,
    address _recipient,
    address _market
  ) ITrigger(_name, _symbol, _description, _platformIds, _recipient) {
    // Set vault
    market = IYVaultV2(_market);

    // Save current share price (immutables can't be read at construction, so we don't use `market` directly)
    lastPricePerShare = IYVaultV2(_market).pricePerShare();
  }

  /**
   * @dev Checks the yVault pricePerShare
   */
  function checkTriggerCondition() internal override returns (bool) {
    // Read this blocks share price
    uint256 _currentPricePerShare = market.pricePerShare();

    // Check if current share price is below current share price, accounting for tolerance
    bool _status = _currentPricePerShare < ((lastPricePerShare * tolerance) / 1e18);

    // Save the new share price
    lastPricePerShare = _currentPricePerShare;

    // Return status
    return _status;
  }
}

pragma solidity ^0.8.5;

interface IYVaultV2 {
  function totalSupply() external view returns (uint256);

  function pricePerShare() external view returns (uint256);
}

pragma solidity ^0.8.6;

import "./interfaces/ICurvePool.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ITrigger.sol";
import "./interfaces/IYVaultV2.sol";

/**
 * @notice Defines a trigger that is toggled if any of the following conditions occur:
 *   1. The price per share for the V2 yVault significantly decreases between consecutive checks. Under normal
 *      operation, this value should only increase. A decrease indicates something is wrong with the Yearn vault
 *   2. Curve Tricrypto token balances are significantly lower than what the pool expects them to be
 *   3. Curve Tricrypto virtual price drops significantly
 * @dev This trigger is for Yearn V2 Vaults that use a Curve pool with two underlying tokens
 */
contract YearnCrvTwoTokens is ITrigger {
  // --- Tokens ---
  // Token addresses
  IERC20 internal immutable token0;
  IERC20 internal immutable token1;

  // --- Tolerances ---
  /// @dev Scale used to define percentages. Percentages are defined as tolerance / scale
  uint256 public constant scale = 1000;

  /// @dev In Yearn V2 vaults, the pricePerShare decreases immediately after a harvest, and typically ramps up over the
  /// next six hours. Therefore we cannot simply check that the pricePerShare increases. Instead, we consider the vault
  /// triggered if the pricePerShare drops by more than 50% from it's previous value. This is conservative, but
  /// previous Yearn bugs resulted in pricePerShare drops of 0.5% – 10%, and were only temporary drops with users able
  /// to be made whole. Therefore this trigger requires a large 50% drop to minimize false positives. The tolerance
  /// is defined such that we trigger if: currentPricePerShare < lastPricePerShare * tolerance / 1000. This means
  /// if you want to trigger after a 20% drop, you should set the tolerance to 1000 - 200 = 800
  uint256 public constant vaultTol = scale - 500; // 50% drop, represented on a scale where 1000 = 100%

  /// @dev Consider trigger toggled if Curve virtual price drops by more than this percentage.
  uint256 public constant virtualPriceTol = scale - 500; // 50% drop

  /// @dev Consider trigger toggled if Curve internal balances are lower than true balances by this percentage
  uint256 public constant balanceTol = scale - 500; // 50% drop

  // --- Trigger Data ---
  /// @notice Yearn vault this trigger is for
  IYVaultV2 public immutable vault;

  /// @notice Curve tricrypto pool used as a strategy by `vault`
  ICurvePool public immutable curve;

  /// @notice Last read pricePerShare
  uint256 public lastPricePerShare;

  /// @notice Last read curve virtual price
  uint256 public lastVirtualPrice;

  // --- Constructor ---

  /**
   * @param _vault Address of the Yearn V2 vault this trigger should protect
   * @param _curve Address of the Curve Tricrypto pool uses by the above Yearn vault
   * @dev For definitions of other constructor parameters, see ITrigger.sol
   */
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _description,
    uint256[] memory _platformIds,
    address _recipient,
    address _vault,
    address _curve
  ) ITrigger(_name, _symbol, _description, _platformIds, _recipient) {
    // Set trigger data
    vault = IYVaultV2(_vault);
    curve = ICurvePool(_curve);
    token0 = IERC20(ICurvePool(_curve).coins(0));
    token1 = IERC20(ICurvePool(_curve).coins(1));

    // Save current values (immutables can't be read at construction, so we don't use `vault` or `curve` directly)
    lastPricePerShare = IYVaultV2(_vault).pricePerShare();
    lastVirtualPrice = ICurvePool(_curve).get_virtual_price();
  }

  // --- Trigger condition ---

  /**
   * @dev Checks the yVault pricePerShare
   */
  function checkTriggerCondition() internal override returns (bool) {
    // Read this blocks share price and virtual price
    uint256 _currentPricePerShare = vault.pricePerShare();
    uint256 _currentVirtualPrice = curve.get_virtual_price();

    // Check trigger conditions. We could check one at a time and return as soon as one is true, but it is convenient
    // to have the data that caused the trigger saved into the state, so we don't do that
    bool _statusVault = _currentPricePerShare < ((lastPricePerShare * vaultTol) / scale);
    bool _statusVirtualPrice = _currentVirtualPrice < ((lastVirtualPrice * virtualPriceTol) / scale);
    bool _statusBalances = checkCurveBalances();

    // Save the new data
    lastPricePerShare = _currentPricePerShare;
    lastVirtualPrice = _currentVirtualPrice;

    // Return status
    return _statusVault || _statusVirtualPrice || _statusBalances;
  }

  /**
   * @dev Checks if the Curve internal balances are significantly lower than the true balances
   * @return True if balances are out of tolerance and trigger should be toggled
   */
  function checkCurveBalances() internal view returns (bool) {
    return
      (token0.balanceOf(address(curve)) < ((curve.balances(0) * balanceTol) / scale)) ||
      (token1.balanceOf(address(curve)) < ((curve.balances(1) * balanceTol) / scale));
  }
}

pragma solidity ^0.8.5;

interface ICurvePool {
  /// @notice Computes current virtual price
  function get_virtual_price() external view returns (uint256);

  /// @notice Cached virtual price, used internally
  function virtual_price() external view returns (uint256);

  /// @notice Current full profit
  function xcp_profit() external view returns (uint256);

  /// @notice Full profit at last claim of admin fees
  function xcp_profit_a() external view returns (uint256);

  /// @notice Pool admin fee
  function admin_fee() external view returns (uint256);

  /// @notice Returns balance for the token defined by the provided index
  function balances(uint256 index) external view returns (uint256);

  /// @notice Returns the address of the token for the provided index
  function coins(uint256 index) external view returns (address);
}

pragma solidity ^0.8.5;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.5;

import "./interfaces/ICurvePool.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ITrigger.sol";
import "./interfaces/IYVaultV2.sol";

/**
 * @notice Defines a trigger that is toggled if any of the following conditions occur:
 *   1. The price per share for the V2 yVault significantly decreases between consecutive checks. Under normal
 *      operation, this value should only increase. A decrease indicates something is wrong with the Yearn vault
 *   2. Curve Tricrypto token balances are significantly lower than what the pool expects them to be
 *   3. Curve Tricrypto virtual price drops significantly
 */
contract YearnCrvTricrypto is ITrigger {
  // --- Tokens ---
  // Token addresses
  IERC20 internal constant usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  IERC20 internal constant wbtc = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
  IERC20 internal constant weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  // Token indices in Curve pool arrays
  uint256 internal constant usdtIndex = 0;
  uint256 internal constant wbtcIndex = 1;
  uint256 internal constant wethIndex = 2;

  // --- Tolerances ---
  /// @dev Scale used to define percentages. Percentages are defined as tolerance / scale
  uint256 public constant scale = 1000;

  /// @dev In Yearn V2 vaults, the pricePerShare decreases immediately after a harvest, and typically ramps up over the
  /// next six hours. Therefore we cannot simply check that the pricePerShare increases. Instead, we consider the vault
  /// triggered if the pricePerShare drops by more than 50% from it's previous value. This is conservative, but
  /// previous Yearn bugs resulted in pricePerShare drops of 0.5% – 10%, and were only temporary drops with users able
  /// to be made whole. Therefore this trigger requires a large 50% drop to minimize false positives. The tolerance
  /// is defined such that we trigger if: currentPricePerShare < lastPricePerShare * tolerance / 1000. This means
  /// if you want to trigger after a 20% drop, you should set the tolerance to 1000 - 200 = 800
  uint256 public constant vaultTol = scale - 500; // 50% drop, represented on a scale where 1000 = 100%

  /// @dev Consider trigger toggled if Curve virtual price drops by this percentage. Similar to the Yearn V2 price
  /// per share, the virtual price is expected to decrease during normal operation, but it can never decrease by
  /// more than 50% during normal operation. Therefore we check for a 51% drop
  uint256 public constant virtualPriceTol = scale - 510; // 51% drop, since 1000-510=490, and multiplying by 0.49 = 51% drop

  /// @dev Consider trigger toggled if Curve internal balances are lower than true balances by this percentage
  uint256 public constant balanceTol = scale - 500; // 50% drop

  // --- Trigger Data ---
  /// @notice Yearn vault this trigger is for
  IYVaultV2 public immutable vault;

  /// @notice Curve tricrypto pool used as a strategy by `vault`
  ICurvePool public immutable curve;

  /// @notice Last read pricePerShare
  uint256 public lastPricePerShare;

  /// @notice Last read curve virtual price
  uint256 public lastVirtualPrice;

  // --- Constructor ---

  /**
   * @param _vault Address of the Yearn V2 vault this trigger should protect
   * @param _curve Address of the Curve Tricrypto pool uses by the above Yearn vault
   * @dev For definitions of other constructor parameters, see ITrigger.sol
   */
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _description,
    uint256[] memory _platformIds,
    address _recipient,
    address _vault,
    address _curve
  ) ITrigger(_name, _symbol, _description, _platformIds, _recipient) {
    // Set vault
    vault = IYVaultV2(_vault);
    curve = ICurvePool(_curve);

    // Save current values (immutables can't be read at construction, so we don't use `vault` or `curve` directly)
    lastPricePerShare = IYVaultV2(_vault).pricePerShare();
    lastVirtualPrice = ICurvePool(_curve).get_virtual_price();
  }

  // --- Trigger condition ---

  /**
   * @dev Checks the yVault pricePerShare
   */
  function checkTriggerCondition() internal override returns (bool) {
    // Read this blocks share price and virtual price
    uint256 _currentPricePerShare = vault.pricePerShare();
    uint256 _currentVirtualPrice = curve.get_virtual_price();

    // Check trigger conditions. We could check one at a time and return as soon as one is true, but it is convenient
    // to have the data that caused the trigger saved into the state, so we don't do that
    bool _statusVault = _currentPricePerShare < ((lastPricePerShare * vaultTol) / scale);
    bool _statusVirtualPrice = _currentVirtualPrice < ((lastVirtualPrice * virtualPriceTol) / scale);
    bool _statusBalances = checkCurveBalances();

    // Save the new data
    lastPricePerShare = _currentPricePerShare;
    lastVirtualPrice = _currentVirtualPrice;

    // Return status
    return _statusVault || _statusVirtualPrice || _statusBalances;
  }

  /**
   * @dev Checks if the Curve internal balances are significantly lower than the true balances
   * @return True if balances are out of tolerance and trigger should be toggled
   */
  function checkCurveBalances() internal view returns (bool) {
    return
      (usdt.balanceOf(address(curve)) < ((curve.balances(usdtIndex) * balanceTol) / scale)) ||
      (wbtc.balanceOf(address(curve)) < ((curve.balances(wbtcIndex) * balanceTol) / scale)) ||
      (weth.balanceOf(address(curve)) < ((curve.balances(wethIndex) * balanceTol) / scale));
  }
}

pragma solidity ^0.8.5;

import "../interfaces/ICurvePool.sol";

/**
 * @notice Mock Curve Tricrypto pool, containing the same interface but configurable parameters for testing
 */
contract MockCrvTricrypto is ICurvePool {
  uint256 public override get_virtual_price;
  uint256 public override virtual_price;
  uint256 public override xcp_profit;
  uint256 public override xcp_profit_a;
  uint256 public override admin_fee;

  constructor() {
    // Initializing the values based on the actual values on 2021-07-15
    get_virtual_price = 1001041521509972624;
    virtual_price = 1001041521509972624;
    xcp_profit = 1001056295181177762;
    xcp_profit_a = 1001035776942422073;
    admin_fee = 5000000000;
  }

  /**
   * @notice Set the pricePerShare
   * @param _get_virtual_price New get_virtual_price value
   */
  function set(uint256 _get_virtual_price) external {
    get_virtual_price = _get_virtual_price;
  }

  function balances(uint256 index) external pure override returns (uint256) {
    require(index == 0 || index == 1 || index == 2, "bad index");
    return 1;
  }

  function coins(uint256 index) external pure override returns (address) {
    // This method is not used and is just to satisfy the interface this contract inherits from
    index; // silence compiler warning about unused variables
    return address(0);
  }
}

pragma solidity ^0.8.6;

import "./interfaces/ISaddlePool.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ITrigger.sol";
import "./interfaces/IYVaultV2.sol";

/**
 * @notice Defines a trigger that is toggled if any of the following conditions occur:
 *   1. Saddle token balances are significantly lower than what the pool expects them to be
 *   2. Saddle virtual price drops significantly
 * @dev This trigger is for Yearn V2 Vaults that use a Saddle pool with two underlying tokens
 */
contract SaddleThreeTokens is ITrigger {
  // --- Tokens ---
  // Token addresses
  IERC20 internal immutable token0;
  IERC20 internal immutable token1;
  IERC20 internal immutable token2;

  // --- Tolerances ---
  /// @dev Scale used to define percentages. Percentages are defined as tolerance / scale
  uint256 public constant scale = 1000;

  /// @dev Consider trigger toggled if Saddle virtual price drops by more than this percentage.
  uint256 public constant virtualPriceTol = scale - 500; // 50% drop

  /// @dev Consider trigger toggled if Saddle internal balances are lower than true balances by this percentage
  uint256 public constant balanceTol = scale - 500; // 50% drop

  // --- Trigger Data ---
  /// @notice Saddle pool to protect
  ISaddlePool public immutable saddle;

  /// @notice Last read Saddle virtual price
  uint256 public lastVirtualPrice;

  // --- Constructor ---
  /**
   * @param _saddle Address of the Saddle pool, must contain three underlying tokens
   * @dev For definitions of other constructor parameters, see ITrigger.sol
   */
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _description,
    uint256[] memory _platformIds,
    address _recipient,
    address _saddle
  ) ITrigger(_name, _symbol, _description, _platformIds, _recipient) {
    // Set trigger data
    saddle = ISaddlePool(_saddle);
    token0 = IERC20(ISaddlePool(_saddle).getToken(0));
    token1 = IERC20(ISaddlePool(_saddle).getToken(1));
    token2 = IERC20(ISaddlePool(_saddle).getToken(2));

    // Save current values (immutables can't be read at construction, so we don't use `vault` or `saddle` directly)
    lastVirtualPrice = ISaddlePool(_saddle).getVirtualPrice();
  }

  // --- Trigger condition ---
  /**
   * @dev Checks the yVault pricePerShare
   */
  function checkTriggerCondition() internal override returns (bool) {
    // Read this blocks share price and virtual price
    uint256 _currentVirtualPrice = saddle.getVirtualPrice();

    // Check trigger conditions. We could check one at a time and return as soon as one is true, but it is convenient
    // to have the data that caused the trigger saved into the state, so we don't do that
    bool _statusVirtualPrice = _currentVirtualPrice < ((lastVirtualPrice * virtualPriceTol) / scale);
    bool _statusBalances = checkSaddleBalances();

    // Save the new data
    lastVirtualPrice = _currentVirtualPrice;

    // Return status
    return _statusVirtualPrice || _statusBalances;
  }

  /**
   * @dev Checks if the Saddle internal balances are significantly lower than the true balances
   * @return True if balances are out of tolerance and trigger should be toggled
   */
  function checkSaddleBalances() internal view returns (bool) {
    return
      (token0.balanceOf(address(saddle)) < ((saddle.getTokenBalance(0) * balanceTol) / scale)) ||
      (token1.balanceOf(address(saddle)) < ((saddle.getTokenBalance(1) * balanceTol) / scale)) ||
      (token2.balanceOf(address(saddle)) < ((saddle.getTokenBalance(2) * balanceTol) / scale));
  }
}

pragma solidity ^0.8.5;

interface ISaddlePool {
  /// @notice Computes current virtual price
  function getVirtualPrice() external view returns (uint256);

  /// @notice Returns balance for the token defined by the provided index
  function getTokenBalance(uint8 index) external view returns (uint256);

  /// @notice Returns the address of the token for the provided index
  function getToken(uint8 index) external view returns (address);
}

pragma solidity ^0.8.5;

import "../interfaces/IYVaultV2.sol";

/**
 * @notice Mock yVault, implemented the same way as a Yearn vault, but with configurable parameters for testing
 */
contract MockYVaultV2 is IYVaultV2 {
  uint256 public override pricePerShare;
  uint256 public underlyingDecimals = 6; // decimals of USDC underlying
  uint256 public override totalSupply; // not used, but needed so this is not an abstract contract

  constructor() {
    // Initializing the values based on the yUSDC values on 2021-06-03
    pricePerShare = 1058448;
  }

  /**
   * @notice Set the pricePerShare
   * @param _pricePerShare New pricePerShare value
   */
  function set(uint256 _pricePerShare) external {
    pricePerShare = _pricePerShare;
  }
}

pragma solidity ^0.8.5;

import "../interfaces/ITrigger.sol";

/**
 * @notice Mock MockCozyToken, for testing the return value of a trigger's `checkAndToggleTrigger()` method
 */
contract MockCozyToken {
  /// @notice Trigger contract address
  address public immutable trigger;

  /// @notice In a real Cozy Token, this state variable is toggled when trigger event occues
  bool public isTriggered;

  constructor(address _trigger) {
    // Set the trigger address in the constructor
    trigger = _trigger;
  }

  /**
   * @notice Sufficiently mimics the implementation of a Cozy Token's `checkAndToggleTriggerInternal()` method
   */
  function checkAndToggleTrigger() external {
    isTriggered = ITrigger(trigger).checkAndToggleTrigger();
  }
}

pragma solidity ^0.8.5;

import "./interfaces/ITrigger.sol";

contract MockTrigger is ITrigger {
  /// @notice If true, checkAndToggleTrigger will toggle the trigger on its next call
  bool public shouldToggle;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _description,
    uint256[] memory _platformIds,
    address _recipient,
    bool _shouldToggle
  ) ITrigger(_name, _symbol, _description, _platformIds, _recipient) {
    shouldToggle = _shouldToggle;

    // Verify market is not already triggered.
    require(!checkTriggerCondition(), "Already triggered");
  }

  /**
   * @notice Special function for this mock trigger to set whether or not the trigger should toggle
   */
  function setShouldToggle(bool _shouldToggle) external {
    require(!isTriggered, "Cannot set after trigger event");
    shouldToggle = _shouldToggle;
  }

  /**
   * @notice Returns true if the market has been triggered, false otherwise
   */
  function checkTriggerCondition() internal view override returns (bool) {
    return shouldToggle;
  }
}

pragma solidity ^0.8.5;

import "../interfaces/ICToken.sol";

/**
 * @notice Mock CToken, implemented the same way as a Compound CToken, but with configurable parameters for testing
 */

contract MockCToken is ICToken {
  uint256 public override totalReserves;
  uint256 public override totalBorrows;
  uint256 public override totalSupply;
  uint256 public override exchangeRateStored;
  uint256 internal cash; // this is the balanceOf the underlying ERC20/ETH
  uint256 public underlyingDecimals = 6; // decimals of USDC underlying

  constructor() {
    // Initializing the values based on the cUSDC values on 2021-05-10 (around block 12,409,320)
    totalReserves = 5359893964073; // units of USDC
    totalBorrows = 3681673803163527; // units of USDC
    totalSupply = 20287132947568793418; // units of cUSDC
    exchangeRateStored = 219815665774648; // units of 10^(18 + underlyingDecimals - 8)
    cash = 783115726329188; // units of USDC
  }

  /**
   * @notice Set the value of a parameter
   * @param _name Name of the variable to set
   * @param _value Value to set the parameter to
   */
  function set(bytes32 _name, uint256 _value) external {
    if (_name == "totalReserves") totalReserves = _value;
    if (_name == "totalBorrows") totalBorrows = _value;
    if (_name == "totalSupply") totalSupply = _value;
    if (_name == "exchangeRateStored") exchangeRateStored = _value;
    if (_name == "cash") cash = _value;
  }

  /**
   * @notice Get cash balance of this cToken in the underlying asset
   * @return The quantity of underlying asset owned by this contract
   */
  function getCash() external view override returns (uint256) {
    return cash;
  }
}

{
  "metadata": {
    "bytecodeHash": "none"
  },
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}