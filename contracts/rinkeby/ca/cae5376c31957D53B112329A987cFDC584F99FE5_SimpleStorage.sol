/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract SimpleStorage {
    
    // This is a test
    uint256 public favofiteNumber = 5;
    bool favoriteBool = true;
    string favoriteString = "String";
    int256 favoriteInt = -5;
    address favoriteAddress = 0x67f6B398870E60C9eE91350e6952B4b62bb88B52;
    bytes32 favoritesBytes = "cat";
    
    struct People {
        uint256 favofiteNumber;
        string name;
    }
    People[] public people;
    mapping(string => uint256) public nameToFavoriteNumber;
    //People public person = People({favofiteNumber: 2, name: "Spede"});
    
    function store(uint256 _favoriteNumber) public {
        favofiteNumber = _favoriteNumber;
    }
    
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People({favofiteNumber: _favoriteNumber, name: _name}));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}