/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19;

contract Monke {
  event NewMonkee(uint monkeeId, string name, uint dna);

  struct Monkee {
    string name;
    uint dna;
    uint32 level;
  }

  uint dnaDigits = 16;
  uint dnaModulus = 10 ** dnaDigits;

  Monkee[] public monkees;

  // uint = id = monkees index
  mapping (uint => address) public monkeeToOwner;
  mapping (address => uint) ownerMonkeeCount;
  
  function _createMonkee(string memory _name, uint _dna) internal {
    uint id = monkees.push(Monkee(_name, _dna, 1));
    monkeeToOwner[id] = msg.sender;
    ownerMonkeeCount[msg.sender]++;
    NewMonkee(id, _name, _dna);
  }

  function _generateRandomDna(string memory _str) private view returns (uint) {
    uint rand = uint(keccak256(_str));
    return rand % dnaModulus;
  }

  function createRandomMonkee(string memory _name) public {
    require(ownerMonkeeCount[msg.sender] == 0);
    uint randDna = _generateRandomDna(_name);
    randDna = randDna - randDna % 100;
    _createMonkee(_name, randDna);
  }
}