/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract DanielArsham {
      
   function getBlockTimestamp() public view returns(uint) {
      return block.timestamp;
   }

   event MyEvent(uint256 timestamp);

   function myEvent() public {
       emit MyEvent(block.timestamp);
   }     
}