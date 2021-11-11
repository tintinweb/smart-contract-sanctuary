/**
 *Submitted for verification at arbiscan.io on 2021-11-10
*/

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.8.10;

contract ValueStore {
  uint256 public uint256Value;

  event NewValue(); 

  function setUint256(uint256 val) public {
      uint256Value = val;
  }

  function setUint256Calldata(uint256 val) public {
      emit NewValue();
  }
}