// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestingEvents {
  event SignUpForRace(address indexed racer, uint256 indexed car, uint256[] modules);

  constructor() {}

  function sendEvent(uint256 car, uint256[] memory modules) public {
    emit SignUpForRace(msg.sender, car, modules);
  }
}

