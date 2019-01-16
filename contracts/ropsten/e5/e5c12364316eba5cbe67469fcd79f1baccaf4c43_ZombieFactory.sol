pragma solidity ^0.4.19;

contract ZombieFactory {

    uint public dnaDigits = 16;
    uint public dnaModulus = 10 ** dnaDigits;

    struct Zombie {
        string name;
        uint dna;
    }

    // 这里开始
}