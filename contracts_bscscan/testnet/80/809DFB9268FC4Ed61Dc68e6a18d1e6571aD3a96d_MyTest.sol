/**
 *Submitted for verification at BscScan.com on 2021-08-09
*/

// File: contracts/MyTest.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MyTest {
  event EventName(address bidder);
  uint256 public number;

  function store(uint256 num) public {
    number = num;
    emit EventName(msg.sender);
  }

  function retrieve() public view returns (uint256) {
    return number;
  }
}