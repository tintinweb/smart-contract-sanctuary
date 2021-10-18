/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
contract EventCheck
{   
  event Names(string Name,uint Timestamps);
  function add(string memory name) public
  {
    emit Names(name,block.timestamp);
  }
}