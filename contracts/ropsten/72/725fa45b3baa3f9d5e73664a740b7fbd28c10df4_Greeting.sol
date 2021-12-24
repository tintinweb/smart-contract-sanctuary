/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Greeting {
  string public greeting = "hello";

  function sayHello() external view returns (string memory) {
    return greeting;
  }

  function updateGreeting(string calldata _greeting) external {
    greeting = _greeting;
  }
}