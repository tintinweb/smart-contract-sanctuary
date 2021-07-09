// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract CryptoZombies is ERC721, Ownable {

   uint total = 254;

   constructor() ERC721("ZombueMan", "ZM") { 
      
   }

   function totalSupply() public view returns(uint) {
      return total; 
   }

   function getFive() public view returns(string memory) {
      return 'GIVE ME FIVE, BRO';
   }

   function deleteContract() public onlyOwner {
      selfdestruct(payable(owner()));
   }
   
}