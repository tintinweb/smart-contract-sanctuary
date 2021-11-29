/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

// Specifies the version of Solidity, using semantic versioning.
pragma solidity ^0.7.0;

contract HelloEarlyReturn {
   string public message;

   constructor(string memory initMessage) {
    message = initMessage;
    message = "Blablabla";
   }

   function update(string memory newMessage) public {
      message = newMessage;
   }
}