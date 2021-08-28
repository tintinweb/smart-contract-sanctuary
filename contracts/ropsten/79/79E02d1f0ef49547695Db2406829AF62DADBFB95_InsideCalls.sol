pragma solidity ^0.8.6;

contract InsideCalls {
    uint256 public var1; 
    uint256 public var2; 
    uint256 public var3; 
        
    function firstType() public {
        for (uint i=0; i<50; i++)
            var1 += 1;
    }
    
    function secondType() internal { 
        for (uint i=0; i<50; i++)
            var2 += 1;
    }
    
    function thirdType() private { 
        for (uint i=0; i<50; i++)
            var3 += 1;
    }
    
     function publicCall() public {    
        firstType();
    }

    function internalCall() public {    
        secondType();
    }

    function privateCall() public {   
        thirdType();
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