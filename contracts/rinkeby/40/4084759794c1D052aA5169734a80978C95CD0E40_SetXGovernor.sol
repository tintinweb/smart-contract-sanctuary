/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract SetXGovernor {
  address public governor;
  address public pendingGovernor;
  uint256 public x;

  constructor() {
    governor = msg.sender;
  }

  function setPendingGovernor(address _pendingGovernor) external {
    require(msg.sender == governor);
    pendingGovernor = _pendingGovernor;
  }

  function acceptGovernor() external {
    require(msg.sender == pendingGovernor, "!pg");
    governor = msg.sender;
    pendingGovernor = address(0);
  }

  function setX(uint256 _x) external {
    require(msg.sender == governor, "!g");
    x = _x;
  }
}