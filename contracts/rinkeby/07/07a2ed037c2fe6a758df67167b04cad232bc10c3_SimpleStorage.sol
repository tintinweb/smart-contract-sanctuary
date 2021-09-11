/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

pragma solidity ^0.6;
// SPDX-License-Identifier: MIT

contract SimpleStorage {
    
    uint256 public favoriteNumber ;
    // bool favoriteBool = false;
    // string favoriteString = "String";
    // int256 favoriteInt = -5;
    // address favoriteAddress = 0x89205A3A3b2A69De6Dbf7f01ED13B2108B2c43e7;
    // bytes2 favoriteBytes = "AZ";
    
    
    struct People{
        uint256 favoriteNumber;
        string name;
        
    }
    
    // People public person = People(
    //     {favoriteNumber:2,name:"test"}
    //     );
    
    People[] public people;
    mapping(string => uint256) public nameToFavoriteNumber;
    
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory _people = People(_favoriteNumber, _name);
        people.push(_people);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
    
    
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }
    
    function retrieve() public view returns(uint256){
        return favoriteNumber;
    }
}