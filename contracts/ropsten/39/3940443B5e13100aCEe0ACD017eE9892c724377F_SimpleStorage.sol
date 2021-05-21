/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.7.0;

contract SimpleStorage {
   uint data;

   function set(uint x) public {
       data = x;
   }

   function get() public view returns (uint) {
       return data;
   }
}