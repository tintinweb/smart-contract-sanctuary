/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SimpleStorage {
  uint data;

  function updateData(uint _data) external {
    if (_data == 10) revert();
    data = _data;

  }

  function readData() external view returns(uint) {
    return data;
  }
}