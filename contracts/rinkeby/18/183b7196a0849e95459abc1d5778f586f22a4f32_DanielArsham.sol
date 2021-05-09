/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract DanielArsham {
      
   function getBlockTimestamp() public view returns(uint) {
      return block.timestamp;
   }

    function getMinute() public view returns (uint8) {
        return uint8((block.timestamp / 60) % 60);
    }

}