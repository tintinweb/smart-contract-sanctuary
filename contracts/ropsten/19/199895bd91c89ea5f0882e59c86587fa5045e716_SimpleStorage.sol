/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract SimpleStorage {
  uint256 simpleNumber;

  struct People {
    uint256 simpleNumber;
    string name;
  }

  People[] public people;
  mapping(string => uint256) public nameToSimpleNumber;

  function store(uint256 _simpleNumber) public {
    simpleNumber = _simpleNumber;
  }

  function retreive() public view returns (uint256) {
    return simpleNumber;
  }

  function addPeople(string memory _name, uint256 _simpleNumber) public {
    people.push(People({ simpleNumber: _simpleNumber, name: _name }));
    nameToSimpleNumber[_name] = _simpleNumber;
  }
}