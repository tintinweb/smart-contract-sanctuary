/**
 *Submitted for verification at Etherscan.io on 2022-01-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyName {
  string public name;

  function setNameGE(string memory _name) public {
    name = _name;
  }
}