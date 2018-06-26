pragma solidity ^0.4.24;

contract TestReturnValues {
 
    string message = &quot;&quot;;
    
    function retrunError() public {
        message = &quot;I&#39;m an error message&quot;;
        require(false, message);
    }   
}