// SPDX-License-Identifier: MIT
pragma solidity >=0.6 <0.7.0;

/// @dev Placeholder-contract for further upgrades
contract MockImplementation {
    constructor() public { }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {
    "": {}
  },
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