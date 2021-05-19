/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

contract SimpleStorage {
  uint storedData;

  function set(uint x) public {
    storedData = x;
  }

  function get() public view returns (uint) {
    return storedData;
  }
}