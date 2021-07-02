/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Calculator {
  uint256 public calculateResult;
  address public user;
  uint256 public addCount;

  event Add(address txorigin, address sender, address _this, uint a, uint b);

  function add(uint256 a, uint256 b) public returns (uint256) {
    calculateResult = a + b;
    user =msg.sender;
    addCount = addCount + 1;
    emit Add(tx.origin, msg.sender, address(this), a, b);
    return calculateResult;
  }
}