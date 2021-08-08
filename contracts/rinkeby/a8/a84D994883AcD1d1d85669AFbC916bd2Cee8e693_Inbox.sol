/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.4.26;



// File: Inbox.sol

contract Inbox {
    string public message;
    
    function Inbox(string initialMessage) public {
        message = initialMessage;
    }
    
    function setMessage(string newMessage) public {
        message = newMessage;
    }
}