// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract Counter {
  uint256 public count;

  function increaseCount(uint256 amount) external {
    count += amount;
  }
}

