/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract SimpleStorage {
    
    //  uninitialized variables will be set to the data types null value (for uint256 this will be 0)
    uint256 public favoriteNumber;
    
    struct Person {
        uint256 favoriteNumber;
        string name;
        uint256 age;
    }
    
    mapping(string => uint256) public nameToFavoriteNumber;
    
    Person[] public people;
    
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }
    
    function retieve() public view returns(uint256) {
        return favoriteNumber + favoriteNumber;
    }
    
    function addPerson(string memory _name, uint256 _age, uint256 _favoriteNumber) public {
        people.push(Person({favoriteNumber: _favoriteNumber, name: _name, age: _age}));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}