/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

pragma solidity >=0.5.0 <0.6.0;

contract ChillyPenguin {

    event NewPenguino(uint penguinoId, string name, uint dna);

    uint dnaDigits = 16;
    uint dnaModulus = 10 ** dnaDigits;

    struct Penguino {
        string name;
        uint dna;
    }

    Penguino[] public penguinos;

    function _createPenguino(string memory _name, uint _dna) private {
        uint id = penguinos.push(Penguino(_name, _dna)) - 1;
        emit NewPenguino(id, _name, _dna);
    }

    function _generateRandomDna(string memory _str) private view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(_str)));
        return rand % dnaModulus;
    }

    function createRandomPenguino(string memory _name) public {
        uint randDna = _generateRandomDna(_name);
        _createPenguino(_name, randDna);
    }

}