// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0 < 0.9.0;

contract Number {

  uint public mainNumber;

  event NumberChanged(address indexed caller, uint newNumber);

  constructor() {}

  function incrementNumber() external {
    mainNumber += 1;
    emit NumberChanged(msg.sender, mainNumber);
  }
}

{
  "metadata": {
    "bytecodeHash": "none"
  },
  "optimizer": {
    "enabled": true,
    "runs": 800
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