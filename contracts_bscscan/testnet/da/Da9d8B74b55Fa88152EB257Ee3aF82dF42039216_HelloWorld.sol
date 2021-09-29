// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

contract HelloWorld {
    constructor() {}

    function helloWorld() external pure returns (string memory) {
        return "hello world";
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 780
  },
  "metadata": {
    "bytecodeHash": "none"
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