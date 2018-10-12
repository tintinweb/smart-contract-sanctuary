pragma solidity ^0.4.10;

contract Bad {
    
    function failWithReason(string reason) public {
        require(false, reason);
    }
    
   function justFailRequire() public {
        require(false, "bad news...");
    }
    
   function divisionByZero() public {
       uint a = 20;
       uint b = 0;
       uint c = a / b;
    }
}