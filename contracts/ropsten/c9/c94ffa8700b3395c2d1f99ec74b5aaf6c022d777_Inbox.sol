/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

pragma solidity ^0.4.17;

contract Inbox {
    string public message;
    
    function Inbox(string initialMessage) public { //constuctor function called at the same time the contract goes live. NOTICE the name is the same as the contract
        message = initialMessage;
    }
    
    function setMessage(string newMessage) public {
        message = newMessage;
    }

}