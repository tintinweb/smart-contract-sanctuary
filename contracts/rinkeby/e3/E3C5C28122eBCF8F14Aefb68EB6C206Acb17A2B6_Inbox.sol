/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.6 <0.9.0;

contract Inbox{
    string public message;

    constructor(string memory initialValue){
        message = initialValue;
    }

    function setMessage(string memory newMessage) public{
        message=newMessage;
    }

     // function getMessage() public view returns(string memory){
    //     return message;
    // }
}