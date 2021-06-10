// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface ICToken {
  function totalReserves() external view returns (uint256);

  function totalBorrows() external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function getCash() external view returns (uint256);

  function exchangeRateStored() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

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