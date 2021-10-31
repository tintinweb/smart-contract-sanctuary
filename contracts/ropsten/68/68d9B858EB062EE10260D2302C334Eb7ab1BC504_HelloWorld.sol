// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.3;

contract HelloWorld {
    event UpdatedMessage(string oldStr, string newStr);

    string public message;

    constructor(string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMessage = message;
        message = newMessage;
        emit UpdatedMessage(oldMessage, newMessage);
    }
}