/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract {
    uint nextId;

    struct Person {
        uint id;
        string name;
        string job;
    }
    Person[] list_person;

    function createPerson(string memory _name, string memory _job) public {
        list_person.push(Person(nextId, _name, _job));
        nextId++;
    }

    function findPerson(uint _id) public view returns (uint, string memory, string memory){
        for(uint i = 0; i < list_person.length; i++) {
            if(list_person[i].id == _id) {
                return (list_person[i].id, list_person[i].name, list_person[i].job);
            }
        }
    }
}