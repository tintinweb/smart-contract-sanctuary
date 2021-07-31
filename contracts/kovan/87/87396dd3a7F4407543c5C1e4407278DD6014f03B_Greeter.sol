/**
 *Submitted for verification at Etherscan.io on 2021-07-31
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
  string greeting;

  constructor(string memory _greeting) {
    greeting = _greeting;
  }

  function greet() public view returns (string memory) {
    return greeting;
  }
}