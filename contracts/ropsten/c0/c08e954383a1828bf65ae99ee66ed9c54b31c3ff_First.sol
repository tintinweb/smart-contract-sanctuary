/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

contract First {
string str;

  constructor () public {
    str = "Hello world!";
  }
  function output() public pure returns (string memory) {
    return "Hello world!";
  }
}