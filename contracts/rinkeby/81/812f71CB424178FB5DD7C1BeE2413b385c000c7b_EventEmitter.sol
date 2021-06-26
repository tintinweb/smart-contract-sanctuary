// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract EventEmitter {
  constructor() {
  }

  event Event();

  function create(uint256 number) public {
    while (number != 0) {
      emit Event();
      number--;
    }
  }
}

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "remappings": [],
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