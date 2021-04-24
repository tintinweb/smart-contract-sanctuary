/**
 *Submitted for verification at Etherscan.io on 2021-04-24
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Notary {

  struct Record {
      uint mineTime;
      uint blockNumber;
    }

  mapping (bytes32 => Record) private docHashes;

  constructor() {
  }

  function addDocHash (bytes32 hash) public {
      Record memory newRecord = Record(block.timestamp, block.number);
      docHashes[hash] = newRecord;
    }
  function findDocHash (bytes32 hash) public view returns(uint, uint) {
      return (docHashes[hash].mineTime, docHashes[hash].blockNumber);
  }
}