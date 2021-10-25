/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.22 <0.9.0;

contract TestToken {
  uint public number;

  function add(uint _nr) public {
    number += _nr;
  }
}