// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Token {
    string public name;

    constructor (string memory _name) {
        name = _name;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "london",
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