/**
 *Submitted for verification at polygonscan.com on 2021-09-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract SimpleStorage {
    struct People {
        uint256 favoriteNumber;
        string name;
    }
    
    People[] public people;
    
    mapping(string => uint256) public nameToFavoriteNumber;
    
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}