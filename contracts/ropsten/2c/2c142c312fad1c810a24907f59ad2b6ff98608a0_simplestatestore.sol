pragma solidity ^0.4.23;

contract simplestatestore {
    
    string public captainsname;
    
    constructor() public {
        
        captainsname = "default captn";
        
    }

    function setcapname(string _fullname) public {
            captainsname = _fullname;
        
        
    }
    
    function getcapname() public {
        
        
    }
}