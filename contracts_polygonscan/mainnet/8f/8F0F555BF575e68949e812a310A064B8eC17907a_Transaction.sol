/**
 *Submitted for verification at polygonscan.com on 2022-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Transaction {

  uint storedData;

  function inc() external {
    storedData = storedData + 1;
  }

  function set(uint x) public {
    storedData = x;
  }

  function get() public view returns (uint) {
    return storedData;
  }

}