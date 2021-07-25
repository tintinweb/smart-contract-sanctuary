/**
 *Submitted for verification at BscScan.com on 2021-07-25
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File contracts/Greeter.sol

//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.6;

contract Greeter {
  string public greeting;

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