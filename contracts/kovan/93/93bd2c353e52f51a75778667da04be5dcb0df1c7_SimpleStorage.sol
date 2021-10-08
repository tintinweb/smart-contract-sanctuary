/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract SimpleStorage {
    uint256 favoriteNumber;

    // This is a comment!
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function getFavNumberFromName(string memory _name)
        public
        view
        returns (uint256)
    {
        return nameToFavoriteNumber[_name];
    }
}