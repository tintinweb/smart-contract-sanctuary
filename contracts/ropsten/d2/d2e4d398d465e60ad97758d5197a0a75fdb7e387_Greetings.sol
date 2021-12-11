/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;
contract Greetings { 
    string public message; 
    event SetMessage(string _message);
    constructor(string memory _initialMessage) {
        
        message = _initialMessage; 
    } 
    function setMessage(string memory _newMessage) public {
        message = _newMessage; 
        emit SetMessage(_newMessage);
    }
}