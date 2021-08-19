/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

//SPDX-License-Identifier:MIT;

pragma solidity ^0.8.7;


 contract Contract{
   // chatapp 
   
   mapping(address => string)  msg_from;
   
   function send_msg(address _to, string memory _message)public {
       msg_from[_to] = _message;
   }
   
   function get_msg()public view returns(string memory){
     return msg_from[msg.sender];
   }
   
   function Reply(address _to, string memory _message)public{
       msg_from[_to] = _message;
   }
}