/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

pragma solidity ^0.7.3;

contract HelloWorld {

   string public message;

   constructor(string memory initMessage) {
   
      message = initMessage;
   }

   function update(string memory newMessage) public {
      message = newMessage;
   }
}