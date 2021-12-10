/**
 *Submitted for verification at arbiscan.io on 2021-12-09
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
  string private greeting;

  constructor(string memory _greeting) {
    greeting = _greeting;
  }

  function greet() public view returns (string memory) {
    return greeting;
  }

  function setGreeting(string calldata _greeting) public {
    greeting = _greeting;
  }
}