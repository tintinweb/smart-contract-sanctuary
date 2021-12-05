/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract HelloWorld {
    
   string public message;

   constructor(string memory initMessage) {
         message = initMessage;
   }
  
   function update(string memory newMessage) public {
      message = newMessage;
   }
}