/**
 *Submitted for verification at polygonscan.com on 2022-01-17
*/

// SPDX-License-Identifier: MIT 
pragma solidity >= 0.7.3;

contract hello {
    event updatedMessage(string prevName, string newName);
    string public message;
    constructor(string memory initMessage){
        message = initMessage;
    }

    function updateMessage(string memory newMessage) public {
       
        string memory prevName = message;
        message = newMessage;
        emit updatedMessage(prevName , newMessage);
    }
}