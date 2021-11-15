// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

contract Greeter {
  string internal greeting;

  constructor(string memory _greeeting) {
    greeting = _greeeting;
  }

  function greet() public view returns (string memory greeting_) {
    greeting_ = greeting;
  }

  function setGreeting(string memory _newGreeting) public {
    greeting = _newGreeting;
  }
}

