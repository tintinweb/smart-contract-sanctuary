/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

contract Message {
    
    string message = "Hello World!";
    
    event SetMessageEvent(string message);

    function getMessage() public view returns (string memory) {
        return message;
    }
    
    function setMessage(string memory newMessage) public {
        message = newMessage;
        emit SetMessageEvent(newMessage);
    }

}