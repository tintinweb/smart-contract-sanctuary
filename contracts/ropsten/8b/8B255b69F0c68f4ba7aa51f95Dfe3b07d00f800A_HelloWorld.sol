// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.3;


contract HelloWorld {
    event UpdatedMessages(string oldStr, string newStr);

    string public message;

    constructor(string memory _initMessage) {
        message = _initMessage;
    }

    function updateMessage(string memory _newMessage) public {
        string memory oldMessage = message;
        message = _newMessage;
        emit UpdatedMessages(oldMessage, _newMessage);
    }

}