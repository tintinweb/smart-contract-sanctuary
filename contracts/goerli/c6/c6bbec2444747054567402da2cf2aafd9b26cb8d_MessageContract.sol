/**
 *Submitted for verification at Etherscan.io on 2021-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
    
// A simple smart contract
contract MessageContract {
    string message = "Hello World";
    
    function getMessage() public view returns(string memory) {
        return message;
    }
    
    function setMessage(string memory newMessage) public {
        message = newMessage;
    }
}