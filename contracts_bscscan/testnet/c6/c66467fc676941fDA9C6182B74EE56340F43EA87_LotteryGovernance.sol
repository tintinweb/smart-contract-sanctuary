// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract LotteryGovernance {
  uint256 public one_time = 1;
  address public lottery;
  address public randomness;

  constructor() {}

  function init(address _lottery, address _randomness) public {
    require(_randomness != address(0), "governance/no-randomnesss-address");
    require(_lottery != address(0), "no-lottery-address-given");
    require(one_time > 0, "can-only-be-called-once");

    one_time = one_time - 1;
    randomness = _randomness;
    lottery = _lottery;
  }
}

