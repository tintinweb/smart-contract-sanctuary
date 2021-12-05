/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

pragma solidity >=0.5.8 <0.7.0;

contract HelloWorld {
   string public message;

   constructor(string memory initMessage) public {
       message = initMessage;
   }

   function update(string memory newMessage) public {
       message = newMessage;
   }
}