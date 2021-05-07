// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

// This is a black hole contract address
// no one can transfer MDX from the contract
contract BlackHole {}

{
  "optimizer": {
    "enabled": true,
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