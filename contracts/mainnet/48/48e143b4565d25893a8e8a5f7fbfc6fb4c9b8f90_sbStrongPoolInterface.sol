// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface sbStrongPoolInterface {
  function serviceMinMined(address miner) external view returns (bool);

  function minerMinMined(address miner) external view returns (bool);

  function mineFor(address miner, uint256 amount) external;

  function getMineData(uint256 day)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  function receiveRewards(uint256 day, uint256 amount) external;
}
