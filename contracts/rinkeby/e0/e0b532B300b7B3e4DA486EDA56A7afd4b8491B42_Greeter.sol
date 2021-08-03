/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

contract Greeter {
  string greeting;
  address public owner;

  constructor(string memory _greeting) {
    // console.log("Deploying a Greeter with greeting:", _greeting);
    greeting = _greeting;
    owner = msg.sender;
  }

  event NameChange(
    string newName
  );

  event Destruction();

  modifier onlyOwner {
      require(msg.sender == owner, "only owner can use this");
      _;
  }

  function greet() public view returns (string memory) {
    return greeting;
  }

  function setGreeting(string memory _greeting) public {
    // console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
    greeting = _greeting;
    emit NameChange(_greeting);
  }

  function abandonShip() external onlyOwner returns (bool) {
    emit Destruction();
    selfdestruct(payable(owner));
    return true;
  }
}