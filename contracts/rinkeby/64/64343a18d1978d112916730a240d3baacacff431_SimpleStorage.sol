/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract SimpleStorage {
    uint256 favoriteNumber; // initialized to zero

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people; // dynamic array
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favNumber) public {
        people.push(People(_favNumber, _name));
        nameToFavoriteNumber[_name] = _favNumber;
    }
}