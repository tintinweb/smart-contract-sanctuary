/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

// SPDX-License-Identifier: GPL-3.0

//pragma solidity >=0.7.0 <0.9.0;
pragma solidity ^0.4.17;

contract Inbox{
    string public message;
    function Inbox(string initialMessage) public {
        message = initialMessage;
    }
    
    function setMessage(string newMessage) public {
        message = newMessage;
    }
    
    function getMessage() public view returns (string){
        return message;
    }
}