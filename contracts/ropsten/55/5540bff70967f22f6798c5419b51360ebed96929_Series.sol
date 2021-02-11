/**
 *Submitted for verification at Etherscan.io on 2021-02-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.0;

contract Series {
  string name = "AHAM";
  mapping(address=>address[]) plugins;

  constructor(string memory _name) public {
    name = _name;
  }

  function getName(int teste) public payable returns (int) {
    return teste;
  }
  
}