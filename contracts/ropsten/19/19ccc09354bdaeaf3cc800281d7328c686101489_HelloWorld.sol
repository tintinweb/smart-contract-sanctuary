// SPDX-License-Identifier: MIT

pragma solidity >=0.7.3;

contract HelloWorld {

   string public message;
   event UpdatedMessages(string oldStr, string newStr);

   constructor(string memory initMessage) {
      message = initMessage;
   }

   function update(string memory newMessage) public {
      string memory oldMsg = message;
      message = newMessage;
      emit UpdatedMessages(oldMsg, newMessage);
   }
}