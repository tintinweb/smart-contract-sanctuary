/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

pragma solidity ^0.6.0;
// SPDX-License-Identifier: MIT

contract SimpleStorage {
    // this will get initialized to 0!
    uint256 public favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public person;

    mapping(string => uint256) public nametoFavoriteNumber;



    function store(uint256 _favoriteNumber) public {
        person[0].favoriteNumber = _favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
     person.push(People(_favoriteNumber, _name));
    nametoFavoriteNumber[_name] = _favoriteNumber;
    }
    
}