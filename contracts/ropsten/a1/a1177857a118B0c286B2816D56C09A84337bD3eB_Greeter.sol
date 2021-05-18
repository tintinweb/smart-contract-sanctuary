/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

contract Greeter {
  string greeting;

  constructor() {
    greeting = "hello world";
  }

  
  function greet() public view returns (string memory) {
    return greeting;
  }

  function setGreeting(string memory _greeting) public {
    greeting = _greeting;
  }
}