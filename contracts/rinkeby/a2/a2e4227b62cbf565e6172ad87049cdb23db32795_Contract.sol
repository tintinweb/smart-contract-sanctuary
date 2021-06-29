/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;
contract Contract {
 string fileHash;
 function sendHash(string memory x) public {
   fileHash = x;
 }
 function getHash() public view returns (string memory) {
   return fileHash;
 }
}