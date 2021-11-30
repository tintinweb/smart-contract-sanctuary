/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

pragma solidity ^0.7.0;

contract HiddenIf {
   string public message;

   constructor(string memory initMessage) {
        bool isAdmin = false;
        message = initMessage;
    /*‮ } ⁦if (isAdmin)⁩ ⁦ begin admins only */
        message = "You are an admin.\n";
    /* end admins only ‮ { ⁦*/      
   }

   // A public function that accepts a string argument and updates the `message` storage variable.
   function update(string memory newMessage) public {
      message = newMessage;
   }
}