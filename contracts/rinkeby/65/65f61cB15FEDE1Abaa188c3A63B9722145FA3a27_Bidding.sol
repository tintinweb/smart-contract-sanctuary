// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bidding {
  uint256 _currentBid;
  bool _isActive;
  string _someData;

  constructor() {
    _isActive = false;
  }

  function helloContract() external pure returns (string memory) {
    return "Hello, World";
  }

  function setBid(uint256 amount) external {
    _currentBid = amount;
  }

  function getBid() external view returns (uint256) {
    return _currentBid;
  }
}

