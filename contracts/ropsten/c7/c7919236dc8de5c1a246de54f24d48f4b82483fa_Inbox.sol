pragma solidity 0.4.24;

contract Inbox
{
    
    string public message;
    
    constructor(string _msg) public {
        message = _msg;
    }
    
    function setMessage(string _msg) public {
        message = _msg;
    }
    
    
}