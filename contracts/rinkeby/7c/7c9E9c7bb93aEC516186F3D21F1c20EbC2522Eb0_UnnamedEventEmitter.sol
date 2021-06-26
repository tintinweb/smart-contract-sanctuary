// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract UnnamedEventEmitter {
  constructor() {}

  uint256 constant MAX_UINT256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

  function create(uint256 n) public {
    assembly {
      for { } gt(n, 0) { } {
        log0(0,0)
        n := add(n, MAX_UINT256)
      }
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
    "enabled": true,
    "runs": 1000000
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