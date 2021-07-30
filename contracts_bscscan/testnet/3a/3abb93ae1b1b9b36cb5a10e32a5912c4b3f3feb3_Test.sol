/**
 *Submitted for verification at BscScan.com on 2021-07-29
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;


contract Test {
    address[] public items;
  
   constructor() public {
     setItems(); 
  }  
  
  function getItems() public view returns (address[] memory) {
      return items;
  }
  
  function setItems() public {
      for (uint256 i = 0; i < 100; i++) {
          items.push(address(0xb0462911f2d4B5993000C493F5C261Bd55303664));
      }
  }
  
  
}