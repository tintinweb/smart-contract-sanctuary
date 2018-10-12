pragma solidity ^0.4.10;

contract Bad {
    
    function failWithReason(string reason) public {
        require(false, reason);
    }
    
   function fail() public {
        require(false, "bad news...");
    }
    
   function failWithoutReason() public {
        require(false);
    }
    
    function callAndFailWithoutReason() public {
        failWithoutReason();
    }
    
    function callAndFail() public {
        fail();
    }
    
    function callAndFailWithDivisionByZero() public {
        divisionByZero();
    }
    
    function divisionByZero() public {
       uint a = 20;
       uint b = 0;
       uint c = a / b;
    }
}