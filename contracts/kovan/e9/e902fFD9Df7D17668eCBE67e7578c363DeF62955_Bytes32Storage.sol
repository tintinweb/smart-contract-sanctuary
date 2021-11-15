// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Bytes32Storage {
  bytes32[3] data;

  function updateData(bytes32 _data1, bytes32 _data2, bytes32 _data3) external {
    data = [_data1, _data2, _data3];
  }
  function readData() external view returns(bytes32[3] memory) {
    return data;
  }
}

