/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

//SPDX-License-Identifier: MIT
pragma solidity >= 0.7.3;

contract HelloWorld{
    event UpdateMessages(string oldStr, string newStr);

    string public message;

    constructor (string memory initMessage){
        message = initMessage;
    }

    function update(string memory newMessage) public{
        string memory oldMsg = message;
        message = newMessage;
        emit UpdateMessages(oldMsg, newMessage);
    }
}