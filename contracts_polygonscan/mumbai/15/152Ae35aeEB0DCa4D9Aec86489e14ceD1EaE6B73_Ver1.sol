// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ver1 {
  address private immutable _bridge;

  constructor() {
    _bridge = msg.sender;
  }
  
}

