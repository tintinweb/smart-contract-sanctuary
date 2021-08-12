// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

contract StarterContract {
    string public author = "atsignhandle";
    string public contract_argument;   
    constructor(string memory _contract_argument) {
        contract_argument = _contract_argument;
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