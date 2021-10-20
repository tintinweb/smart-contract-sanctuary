// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Inbox {
    string public message;

    constructor(string memory _init) {
        message = _init;
    }

    function setMessage(string memory _new) public {
        message = _new;
    }
}