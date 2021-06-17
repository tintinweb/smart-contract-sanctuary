/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

pragma solidity ^0.6.0;

contract Inbox {
    string public message;
    
    constructor(string memory initialMessage) public {
        message= initialMessage;
    }
    
    function setMessage(string memory newMessage) public{
        message= newMessage;
    }
    
    function getMessage()public view returns (string memory){
        return message;
    }
}