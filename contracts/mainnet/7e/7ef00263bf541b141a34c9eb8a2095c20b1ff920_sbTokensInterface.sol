// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface sbTokensInterface {
  function getTokens() external view returns (address[] memory);

  function getTokenPrices(uint256 day) external view returns (uint256[] memory);

  function tokenAccepted(address token) external view returns (bool);

  function upToDate() external view returns (bool);

  function getTokenPrice(address token, uint256 day) external view returns (uint256);
}
