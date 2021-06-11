/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract Counter {

  uint256 public counter = 0;

  function add() external {
    counter++;
  }

  function sub() external {
    if (counter > 0) {
      counter--;
    }
  }

}