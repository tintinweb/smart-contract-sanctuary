/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "hardhat/console.sol";


contract Greeter {
  string greeting;

  constructor() {
    greeting = "Hello there1";
  }

  function greet() public view returns (string memory) {
    return greeting;
  }

  function setGreeting(string memory _greeting) public {
    // console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
    greeting = _greeting;
  }
}