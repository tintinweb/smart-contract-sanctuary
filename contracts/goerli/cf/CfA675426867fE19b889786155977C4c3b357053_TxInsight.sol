// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

struct Record {
  uint256 a;
  string b;
}

contract TxInsight {
  function run(
    // these arguments are what will be decoded
    uint256[] memory nums,
    Record memory record
  )
    public
  {
    // no-op
  }
}