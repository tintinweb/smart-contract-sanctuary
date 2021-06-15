// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ImplementationV3 {
    uint256 public num;
    address public owner;
    uint256 public anotherNum;
    
    constructor() {
        owner = msg.sender;
    }
    
    function increment(uint256 _num) public {
        anotherNum += _num;
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
  },
  "libraries": {}
}