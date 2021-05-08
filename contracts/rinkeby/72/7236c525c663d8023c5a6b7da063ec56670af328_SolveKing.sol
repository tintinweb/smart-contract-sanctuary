/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;

contract SolveKing {
  constructor() {}

  function transfer(address target) public payable {
    bytes memory x;
    (bool success, ) = target.call{ value: msg.value }(x);
    require(success, "call not success");
  }
}