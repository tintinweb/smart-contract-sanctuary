// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract MockAggregator {
  int256 private _latestAnswer;

  event setPriceUpdated(int256 indexed current);
  // The price of assets in Aave contracts was in ETH wei (Eth = 4200USD), adding 238*10**10 to convert 0.01 USD => ETHwei
  function setPriceInUsd(int256 latestAnswer_inUsd) external returns (int256) {
    _latestAnswer = latestAnswer_inUsd * 238 * 10 ** 10;
    emit setPriceUpdated(latestAnswer_inUsd);
  }

  function latestAnswer() external view returns (int256) {
    return _latestAnswer;
  }

  function getTokenType() external view returns (uint256) {
    return 1;
  }

}