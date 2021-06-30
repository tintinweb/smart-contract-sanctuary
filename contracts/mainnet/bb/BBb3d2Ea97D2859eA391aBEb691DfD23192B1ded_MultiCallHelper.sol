// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

contract MultiCallHelper {
  fallback () external payable {
    assembly {
      for { let ptr := 0 } lt(ptr, calldatasize()) {} {
        let to := calldataload(ptr)
        ptr := add(ptr, 32)

        let value := calldataload(ptr)
        ptr := add(ptr, 32)

        let inSize := calldataload(ptr)
        ptr := add(ptr, 32)

        calldatacopy(0, ptr, inSize)
        ptr := add(ptr, inSize)

        let success := call(gas(), to, value, 0, inSize, 0, 0)
        if iszero(success) {
          returndatacopy(0, 0, returndatasize())
          revert(0, returndatasize())
        }
      }
      stop()
    }
  }
}

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "none"
  },
  "optimizer": {
    "details": {
      "constantOptimizer": true,
      "cse": true,
      "deduplicate": true,
      "jumpdestRemover": true,
      "orderLiterals": false,
      "peephole": true,
      "yul": false
    },
    "runs": 256
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