pragma solidity ^0.4.18;

contract viewMessagePayable{
    string message;
    string message2;
    address public owner;
    uint amount;

    constructor() public {
        message = "This is the initial Message";
        message2 = "This is the second Initial message";
        owner = msg.sender;
        amount = 0;
    }
    
    
    function setNewMessage(string newMsg) public payable
    {
        
        //msg.value is a special variable that holds the number of wei sent with the transaction (gas is counted separately)
        message = newMsg;
        amount += msg.value;
        
        
    }
    
    function setNewMessage2(string meg) public payable {
        message2 = meg;
        amount += msg.value;
    }
    
    function getMessage() constant public returns (string)
    {
        return message;
    }
    
    
}