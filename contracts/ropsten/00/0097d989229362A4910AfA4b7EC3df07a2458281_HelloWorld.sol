/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#prag

pragma solidity ^0.8.0;

contract HelloWorld {

    string public message;

    event UpdatedMessages(string oldStr, string newStr);

    constructor(string memory initMessage)  {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }
}