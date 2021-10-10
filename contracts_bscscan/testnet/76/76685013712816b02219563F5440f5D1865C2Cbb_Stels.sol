/**
 *Submitted for verification at BscScan.com on 2021-10-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Stels {

    string private message;

    constructor() {
        message = "Hello Stels";
    }

    function update(string memory newMessage) public {
        message = newMessage;
    }
    
    function getMessage() view public returns (string memory) {
        return message;
    }
}