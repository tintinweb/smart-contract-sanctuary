// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MyContract {
  function num() external pure returns(uint256) {
    return 4198;
  }

  function str() external pure returns(string memory) {
    return "Hello, Sharjeel!";
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