/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

pragma solidity 0.5.10;

contract HelloWorld {

   string public message;

   constructor(string memory initMessage) public {
      message = initMessage;
   }

   function update(string memory newMessage) public {
      message = newMessage;
      }
}