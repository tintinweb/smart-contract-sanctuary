/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
/// @title Voting with delegation.

contract Test{

  struct Message  {
      string name;
      string message;
  }
  
  struct User {
      address accountAddress;
      string userName;
      string status;
  }
  
  
  
  Message[] public messages;
  User[] public users;
  event newMessage();
  
  function addMessage (string memory _name, string memory _message) public returns(bool) {
      messages.push(Message(_name, _message));
      emit newMessage();
      return true;
  }
  
  
  function register(string memory _name) public payable {
      require(msg.value == 0x11C37937E08000, "msg.value incorrect");
      users.push(User(msg.sender, _name, 'premium'));
 
  }
  
 
 
  
  
}