// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract MemeKiller {
  constructor() public {
  }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "byzantium",
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