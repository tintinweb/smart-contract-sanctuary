/**
 *Submitted for verification at polygonscan.com on 2021-11-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract HelloWorld {
    string public message;

    constructor(string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        message = newMessage;
    }
}