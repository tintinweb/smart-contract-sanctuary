/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

pragma solidity ^0.8.1;

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