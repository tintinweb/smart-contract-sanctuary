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
 function isContract(address _addr) public view returns (uint32) {
  uint32 size;
  assembly {
    size := extcodesize(_addr)
  }
  require(size < 1,"that's a contract");
  return (size);
 }
}