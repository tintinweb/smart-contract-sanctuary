/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT

//pragma solidity >= 0.6.0 <0.9.0;
pragma solidity ^0.6.0;

contract SimpleStorage {

    // init to 0
    // default type is internal (internal/ external/ public/ private)
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // array
    People[] public people;


    // mapping
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure
    // view only reading off of the blockchain (variables can also be of type view)
    // pure can do math but doesnt get saved in the blockchain
    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People({favoriteNumber: _favoriteNumber, name: _name}));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}