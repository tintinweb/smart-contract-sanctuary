/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-27
*/

pragma solidity 0.8.10;


contract ZombieFactory {
    
     uint dnaDigits = 16;
    
     uint dnaModulus = 10 ** dnaDigits;
    
    struct Zombie {
        string name;
        uint dna;
    }

Zombie[] public zombies; // Tableau Dynamique Structure Public

function createZombie(string memory _name, uint _dna) private {
    zombies.push(Zombie(_name,_dna));

}

}