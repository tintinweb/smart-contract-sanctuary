// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ver2b.sol";

contract Ver2 is Ver2b {
  
  address private immutable _bridge;

  constructor() {
    _bridge = msg.sender;
  }

  function bridge() public view virtual returns (address) {
      return _bridge;
  }
}