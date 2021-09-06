// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Testing {
    constructor() {}
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
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