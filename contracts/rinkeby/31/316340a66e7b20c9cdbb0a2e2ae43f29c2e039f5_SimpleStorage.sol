/**
 *Submitted for verification at Etherscan.io on 2021-12-26
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract SimpleStorage {
    //Initialized to to 0!
    uint256 favoriteNumber;

    struct People{
        uint256 favoriteNumber;
        string name;
    }

    // People public person = People({favoriteNumber: 2, name: "Nic"});

    People[] public people; // Dynamic, empty array
    
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // people.push(People({favoriteNumber: _favoriteNumber, name: _name})); // Option 1
        people.push(People(_favoriteNumber, _name)); // Option 2
        nameToFavoriteNumber[_name] = _favoriteNumber; 
    }  

}