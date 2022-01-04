/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract SolidStorage {

    struct Person {
        uint256 vote;
        string name;
    }

    Person[] public person;
    mapping(string => uint256) public nameToVote;

    function addPerson(string memory _name, uint256 _vote) public {
        person.push(Person(_vote, _name));
        nameToVote[_name] = _vote;
    }

}