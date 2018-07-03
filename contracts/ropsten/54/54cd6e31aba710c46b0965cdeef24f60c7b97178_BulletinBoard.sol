pragma solidity ^0.4.24;

contract BulletinBoard {

    struct Message {
        address sender;
        string text;
        uint block_timestamp;
    }

    Message[] public messages;
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    function addMessage(string text) public payable {
        require(msg.value >= 0.000001 ether * bytes(text).length);
        messages.push(Message(msg.sender, text, block.timestamp));
    }

    function numMessages() public constant returns (uint) {
        return messages.length;
    }
    
    function withdraw() public {
        require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
    }
}