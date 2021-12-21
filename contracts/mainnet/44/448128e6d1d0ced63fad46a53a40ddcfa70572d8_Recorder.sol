/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Recorder {

    struct Person {
        string name;
        string title;
    }

    Person[] public persons;

    constructor(Person[] memory _persons) {
        for (uint8 i = 0; i < _persons.length; i++) {
            persons.push(_persons[i]);
        }
    }

    function add(Person memory person) public returns (uint256) {
        persons.push(person);
        return persons.length - 1;
    }

    function totalPersons() public view returns (uint256) {
        return persons.length;
    }
}