/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.6;


contract LokTest {
  uint256 public timer = 1753633194;
  bool  public test_l = false;

  function incTimer(uint256 _timer) public {
    timer = block.timestamp  +_timer;
  }

  function launch() external  {
    test_l = true;
  }    
}