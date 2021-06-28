// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


contract VerifyEIP712  {
    uint256 public b; 
    constructor() {
        b = 3;
    }
    
    bytes32 constant public IDENTITY_TYPEHASH = keccak256("Identity(uint256 userId,address wallet)");
    bytes32 constant public BIDDER_TYPEHASH = keccak256("Bidder(uint256 amount,Identity bidder");
    
    // function hashStruct() {
        
    // }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
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