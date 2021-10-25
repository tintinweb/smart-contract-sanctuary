// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract SimpleStorage {
    uint256 favoriteNumber;


    // This is a comment!
    struct People {
        uint256 favoriteNumber;
        string name;
        uint256 whatever;
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
        people.push(People(_favoriteNumber, _name, 0));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}