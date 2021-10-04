/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract SimpleStorage {
    
    // this will get initialized to 0!
    uint256 public favoriteNumber;
    
    function store(uint256 _faveNo) public {
        favoriteNumber = _faveNo;
    }
    
    function retrieve() public view returns(uint256){
        return favoriteNumber;
    }
    
    struct Person {
        uint256 favoriteNumber;
        string name;
    }
    mapping(string => uint256) public nameToFaveNumber;
    
    Person[] public person;
    
    function addPerson(uint256 _favoriteNumber, string memory _name) public{
        person.push(Person(_favoriteNumber,_name));
        nameToFaveNumber[_name] = _favoriteNumber;
    }
    
}