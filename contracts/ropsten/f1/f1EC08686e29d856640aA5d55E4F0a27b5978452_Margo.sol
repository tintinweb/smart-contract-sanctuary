/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

pragma solidity ^0.7.0;
contract Margo {
   string public message;
   constructor(string memory initMessage) {
      message = initMessage;
   }
   function update(string memory newMessage) public {
      message = newMessage;
   }
}