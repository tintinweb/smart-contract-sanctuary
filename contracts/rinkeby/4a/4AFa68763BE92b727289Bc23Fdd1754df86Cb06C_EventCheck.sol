/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
contract EventCheck
{   
  event Names(uint Number,string  Name ,uint Time);
  function add(uint number,string memory name) public
  {
    emit Names(number,name,block.timestamp);
  }
}