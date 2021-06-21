// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Modifier {
  address owner;
  uint256 public value = 42;

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender == owner) {
      _;
    }
  }

  function updateValue(uint256 _value) external onlyOwner() {
    value = _value;
  }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
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