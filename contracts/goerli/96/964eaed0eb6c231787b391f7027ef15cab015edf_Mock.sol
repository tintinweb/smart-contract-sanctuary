// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Mock {
    uint private constant _number = 123456; 
    
    function getConstant() public pure returns(uint) {
        return _number;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
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