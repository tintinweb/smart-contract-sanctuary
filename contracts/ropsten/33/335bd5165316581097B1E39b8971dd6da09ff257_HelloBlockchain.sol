// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.3;

contract HelloBlockchain {
    event UpdatedMessages(string oldStr, string newStr);

    string public message;

    constructor (string memory initMsg) {
        message = initMsg;
    }

    function update(string memory newMsg) public {
        string memory oldMsg = message;
        message = newMsg;
        emit UpdatedMessages(oldMsg, newMsg);
    }
}