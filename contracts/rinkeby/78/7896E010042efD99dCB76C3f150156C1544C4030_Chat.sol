/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
/// @title Voting with delegation.

contract Chat{

  struct Message  {
      address sender;
      string name;
      string message;
      uint timestamp;
  }
  
  struct User {
      address accountAddress;
      string userName;
      string status;
  }
  
  
  
  Message[] public messages;
  User[] public users;
  uint public messagesLength;
  
  event NewMessage(address sender, string name, string message, uint timestamp);
  
  function addMessage (string memory _name, string memory _message) public returns(bool) {
      messages.push(Message(msg.sender, _name, _message, block.timestamp));
      messagesLength = messages.length;
      emit NewMessage(msg.sender, _name, _message, block.timestamp);
      return true;
  }
  
  
  function register(string memory _name) public payable {
      require(msg.value == 0x11C37937E08000, "msg.value incorrect");
      users.push(User(msg.sender, _name, 'premium'));
 
  }
  
 
 
  
  
}