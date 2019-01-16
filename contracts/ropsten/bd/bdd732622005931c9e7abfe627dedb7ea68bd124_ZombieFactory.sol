pragma solidity ^0.4.0;
contract ZombieFactory{
    struct Zombie {
        string name;
        uint dna;
    }

    Zombie[] public zombies;

    function createZombie(string _name, uint _dna) public {
        zombies.push(Zombie(_name, _dna));
    }

}