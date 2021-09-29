/**
 *Submitted for verification at polygonscan.com on 2021-09-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface OracleLike {
  function getPrice() external returns (uint256, bool);
}

// Simple Oracle for testing purposes
// DO NOT USE IN PRODUCTION
contract SimpleOracle is OracleLike {
  uint256 public tokenPrice;

  function getPrice() public view override returns (uint256, bool) {
    return (tokenPrice, true);
  }

  function setPrice(uint256 value) public {
    tokenPrice = value;
  }
}