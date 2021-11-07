/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BrainFuck {
    string public message;
    address owner;
    
    constructor() {
        owner = msg.sender;    
    }
    
    function setMessage(string calldata _message) external {
        require(msg.sender == owner, "Only a Metanaut can change the message");
        message = _message;
    }
    
}