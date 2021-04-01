/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

pragma solidity 0.8.3;

contract HelloWorld {
    string public message;

    constructor(string memory initialMessage) {
        message = initialMessage;
    }

    function updateMessage(string memory newMessage) public {
        message = newMessage;
    }
}