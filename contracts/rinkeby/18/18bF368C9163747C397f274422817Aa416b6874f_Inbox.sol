/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

pragma solidity >= 0.8.0 <0.9.0;

contract Inbox {
    string public message;

    constructor(string memory initialMessage){
        message = initialMessage;
    }

    function setMessage(string memory newMessage) public {
        message = newMessage;
    }
}