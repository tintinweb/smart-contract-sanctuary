/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract SimpleStorage {
    
    uint256 favoriteNumber;
    
    struct People {
        uint256 favoriteNumber;
        string name;
    }
    
    People[] public people;
    
    mapping(string => uint256) public nameToFavouriteNumber;
    
    function store(uint256 _favouriteNumber) public {
        favoriteNumber = _favouriteNumber;
    }
    
    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }
    
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People({name: _name, favoriteNumber: _favouriteNumber}));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
    
}