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

interface IYVaultV2 {
  function totalSupply() external view returns (uint256);

  function pricePerShare() external view returns (uint256);
}

