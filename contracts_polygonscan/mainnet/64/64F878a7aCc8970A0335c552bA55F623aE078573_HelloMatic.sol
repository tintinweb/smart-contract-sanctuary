/**
 *Submitted for verification at polygonscan.com on 2021-08-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract HelloMatic {
    string public name = "Hello Matic";
    string public message;

    constructor(string memory _message) {
        message = _message;
    }

    function update(string memory _message) public {
        message = _message;
    }
}