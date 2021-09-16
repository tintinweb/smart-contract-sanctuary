/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.0 <0.9.0;

contract SimpleStorage{
    uint256 public favoriteNumber;
    
    struct People{
        uint256 favoriteNumber;
        string name;
    }
    
    People[] public person;
    mapping(string => uint256) public nameToFavoriteNumber;
    
    function addPerson(string memory _name, uint256 _num) public{
        person.push(People({favoriteNumber:_num,name:_name}));
        nameToFavoriteNumber[_name] = _num;
    }
    
    function store(uint256 num) public{
        favoriteNumber = num;
    }
    function retrieve() public view returns(uint256){
        return favoriteNumber;
    }
}