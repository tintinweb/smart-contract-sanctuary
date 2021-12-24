// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.3;

contract HelloWorld {
    event UpdatedMessages(string oldStr, string newStr);

    // a public variable that anyone can access
    string public message;

    // called only once, during smart contract deployment
    constructor (string memory initMessage) {
        message = initMessage;
    }
    
    function update (string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }


}