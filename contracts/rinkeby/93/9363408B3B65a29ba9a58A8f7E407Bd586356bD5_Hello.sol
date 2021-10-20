// contracts/Hello.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Hello {
    string public message;
    uint public counter;

    constructor() {
        counter = 0;
        message = "";
    }

    function updateMessage(string memory newMessage) public {
        ++counter;
        message = newMessage;
    }
}