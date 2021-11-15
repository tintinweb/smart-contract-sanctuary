// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

contract TowerFactory {

    event NewTower(uint towerId, string name, uint dna);

    uint dnaDigits = 16;
    uint dnaModulus = 10 ** dnaDigits;

    struct Tower {
        string name;
        uint dna;
    }

    Tower[] public towers;

    function _createTower(string memory _name, uint _dna) private {
        towers.push(Tower(_name, _dna));
        uint id = towers.length - 1;
        emit NewTower(id, _name, _dna);
    }

    function _generateRandomDna(string memory _str) private view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(_str)));
        return rand % dnaModulus;
    }

    function createRandomTower(string memory _name) public {
        uint randDna = _generateRandomDna(_name);
        _createTower(_name, randDna);
    }
}

