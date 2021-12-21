/**
 *Submitted for verification at polygonscan.com on 2021-12-20
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.7.3;

contract HelloWorld {
    event UpdatedMessage(string oldStr, string newStr);

    string public message;

    constructor(string memory initMessage) {
        message = initMessage;
    }

    function updateMessage(string memory newMessage) public {
        string memory oldMessage = message;
        message = newMessage;
        emit UpdatedMessage(oldMessage, newMessage);
    }
}