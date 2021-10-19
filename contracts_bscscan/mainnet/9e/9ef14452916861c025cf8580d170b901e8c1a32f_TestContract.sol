/**
 *Submitted for verification at BscScan.com on 2021-10-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface TestStrategy {
  function harvestTrigger(uint256 gasCost) external view returns (bool);
}

contract TestContract {
  bool success;
  function testHarvestTrigger(uint256 gasCost) external returns (bool) {
    TestStrategy strategy = TestStrategy(0xfC02FE1fcCd40139B01d568ff46655bBca9ce4d5);
    success = strategy.harvestTrigger(gasCost);
    return success;
  }
}