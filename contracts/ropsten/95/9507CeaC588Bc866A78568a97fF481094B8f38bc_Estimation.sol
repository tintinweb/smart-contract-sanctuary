pragma solidity ^0.8.6;

contract Estimation {                        

    uint256 public var1 = 10;           
    uint256 internal var2 = 10;
    uint256 private var3 = 10;

    function addToVar1 () public returns (uint256) { 
        var1+=1;
        return var1;
    }
    
    function addToVar2 () public returns (uint256) { 
        var2+=1;
        return var2;
    }
    
    function addToVar3 () public returns (uint256) { 
        var3+=1;
        return var3;
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