/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.3;

contract HelloWorld {

    event UpdateMessages(string oldStr, string newStr);
    string public message;

    constructor(string memory initMessage){
        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdateMessages(oldMsg, newMessage);
    }

}