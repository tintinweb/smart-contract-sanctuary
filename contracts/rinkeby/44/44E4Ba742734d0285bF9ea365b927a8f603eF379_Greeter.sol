//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    uint256 private number;

    constructor(uint256 num1, uint256 num2) {}
}

{
  "optimizer": {
    "enabled": false,
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