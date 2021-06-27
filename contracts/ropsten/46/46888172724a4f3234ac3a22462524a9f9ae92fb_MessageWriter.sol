/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MessageWriter {
    
    mapping(uint256 => Message) public message;
    uint public messageIndex = 0;
    address owner;
    
    struct Message {
        uint256 timeStamp;
        string message;
        string name;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function addMessage(string memory _message, string memory _name) public {
        incrementIndex();
        message[messageIndex] = Message(block.timestamp, _message, _name);
    }
    
    function incrementIndex() internal {
        messageIndex += 1;
    }
    
    function addOneSentenceMessage(string memory _message, string memory _name, uint256 _timeStamp) public onlyOwner {
        incrementIndex();
        message[messageIndex] = Message(_timeStamp, _message, _name);
    }    
    
    function viewMessage(uint256 _messageIndex) public view returns(string memory) {
        return message[_messageIndex].message;
    }
    
}