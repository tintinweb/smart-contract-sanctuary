/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract SimpleStorage {
    
    uint256 public favoriteNumber;
    bool favoriteBool;
    
    struct People {
        uint256 favoriteNumber;
        string name;
    }
    
    
    
    People public person = People({favoriteNumber: 2, name: "Patrick"});
    People[] public people_arr;
    mapping(string => uint256) public nameToFavoriteNumber;
    
    
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }
    
    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }
    
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people_arr.push(People(_favoriteNumber, _name ));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

}