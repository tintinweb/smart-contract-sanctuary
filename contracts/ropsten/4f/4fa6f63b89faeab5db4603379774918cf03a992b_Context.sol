/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

/*
██╗  ██╗ ██████╗ ███╗   ██╗██╗  ██╗██╗  ██╗ ██████╗ ███╗   ██╗██╗  ██╗
██║  ██║██╔═══██╗████╗  ██║██║ ██╔╝██║  ██║██╔═══██╗████╗  ██║██║ ██╔╝
███████║██║   ██║██╔██╗ ██║█████╔╝ ███████║██║   ██║██╔██╗ ██║█████╔╝ 
██╔══██║██║   ██║██║╚██╗██║██╔═██╗ ██╔══██║██║   ██║██║╚██╗██║██╔═██╗ 
██║  ██║╚██████╔╝██║ ╚████║██║  ██╗██║  ██║╚██████╔╝██║ ╚████║██║  ██╗
╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝
*/

// SPDX-License-Identifier: None
pragma solidity ^0.7.4;
contract Context {
 function isContract(address _addr) public view returns (bool) {
  bytes32 codehash;
  bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
  assembly { codehash := extcodehash(_addr) }
  return (codehash != accountHash && codehash != 0x0);
 }
}