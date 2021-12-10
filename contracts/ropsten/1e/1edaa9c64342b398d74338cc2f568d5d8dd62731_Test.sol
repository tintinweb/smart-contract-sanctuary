/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract Test {
  bool public hasStarted;
  uint256 public constant PRICE = 0.08 ether;
  mapping(address => uint32) public amountOf;

  function mint(address to, uint8 projectId) public payable {
    require(hasStarted, "Sale hasn't started");
    require(projectId == 1, "Wrong project id");
    amountOf[to]++;
  }
  
  function changeStatus() public {
    hasStarted = !hasStarted;
  }
}