/**
 *Submitted for verification at Etherscan.io on 2021-07-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract AdvancedStorage {
  uint[] public ids;

  function add(uint id) public {
    ids.push(id);
  }

  function get(uint i) view public returns(uint) {
    return ids[i];
  }

  function getAll() view public returns(uint[] memory) {
    return ids;
  }

  function length() view public returns(uint) {
    return ids.length;
  }
}