/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract SimpleStprage {
    
    uint256 favoriteNumber;
    
    struct People {
        uint256 favoriteNumber;
        string name;
    }
    
    People public person = People({favoriteNumber: 2, name: "Mimi Fannan"});
    
    People[] public people;
    
    mapping(string => uint256) public nameToFavoriteNumber;
    
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }
    
    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }
    
    // function doubling(uint256 favoriteNumber) public pure {
    //     favoriteNumber + favoriteNumber;
    // }
    
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People({favoriteNumber: _favoriteNumber, name: _name}));
        // people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}