/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

// Sources flattened with hardhat v2.1.1 https://hardhat.org

// File contracts/Greeter.sol

pragma solidity ^0.8.0;

contract Greeter {
  string greeting;

  constructor() {
    greeting = "";
  }

  function greet() public view returns (string memory) {
    return greeting;
  }

  function setGreeting(string memory _greeting) public {
    greeting = _greeting;
  }
}