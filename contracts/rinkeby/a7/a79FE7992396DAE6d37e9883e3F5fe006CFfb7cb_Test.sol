/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;


abstract contract ERC1271 {
   
}

contract Test {
    
    constructor(uint x1, uint x2) public {
       
    }

    function _registerStandard(bytes4 _interfaceId) internal {
        
    }

    function initialize() public {
        uint x = 2828285;
        _registerStandard(type(ERC1271).interfaceId); 
    } 
}


contract Test2 {
    address public base;

    constructor() public {
       base = address(new Test(10, 20));
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 20000
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}