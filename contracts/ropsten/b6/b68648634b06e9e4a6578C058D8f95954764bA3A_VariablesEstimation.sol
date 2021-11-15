pragma solidity ^0.8.6;

contract VariablesEstimation {  
    //исследование газа при разной видимости переменных                      
    uint256 public var1;           
    uint256 internal var2;
    uint256 private var3;
    
    function addToVar1() public { 
        for (uint i=0; i<30; i++)
            var1 += 1;
    }
    
    function addToVar2() public {
        for (uint i=0; i<30; i++)
            var2 += 1;
    }
    
    function addToVar3() public {
        for (uint i=0; i<30; i++)
            var3 += 1;
    }
}


contract OutsideCalls {
    //исследование газа при вызовах снаружи
    uint256 public var1;  
    uint256 public var2;
    
    function firstType() public {
        for (uint i=0; i<40; i++)
            var1 += 1;
    }
    
    function secondType() external { 
        for (uint i=0; i<40; i++)
            var2 += 1;
    }
}


contract InsideCalls {
    //исследование газа при вызовах внутри контракта
    uint256 public var1; 
    uint256 public var2; 
    uint256 public var3; 
        
    function publicType() public {
        for (uint i=0; i<30; i++)
            var1 += 1;
    }
    
    function internalType() internal { 
        for (uint i=0; i<30; i++)
            var2 += 1;
    }
    
    function privateType() private { 
        for (uint i=0; i<30; i++)
            var3 += 1;
    }
    
    function firstCalling() public {    
        publicType();
    }

    function thirdCalling() public {    
        internalType();
    }

    function fourthCalling() public {   
        privateType();
    }
}

