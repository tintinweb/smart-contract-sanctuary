/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0;

contract Inbox {
    string public message;

    constructor(string memory initialMessage){
        message = initialMessage;
    }
    
    function setMessage(string memory newMessage) public {
        message = newMessage;
    }
}