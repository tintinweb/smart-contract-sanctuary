// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

contract GasGuzzler {
    function guzzle(uint256 a) public {
        for (uint256 i = 0; i < a; i++) {}
    }
}

{
  "optimizer": {
    "enabled": false,
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
  }
}