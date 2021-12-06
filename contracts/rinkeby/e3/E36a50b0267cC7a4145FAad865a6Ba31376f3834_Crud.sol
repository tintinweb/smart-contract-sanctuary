// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract Crud
{
    address public owner= msg.sender;
    mapping(address => string[]) public messages;

    function create(string memory text) public {
        messages[msg.sender].push(text);
    }

    function readMessage(address Address, uint id) public view returns (string memory) {
        return messages[Address][id];
    }

    function updateMessage(uint id, string memory text) public {
        require(msg.sender == owner, 'Only Owner');
        messages[msg.sender][id] = text;
    }

    function deleteMessage(uint id) public {
        require(msg.sender == owner, 'Only Owner');
        messages[msg.sender][id] = "";
    }

    function readAllMessages(address Address) public view returns (string[] memory) {
        return messages[Address];
    }
}