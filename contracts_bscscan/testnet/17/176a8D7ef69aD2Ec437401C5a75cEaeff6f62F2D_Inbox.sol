/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

pragma solidity ^0.8.11;

contract Inbox {
    string public message;
    
    constructor(string memory initialMessage) {
        message = initialMessage;
    }
    
    function setMessage(string memory newMessage) public {
        message = newMessage;
    }

    function getMessage() public view returns (string memory) {
       return message;
    }
}