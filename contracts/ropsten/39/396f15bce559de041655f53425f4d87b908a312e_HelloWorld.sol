/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;

contract HelloWorld {
    string private message;
    
    function getMessage() public view returns (string memory) {
        return message;
    }
    
    function setMessage(string memory newMessage) public {
        message = newMessage;
    }
}