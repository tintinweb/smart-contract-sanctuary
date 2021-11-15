// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract BytesStorage {
  bytes dataBytes;
  bytes32[2] data;

  function updateData(bytes memory _data1, bytes32 _data2, bytes32 _data3) external {
    dataBytes = _data1;
    data = [_data2, _data3];
  }
  function readData() external view returns(bytes32[2] memory) {
    return data;
  }
  function readDataBytes() external view returns(bytes memory) {
    return dataBytes;
  }
}

