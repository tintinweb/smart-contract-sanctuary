pragma solidity ^0.8.0;



library mylib { 
    struct Data {
        mapping(uint => bool) flags;
    }
    function doTrue(Data storage self,uint256 value) public returns(bool){
        self.flags[value]=true;
        return true;
    }
    function doFalse(Data storage self,uint256 value) public returns(bool){
        self.flags[value]=false;
        return false;
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
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