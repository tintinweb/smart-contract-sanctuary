// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";

contract CryptoZombies is ERC721 {

   uint total = 254;

   constructor() ERC721("GameItem", "ITM") { 
      
   }

   function totalSupply() public view returns(uint) {
      return total; 
   }
   
}