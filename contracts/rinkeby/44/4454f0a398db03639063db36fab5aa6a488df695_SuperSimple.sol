/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.3;


contract SuperSimple  {
  uint256 public test = 0;
  uint256 public timer = 1753633194;

  function incTest() public {
      test ++;
  }

  function incTimer(uint256 _timer) public {
        timer = block.timestamp  +_timer;
    }
}