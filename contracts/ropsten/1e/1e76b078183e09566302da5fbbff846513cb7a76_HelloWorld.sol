/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract HelloWorld {
    event UpdatedMessage(string oldStr, string newStr);
    string public message;
    constructor(string memory initMessage) {
        message = initMessage;
    }
    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessage(oldMsg, newMessage);
    }
}