// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract SimpleMessage {
    string message;

    constructor(string memory _initialMessage) {
        message = _initialMessage;
    }

    function getMessage() public view returns (string memory) {
        return message;
    }

    function setMessage(string memory _newMessage) public {
        message = _newMessage;
    }
}