/**
 *Submitted for verification at BscScan.com on 2021-07-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract TokenV1 {
    uint256 public c;

    function add(uint256 a, uint256 b) public returns (uint256) {
      c = a + b + 1;
      return c;
    }
}