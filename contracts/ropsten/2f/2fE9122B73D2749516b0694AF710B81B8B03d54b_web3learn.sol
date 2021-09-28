pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED
//@dev Tariq Saeed

contract web3learn {
    
    string owner;
    
    function setOwner(string memory _owner) public {
        
        owner = _owner;
    }
    
    function getOwner() external view returns (string memory) {
        return owner;
        
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