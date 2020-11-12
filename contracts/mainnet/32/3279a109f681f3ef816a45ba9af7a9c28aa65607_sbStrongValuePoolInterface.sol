// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface sbStrongValuePoolInterface {
  function mineFor(address miner, uint256 amount) external;

  function getMinerMineData(address miner, uint256 day)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  function getMineData(uint256 day)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  function serviceMinMined(address miner) external view returns (bool);

  function minerMinMined(address miner) external view returns (bool);
}
