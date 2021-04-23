/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.4;
contract Context {
 function isContract(address addr) internal view returns (bool) {
  bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
  bytes32 codehash;
  assembly {
   codehash := extcodehash(addr)
  }
  return (codehash != 0x0 && codehash != accountHash);
 }
}