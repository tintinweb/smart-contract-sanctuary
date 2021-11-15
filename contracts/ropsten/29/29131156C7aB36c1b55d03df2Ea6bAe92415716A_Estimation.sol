pragma solidity ^0.8.6;

contract Estimation {                        
    uint256 public var1 = 10;           
    uint256 internal var2 = 10;
    uint256 private var3 = 10;
    uint256 public var4 = 1;

    function addToVar1() public { 
        var1 += 1;
    }
    
    function addToVar2() public { 
        var2 += 1;
    }
    
    function addToVar3() public { 
        var3 += 1;
    }
    
    //
    function firstType() public { 
        var4 += 1;
    }
    
    function secondType() external { 
        var4 += 1;
    }
    
    function thirdType() internal { 
        var4 += 1;
    }
    
    function fourthType() private { 
        var4 += 1;
    }
    
    function firstCalling() public {
        firstType();
    }

    function thirdCalling() public {
        thirdType();
    }
    function fourthCalling() public {
        fourthType();
    }
}

