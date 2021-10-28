// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.7.3;

contract HelloAlchemy {
    event UpdateMessages(string oldStr, string newStr);

    string private message;

    constructor (string memory initMessage) {
        message = initMessage;
    }

    function getMessage() external view returns(string memory) {
        return message;
    }

    function update(string memory newMessage) external {
        string memory oldMessage = message;
        message = newMessage;
        emit UpdateMessages(oldMessage, newMessage);
    }
}