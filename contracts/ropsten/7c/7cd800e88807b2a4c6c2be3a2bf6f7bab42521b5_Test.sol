/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0;

contract Test {

  uint  name;

  function  setName(uint x ) public{
      name=x;
  }
  function  getName() public view returns(uint)   {
      return name;
  }

}