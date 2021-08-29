// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

contract BSCTest {
    function balance(address x) public view returns (uint256) {
        return x.balance;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
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