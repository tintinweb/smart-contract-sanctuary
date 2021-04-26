/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MessagesApp {
    struct Message{
        string id;
        string title;
        string text;
    }

    Message[] public messages;

    function createMessage(string memory id, string memory title, string memory text) public {
        messages.push(Message(id,title,text));
    }

    function listMessages() public view returns (Message[] memory){
        return messages;
    }

    function updateMessage(string memory id, string memory title, string memory text, uint256 index) public {
        messages[index] = Message(id,title,text);
    }

    function deleteMessage(uint256 index) public {
        delete messages[index];
    }
}