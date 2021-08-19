/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

pragma solidity ^0.4.17;

contract Inbox {
    string public message;
    
    function Inbox(string intialMessage) public {
        message = intialMessage;
    }
    
    function setMessage(string newMessage) public {
        message = newMessage;
    }
    
    function getMessage() public view returns (string) {
        return message;
    }
}