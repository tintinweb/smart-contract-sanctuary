// SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;

contract HelloWorld {
    event UpdatedMessages(string oldString, string newString);

    string public message;

    constructor(string memory initMsg) {
        message = initMsg;
    }

    function updateMsg(string memory newMsg) public {
        string memory oldMsg = message;
        message = newMsg;
        emit UpdatedMessages(oldMsg, newMsg);
    }
}