/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;



contract Counter  {
  uint256 public count;
  uint256 public lastExecuted;

  constructor(address  _pokeMe) {}

  function increaseCount(uint256 amount) external {
    require(
      ((block.timestamp - lastExecuted) > 180),
      "Counter: increaseCount: Time not elapsed"
    );

    count += amount;
    lastExecuted = block.timestamp;
  }
}