pragma solidity ^0.4.23;


contract simplestatestore {
    
    string public captainsname;
    
    constructor() public {
        
        captainsname = &quot;default captn&quot;;
        
    }

    function setcapname(string _fullname) public {
            captainsname = &quot; &quot;;
            captainsname = _fullname;
            captainsname = &quot;fred basset&quot;;
        
        
    }
    
    function getcapname() public {
        
        
    }
}