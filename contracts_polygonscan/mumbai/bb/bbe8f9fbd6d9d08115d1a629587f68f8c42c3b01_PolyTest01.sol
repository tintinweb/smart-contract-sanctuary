/**
 *Submitted for verification at polygonscan.com on 2021-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PolyTest01{
    
    string public message;
    
    constructor(string memory initMessage)public{
        message = initMessage;
    }
    
    function update(string memory newMessage)public{
        message = newMessage;
    }
}