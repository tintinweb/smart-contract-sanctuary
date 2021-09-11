/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

pragma solidity ^0.8.4;
//SPDX-License-Identifier: MIT Licensed

// contract Inbox {
//  string  public message;

// function Inboxs( string initialmessage) public {
    
//     message  = initialmessage;
// }

// function setMessage (string newMessage) public{
//   message= newMessage;
// }

// }
contract SimpleStorage {
uint storedData;
function set(uint x) public {
storedData = x;
}
function get() public view returns (uint) {
return storedData;
}
}