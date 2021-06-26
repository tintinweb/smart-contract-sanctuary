/**
 *Submitted for verification at Etherscan.io on 2021-06-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MessageWriter {
    
    mapping(uint256 => Message) public message;
    uint public messageIndex = 0;
    
    struct Message {
        uint256 timeStamp;
        string message;
    }
    
    function addMessge(string memory _message) public {
        incrementIndex();
        message[messageIndex] = Message(block.timestamp, _message);
    }
    
    function incrementIndex() internal {
        messageIndex += 1;
    }
    
    function viewMessage(uint256 _messageIndex) public view returns(string memory) {
        return message[_messageIndex].message;
    }
    
}