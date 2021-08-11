/**
 *Submitted for verification at BscScan.com on 2021-08-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Test {
  bool public tradingEnabled = false;
    
  function enableTrading() external {
    tradingEnabled = true;
  }
}