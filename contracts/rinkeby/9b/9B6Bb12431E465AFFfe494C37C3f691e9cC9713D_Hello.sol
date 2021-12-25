/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

// hello.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Hello {
    string public message;

    constructor() {
        message = "Hello, World!";
    }

    function set_message(string calldata _message) public {
        message = _message;
    }
}