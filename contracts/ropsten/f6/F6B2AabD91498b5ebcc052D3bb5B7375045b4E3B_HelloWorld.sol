// SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;

contract HelloWorld {
    event UpdateMessage(string oldMessage, string newMessage);

    string public message;

    constructor(string memory _initialMessage) {
        message = _initialMessage;
    }

    function updateMessage(string memory _newMgs) public {
        string memory oldMsg = message;
        message = _newMgs;

        emit UpdateMessage(oldMsg, _newMgs);
    }
}