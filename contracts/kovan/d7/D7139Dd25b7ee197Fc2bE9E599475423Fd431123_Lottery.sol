// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.3;

contract Lottery {
  address public manager;

  constructor() {
    manager = msg.sender;
  }
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