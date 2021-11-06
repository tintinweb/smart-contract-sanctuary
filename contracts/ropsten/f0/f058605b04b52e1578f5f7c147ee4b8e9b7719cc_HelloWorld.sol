// SPDX-License-Identifier: UNLICENSED

pragma solidity >= 0.7.3;

contract HelloWorld {
    event UpdatedMessages(string oldMessage, string newMessage);

    string public message;

    constructor (string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMessage = message;
        message = newMessage;
        emit UpdatedMessages(oldMessage, newMessage);
    }
}