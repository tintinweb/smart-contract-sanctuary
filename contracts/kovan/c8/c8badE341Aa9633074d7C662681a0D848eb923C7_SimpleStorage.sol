// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract SimpleStorage {
  uint256 data;

  function updateData(uint256 _data) external {
    data = _data;
  }
  function readData() external view returns(uint256) {
    return data;
  }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}