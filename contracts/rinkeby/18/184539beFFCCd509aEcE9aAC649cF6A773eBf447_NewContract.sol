/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract NewContract {
  string public name;

  constructor(string memory _name) {
    name = _name;
  }
}