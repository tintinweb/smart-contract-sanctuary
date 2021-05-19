/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

contract GiveTake {
  address internal testStore;

  function _testStore() public view returns (address) {
    return testStore;
  }

  function testStore_(address _testStore_) public returns (bool) {
    testStore = _testStore_;
    return true;
  }
}