/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

// SPDX-License-Identifier: MIT

// pragma solidity >= 0.6.0 < 0.9.0;
pragma solidity ^0.6.0;

contract SimpleStorage {
    
    // the default value is 0
    uint256 public favoriteNumber;
    
    // bool favoriteBool = true;
    // string favString = "string_value";
    // int256 favInt = -5;
    // address favAddress = 0x5cDE6Fe5F61E2061A3124C30Bb991547680a544d;
    // bytes32 favBytes = "cat";
    
    struct People {
        uint256 favNumber;
        string name;
    }
    
    People[] public people;
    // People[2] public fixedSizePeople;
    
    mapping (string => uint256) public nameToFavNumber;
    
    // People public person = People({favNumber: 2, name: "Dima"});
    
    function store(uint256 _newFavNumber) public {
        favoriteNumber = _newFavNumber;
    }
    
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
    
    function pureStuff(uint256 arg) public pure returns(uint256) {
        return arg + arg/2;
    }
    
    function addPerson(string memory _name, uint256 _favNumber) public {
        people.push(People(_favNumber, _name));
        nameToFavNumber[_name] = _favNumber;
    }
}