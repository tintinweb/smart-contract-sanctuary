/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

// SPDX-License_Identifier: MIT

pragma solidity ^0.6.0;

contract SimpleStorage{
    
    uint256 public favouriteNumber = 5;
    
    struct People {
        uint256 fav;
        string name;
        
    }
    
    People[] public peoples;
    mapping(string => uint256) public nameToFavoriteNumber;
    
    function store(uint256 newFavNumber) public{
        favouriteNumber = newFavNumber;
        
    }
    
    function read(string memory _name) public view returns(uint256) {
        return nameToFavoriteNumber[_name];
    }
    
    function addPerson(string memory _name, uint256 _fav) public{
        peoples.push(People(_fav, _name));
        nameToFavoriteNumber[_name] = _fav;
        
    }
    
}