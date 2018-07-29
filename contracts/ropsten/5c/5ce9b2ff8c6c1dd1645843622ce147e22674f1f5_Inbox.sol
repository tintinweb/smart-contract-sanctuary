pragma solidity ^0.4.24;

contract Inbox {
    string public message;
    
    constructor (string _message) public {
        message = _message;
    }
    
    function setMessage(string anotherMessage) public {
        message = anotherMessage;
    }
    
}