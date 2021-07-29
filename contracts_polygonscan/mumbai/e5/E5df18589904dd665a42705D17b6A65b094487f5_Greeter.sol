//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

contract Greeter {
  string _greeting;
  uint256 _testNumber;
  address _testAddress;

  constructor(
    string memory greeting,
    uint256 testNumber,
    address testAddress
  ) {
    _greeting = greeting;
    _testNumber = testNumber;
    _testAddress = testAddress;
  }

  function greet() public view returns (string memory) {
    return _greeting;
  }

  function getTestNumber() public view returns (uint256) {
    return _testNumber;
  }

  function getAddress() public view returns (address) {
    return _testAddress;
  }

  function setGreeting(string memory greeting) public {
    _greeting = greeting;
  }
}