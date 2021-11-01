/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract SetXOwner {
  address public owner;
  uint256 public x;

  constructor() {
    owner = msg.sender;
  }

  function transferOwnership(address _newOwner) external {
    owner = _newOwner;
  }

  function renounceOwnership() external {
    revert("cannot renounce ownership");
  }

  function setX(uint256 _x) external {
    require(msg.sender == owner, "!g");
    x = _x;
  }
}