/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;
contract Greetings { 
    string public message; 
    constructor(string memory _initialMessage) {
        message = _initialMessage; 
    } 
    function setMessage(string memory _newMessage) public {
        message = _newMessage; 
    }
}