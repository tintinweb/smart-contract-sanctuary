/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-27
*/

pragma solidity 0.8.10;

contract ZombieApp {
    
    struct Person {
        string name;
        uint age;
        string names;
    }
    
Person[] private people;
    
function createPeople (string memory _name, uint _age, string memory _names) public {
    people.push(Person(_name, _age, _names));
    
}

function _generateRandomDna (string memory _str) private view returns (uint) {
    
}

}