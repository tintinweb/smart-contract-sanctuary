/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;


contract Greeter {
  string greeting;

  constructor(string memory _greeting) {
    greeting = _greeting;
  }

  function greet() public view returns (string memory) {
    return greeting;
  }

  function setGreeting(string memory _greeting) public {
    greeting = _greeting;
  }
}