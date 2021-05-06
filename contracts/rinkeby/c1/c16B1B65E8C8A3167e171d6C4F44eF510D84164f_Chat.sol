/**
 *Submitted for verification at Etherscan.io on 2021-05-05
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
  

  mapping(address => string) public registeredAddresses;
  
  event NewMessage(address sender, string name, string message, uint timestamp);
  
  function addMessage (string memory _message) public returns(bool) {
      emit NewMessage(msg.sender, registeredAddresses[msg.sender], _message, block.timestamp);
      return true;
  }
  
  
  function register(string memory _name) public payable returns(bool) {
      require(msg.value == 0x11C37937E08000, "msg.value incorrect");
      registeredAddresses[msg.sender] = _name;
      return true;
    }
}