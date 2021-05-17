/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

contract Greeter {
  string greeting;

  function greet() public view returns (string memory) {
    return greeting;
  }

  function setGreeting(string memory _greeting) public {
    greeting = _greeting;
  }
}