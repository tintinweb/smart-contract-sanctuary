/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

/**
 * SPDX-License-Identifier: MIT
 */
 
pragma solidity ^0.4.17;

contract Inbox {
    string public message;
    
    
    function Inbox(string initialMessage) public {
        message = initialMessage;
    }
    
    function setMessage(string newMessage) public {
        message = newMessage;
    }
    
}