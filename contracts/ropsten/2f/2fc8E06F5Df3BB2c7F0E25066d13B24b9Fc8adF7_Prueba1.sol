// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.3;

contract Prueba1 {
    event UpdateMessages(string oldStr, string newStr);

    string public message;

    constructor (string memory initMessage) {
        message = initMessage;
    }

    function setMessage(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdateMessages(oldMsg, message);
    }
}