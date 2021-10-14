// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

contract FakeLinkBSCOracle {

  function latestAnswer() public returns(uint) {

    return 10;
  }

  function decimals() public returns(uint) {

    return 10;
  }

}