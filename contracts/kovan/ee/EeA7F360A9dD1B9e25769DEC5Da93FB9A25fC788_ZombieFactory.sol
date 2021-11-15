//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.5;




contract ZombieFactory {
  uint constant dnaDigits = 16;
  uint constant dnaModulus = 10 ** dnaDigits;

  struct Zombie {
    string name;
    uint dna;
  }

  Zombie[] public zombies;

  function createRandomZombie(string memory _name) public {
    uint randDna = _generateRandomDna(_name);
    _createZombie(_name, randDna);
  }

  function _createZombie(string memory _name, uint _dna) private {
    zombies.push(Zombie(_name, _dna));
  }

  function _generateRandomDna(string memory _str) private pure returns (uint) {
    uint rand = uint(keccak256(abi.encodePacked(_str)));
    return rand % dnaModulus;
  }
}

