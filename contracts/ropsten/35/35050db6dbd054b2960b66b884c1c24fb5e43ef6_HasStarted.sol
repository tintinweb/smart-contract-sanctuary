/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract HasStarted {
  bool public hasStarted;
  uint256 public constant PRICE = 0.08 ether;
  mapping(address => uint32) public amountOf;

  function mint(uint8 amount) public payable {
    require(amount <= 2, "Insufficient amount");
    require(hasStarted, "Sale hasn't started");
    amountOf[msg.sender] += amount;
  }
  
  function changeStatus() public {
    hasStarted = !hasStarted;
  }
}