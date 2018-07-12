pragma solidity 0.4.24;

contract Linked {
    // The structure of a message
    struct Message {
        string content;
        uint256 timestamp;
    }

    // All the messages ever written
    Message[] public messages;

    function writeMessage(string _content) public {
        Message memory message = Message(_content, now);
        messages.push(message);
    }
}