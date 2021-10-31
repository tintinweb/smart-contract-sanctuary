//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract DaughterContract {
  string public name;
  uint256 public birthYear;

  address public mom;

  constructor() {
    mom = msg.sender;
  }

  modifier onlyMom() {
    require(msg.sender == mom, "Limited by Mom");
    _;
  }

  function initialize(string memory _name, uint256 _birthYear) external onlyMom {
    name = _name;
    birthYear = _birthYear;
  }
}