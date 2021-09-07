/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @title The ChronScheduler contract
 * @notice A chainlink keeper-compatible contract that schedules tasks using chron
 */
contract GasPriceTester {
  uint256 public lastGasPrice;

  event GasPriceChanged(
    uint256 oldPrice,
    uint256 newPrice,
    uint256 actualPrice
  );

  /**
   * @notice Get list of addresses that are underfunded and return keeper-compatible payload
   * @return upkeepNeeded signals if upkeep is needed, performData is an abi encoded list of addresses that need funds
   */
  function checkUpkeep(bytes calldata)
    external
    view
    returns (bool upkeepNeeded, bytes memory performData)
  {
    if (lastGasPrice > tx.gasprice) {
      upkeepNeeded = lastGasPrice - tx.gasprice > 5 gwei;
    } else {
      upkeepNeeded = tx.gasprice - lastGasPrice > 5 gwei;
    }
    performData = abi.encode(tx.gasprice);
    return (upkeepNeeded, performData);
  }

  /**
   * @notice Called by keeper to send funds to underfunded addresses
   * @param performData The abi encoded list of addresses to fund
   */
  function performUpkeep(bytes calldata performData) external {
    uint256 priceInCall = abi.decode(performData, (uint256));
    emit GasPriceChanged(lastGasPrice, priceInCall, tx.gasprice);
    lastGasPrice = priceInCall;
  }
}