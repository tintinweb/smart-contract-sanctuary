/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract CafeteriaContract {
    string public message;
    string public food;
    event messageSet(string _message);
    
    constructor () {
        message = "hello world123";
        food = "pizza";
    }
    
    function setMessage(string memory newMessage, string memory newFood) public {
        message = newMessage;
        food = newFood;
        emit messageSet(newMessage);
    }
}