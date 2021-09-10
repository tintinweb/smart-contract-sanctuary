pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



contract ABC {

    uint256 public c;
    constructor(uint256 cap) {
        c = cap;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}