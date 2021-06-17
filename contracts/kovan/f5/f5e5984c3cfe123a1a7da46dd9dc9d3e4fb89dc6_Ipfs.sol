/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

/* SPDX-License-Identifier: MIT */
pragma solidity ^0.8.0;


contract Ipfs {
  string ipfsHash;

  function sendHash(string memory x) public {
    ipfsHash = x;
  }

  function getHash() public view returns (string memory x) {
    return ipfsHash;
  }
}