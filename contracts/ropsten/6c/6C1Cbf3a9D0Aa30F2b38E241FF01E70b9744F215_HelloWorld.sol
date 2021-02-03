// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.5.10;

contract HelloWorld {
    string public message;
    constructor(string memory initMessage) public {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        message = newMessage;
    }
}