pragma solidity 0.7.4;

contract HelloWorld {
    string public message;
    
    constructor(string memory initialMessage) public {
        message = initialMessage;
    }
    
    function updateMessage(string memory newMessage) public {
        message = newMessage;
    }
}