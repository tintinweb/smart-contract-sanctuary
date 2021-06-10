// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IYVaultV2 {
  function pricePerShare() external view returns (uint256);
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