/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

pragma solidity ^0.6.0;

contract HelloWorld {

    event UpdatedMessages(string oldStr, string newStr);

    string public message;

    constructor(string memory initMessage) public {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }
}