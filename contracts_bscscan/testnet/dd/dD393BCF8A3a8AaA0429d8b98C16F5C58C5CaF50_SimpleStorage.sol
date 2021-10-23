/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SimpleStorage {
  uint data;

  function updateData(uint _data) external {
    data = _data;
  }

  function readData() external view returns(uint) {
    return data;
  }
}