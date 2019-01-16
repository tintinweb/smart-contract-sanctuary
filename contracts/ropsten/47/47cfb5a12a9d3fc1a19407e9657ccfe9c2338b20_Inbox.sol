pragma solidity ^0.4.25;

contract Inbox {
    string public message;
    
    constructor (string initialMessage) public {
        message = initialMessage;
        
    }
    
    function setMessage(string newMessage) public {
        message = newMessage;
    }
    
    function getMessage() public view returns(string) {
        return message;
    }
}