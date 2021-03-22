/**
 *Submitted for verification at Etherscan.io on 2021-03-21
*/

pragma solidity =0.6.6;

contract Inbox {
    string public message;

    constructor(string memory initialMessage) public {
        message = initialMessage;
    }

    function setMessage(string memory newMessage) public {
        message = newMessage;
    }
}