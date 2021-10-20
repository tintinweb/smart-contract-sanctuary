/**
 *Submitted for verification at polygonscan.com on 2021-10-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract MessageBoard {

  string public message = "First message";

  function set(string memory x) public {
    message = x;
  }
}