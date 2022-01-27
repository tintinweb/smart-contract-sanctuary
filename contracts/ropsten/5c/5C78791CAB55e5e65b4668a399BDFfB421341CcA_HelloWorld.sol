// SPDX-License-Identifier: MIT

pragma solidity >=0.7.3;

contract HelloWorld {
    event UpdatedMessages(string prev, string next);

    string public message;

    constructor(string memory initMessage) {
        message = initMessage;
    }

    function update(string memory nextMessage) public {
        string memory prevMessage = message;
        message = nextMessage;
        emit UpdatedMessages(prevMessage, nextMessage);
    }
}