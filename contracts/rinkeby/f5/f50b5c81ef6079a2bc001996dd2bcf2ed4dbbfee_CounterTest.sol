/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;


contract CounterTest {
  uint256 public count;
  uint256 public lastExecuted;

  constructor() {}

  function increaseCount(uint256 amount) external {
    require(
      ((block.timestamp - lastExecuted) > 10),
      "Counter: increaseCount: Time not elapsed"
    );

    count += amount;
    lastExecuted = block.timestamp;
  }
}