/**
 *Submitted for verification at polygonscan.com on 2021-12-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

contract SimpleStorage {
  uint storedData;

  uint storedData2;

  function set(uint x) public {
    storedData = x;
  }

  function set2(uint x) public {
    storedData2 = x;
  }

  function get() public view returns (uint) {
    return storedData;
  }
}