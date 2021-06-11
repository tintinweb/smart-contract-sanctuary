// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Voting.sol";

contract Passport {

  Voting voting;

  string public name;
  string gender;
  uint age;

  constructor(address _voting, string memory _name, string memory _gender, uint _age) {
    voting = Voting(_voting);
    name = _name;
    gender = _gender;
    age = _age;
  }

  function vote(bool _vote) public {
    voting.vote(_vote);
  }
}