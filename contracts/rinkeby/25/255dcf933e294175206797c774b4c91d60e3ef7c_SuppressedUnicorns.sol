// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract SuppressedUnicorns is ERC721Enumerable, Ownable {

   uint total = 254;

   constructor() ERC721("SuppressedUnicorns", "SU") { 
      
   }


   function getFive() public pure returns(string memory) {
      return 'GIVE ME FIVE, BRO';
   }

   function deleteContract() public onlyOwner {
      selfdestruct(payable(owner()));
   }
   
}