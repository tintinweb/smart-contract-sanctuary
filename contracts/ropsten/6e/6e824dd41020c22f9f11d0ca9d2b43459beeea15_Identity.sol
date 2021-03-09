/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

pragma solidity 0.6.6;
contract Identity {
    struct Person {
        string name;
        uint age;
        uint height;
    }
    Person [] public people;
    function createPerson (string memory name, uint age, uint height) public {
        Person memory newPerson;
        newPerson.name = name;
        newPerson.height = height;
        newPerson.age = age;
        people.push (newPerson);
    }
}