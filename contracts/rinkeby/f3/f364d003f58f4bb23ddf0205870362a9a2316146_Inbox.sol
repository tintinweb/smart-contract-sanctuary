/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Inbox {
    string public message;
    
    constructor(string memory initialMessage){
        message = initialMessage;
    }
    
    function setMessage(string memory newMessage) public{
        message= newMessage;
    }
    
    function getMessage() public view returns (string memory){
        return message;
    }
    
}