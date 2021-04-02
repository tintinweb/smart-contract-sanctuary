/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

pragma solidity ^0.4.17;

contract Inbox{

string public message;

function setMessage(string newMessage) public {

message = newMessage;

}

}