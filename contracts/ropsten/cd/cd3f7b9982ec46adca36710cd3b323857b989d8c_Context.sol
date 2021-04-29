/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// SPDX-License-Identifier: None
pragma solidity ^0.7.4;
contract Context {
 function isContract(address _addr) external view {
  uint32 size;
  assembly {
    size := extcodesize(_addr)
  }
  //return (size > 0);
  require(size < 0,"that's a contract");
 }
}