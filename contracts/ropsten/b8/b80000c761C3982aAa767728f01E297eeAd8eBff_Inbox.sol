/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Inbox { 

    string public message;

    string public creatorName;

    address public creator;

    constructor() {
        message = "it's alive!";
        creator = msg.sender;
        creatorName = "g14";
    }

    function setMessage(string memory newMessage) public {
        message = newMessage;
    }
    
}