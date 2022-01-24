/**
 *Submitted for verification at polygonscan.com on 2022-01-23
*/

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity >=0.7.3;

contract HelloWorld {

   event UpdatedMessages(string oldStr, string newStr);

   string public message;

   constructor(string memory initMessage) {
      message = initMessage;
   }

   function update(string memory newMessage) public {
      string memory oldMsg = message;
      message = newMessage;
      emit UpdatedMessages(oldMsg, newMessage);
   }
}