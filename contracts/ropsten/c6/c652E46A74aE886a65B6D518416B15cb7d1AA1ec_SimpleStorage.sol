/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 public favoriteNumber = 0;
    
    struct Person {
        uint256 favoriteNumber;
        string name;
    }
    
    Person[] public people;
    
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }
    
    function retreive() public view returns(uint256) {
        return favoriteNumber;
    }
    
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(Person({favoriteNumber: _favoriteNumber, name: _name}));
    }
    
}