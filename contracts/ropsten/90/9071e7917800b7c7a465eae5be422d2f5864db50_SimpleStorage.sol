/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 private favouriteNumber;
    
    struct People {
        string name;
        uint256 favouriteNumber;
    }
    
    People[] public people;
    mapping(string => uint256) public nameToFav;
    
    function newPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_name, _favouriteNumber));
        nameToFav[_name] = _favouriteNumber;
    }
    function countPeople() public view returns(uint256) {
        return people.length;
    }
    function store(uint256 _favouriteNumber) public {
        favouriteNumber = _favouriteNumber;
    }
    function retrieve() public view returns(uint256) {
        return favouriteNumber + favouriteNumber;
    }
    function sum8and256(uint256 a, uint8 b) public pure returns(uint256) {
        return a + b;
    }
}