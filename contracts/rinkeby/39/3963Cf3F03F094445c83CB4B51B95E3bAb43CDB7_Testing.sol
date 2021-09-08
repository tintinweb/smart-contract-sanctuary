// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;



contract Testing {
    
    
    function hm() public view returns (string memory) {
    return('ho');
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