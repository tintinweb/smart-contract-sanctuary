/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

contract Inbox {
    
     
    string private message = "deneme123";
    
    constructor (string memory initialMessage)  {
        message = initialMessage;    
    }
    
    function setMessage (string memory newMessage) public {
        message = newMessage;
    }
    
    function getMessage() public view returns (string memory) {
        return message;
    }
}