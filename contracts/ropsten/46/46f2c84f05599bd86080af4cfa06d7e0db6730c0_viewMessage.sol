pragma solidity ^0.4.18;

contract viewMessage{
    string message;
    constructor() public {
        message = "This is the initial Message";
    }
    
    
    function setNewMessage(string newMsg) public payable
    {
        //msg.value is a special variable that holds the number of wei sent with the transaction (gas is counted separately)
        message = newMsg;
        
    }
    
    function getMessage() constant public returns (string)
    {
        return message;
    }
    
    
}