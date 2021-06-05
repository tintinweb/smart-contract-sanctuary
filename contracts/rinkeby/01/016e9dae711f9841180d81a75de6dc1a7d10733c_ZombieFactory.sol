/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

pragma solidity ^0.8.0;

contract ZombieFactory {

    // declare our event here

    uint dnaDigits = 16;
    uint dnaModulus = 10 ** dnaDigits;

    struct Zombie {
        string name;
        uint dna;
    }

    Zombie[] public zombies;

    function _createZombie(string memory _name, uint _dna) private {
        zombies.push(Zombie(_name, _dna));
        // and fire it here
    }

    function _generateRandomDna(string memory _str) private view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(_str)));
        return rand % dnaModulus;
    }

    function createRandomZombie(string memory _name) public {
        uint randDna = _generateRandomDna(_name);
        _createZombie(_name, randDna);
    }

	function paginateAllZombies(uint _resultsPerPage, uint _page) external view returns (Zombie[] memory) {
	  Zombie[] memory result = new Zombie[](_resultsPerPage);
	  for(uint i = _resultsPerPage * _page - _resultsPerPage; i < _resultsPerPage * _page; i++ ){
	      result[i] = zombies[i];
	    } //CONVERT TO SAFEMATH
	    return result;
	}
}