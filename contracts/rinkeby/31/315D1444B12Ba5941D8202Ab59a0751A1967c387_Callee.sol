// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Callee {
    uint[] public values;

    function getValue(uint initial) public {
      
    }
    function storeValue(uint value) public {

    }
    function getValues() public {
  
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
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