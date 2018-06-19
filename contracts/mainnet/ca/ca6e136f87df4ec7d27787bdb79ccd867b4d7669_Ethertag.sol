pragma solidity ^0.4.23;
contract Ethertag {
    address public owner;
    address public thisContract = this;
    uint public minValue;
    uint public maxTextLength;
    message[] public messages;
    
    struct message {
        string text;
        uint value;
        rgb color;
    }
    
    struct rgb {
        uint8 red;
        uint8 green;
        uint8 blue;
    }
    
    event newMessage(uint id, string text, uint value, uint8 red, uint8 green, uint8 blue);
    event newSupport(uint id, uint value);
    
    constructor() public {
        owner = msg.sender;
        minValue = 10000000000000;
        maxTextLength = 200;
    }
    
    function getMessagesCount() public view returns(uint) {
        return messages.length;
    }

    function getMessage(uint i) public view returns(string text, uint value, uint8 red, uint8 green, uint8 blue) {
        require(i<messages.length);
        return (
            messages[i].text, 
            messages[i].value,
            messages[i].color.red,
            messages[i].color.green,
            messages[i].color.blue
            );
    }
  
    function addMessage(string m, uint8 r, uint8 g, uint8 b) public payable {
        require(msg.value >= minValue);
        require(bytes(m).length <= maxTextLength);
        messages.push(message(m, msg.value, rgb(r,g,b)));
        emit newMessage(
            messages.length-1,
            messages[messages.length-1].text, 
            messages[messages.length-1].value, 
            messages[messages.length-1].color.red,
            messages[messages.length-1].color.green,
            messages[messages.length-1].color.blue
            );
    }
    
    function supportMessage(uint i) public payable {
        messages[i].value += msg.value;
        emit newSupport(i, messages[i].value);
    }
   
    function changeSettings(uint newMaxTextLength, uint newMinValue) public {
        require(msg.sender == owner);
        maxTextLength = newMaxTextLength;
        minValue = newMinValue;
    }
    
    function withdraw() public {
        require(msg.sender == owner);
        msg.sender.transfer(thisContract.balance);
    }
}