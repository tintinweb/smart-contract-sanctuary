// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Test {
    function get() public view  returns (uint256) {
        return block.timestamp;
    }
}

{
  "evmVersion": "london",
  "metadata": {
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": false,
    "runs": 200
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