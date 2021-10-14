/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
contract EventCheck
{   
  event Name(uint number,string  name,uint time);
  function add(uint number,string memory name) public
  {
    emit Name(number,name,block.timestamp);
  }
}