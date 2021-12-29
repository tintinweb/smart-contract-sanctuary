/**
 *Submitted for verification at Etherscan.io on 2021-12-27
*/

pragma solidity >=0.7.3;

contract MessageList {

   event MessageAdded(address user, string message);

   mapping(address => string[]) public messages;

   function addMessage(string calldata message) public {
      messages[msg.sender].push(message);
      emit MessageAdded(msg.sender, message);
   }
}