// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract Baseball {
  uint public number;

  constructor(uint _initNumber) {
    number = _initNumber;
  }

  function updateNumber(uint _newNumber) external {
    number = _newNumber;
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
    "enabled": true,
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