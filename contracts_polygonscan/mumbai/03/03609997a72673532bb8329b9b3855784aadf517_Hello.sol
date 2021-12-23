/**
 *Submitted for verification at polygonscan.com on 2021-12-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.7.0 <0.9.0;

contract Hello{
    string public message;

    constructor(string memory _newMessage){
        message = _newMessage;
    }

    function getMessage()public view returns(string memory){
        return message;
    }
}