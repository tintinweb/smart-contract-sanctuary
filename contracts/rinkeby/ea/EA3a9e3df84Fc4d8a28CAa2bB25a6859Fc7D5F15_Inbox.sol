/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

pragma solidity ^0.4.17;

// linter warnings (red underline) about pragma version can igonored!

// contract code will go here
contract Inbox {
    string public message;

    function Inbox(string initialMessage) public {
        message = initialMessage;
    }

    function setMessage(string newMessage) public {
        message = newMessage;
    }
}