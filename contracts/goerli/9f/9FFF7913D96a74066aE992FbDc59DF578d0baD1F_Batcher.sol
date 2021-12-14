/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Batcher {
  function batchSend(address payable[] memory targets, uint value) public payable {
    for (uint i = 0; i < targets.length; i++) {
      bool success = targets[i].send(value);
      require(success, 'transaction failed');
    }
  }
}