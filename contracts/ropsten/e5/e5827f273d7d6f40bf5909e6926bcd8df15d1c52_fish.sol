/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract fish {
 
  int public fishColor;
  string public name;
  string public symbol;
  
  constructor() {
    name = "Fish 1";
    symbol = "FSH";
    fishColor = 0;
  }

}