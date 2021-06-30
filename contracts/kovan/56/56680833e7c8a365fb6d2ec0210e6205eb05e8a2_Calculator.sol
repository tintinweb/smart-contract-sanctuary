/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.5 <0.9.0;

contract Calculator {
  uint256 public calculateResult;
  address public user;
  address public calculator;
  uint256 public consecutiveCalls;

  event testEvent(address indexed txOrigin, address indexed msgSenderAddress, address indexed _this, uint256 calculateResult);

  function add(uint256 a, uint256 b) public returns (uint256) {
    calculateResult = a + b;
    user = msg.sender;
    calculator = address(this);
    consecutiveCalls++;
    emit testEvent(tx.origin, msg.sender, address(this), calculateResult);
    return calculateResult;
  }
}