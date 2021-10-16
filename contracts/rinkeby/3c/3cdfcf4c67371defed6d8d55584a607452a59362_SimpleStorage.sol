/**
 *Submitted for verification at Etherscan.io on 2021-10-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 < 0.9.0;


contract SimpleStorage {
    
    // this will get initialized to 0!
    uint256 public favoriteNumber;
    bool favoriteBool;
    
    struct People {
        
        uint256 favoriteNumber;
        string name;
        
    }
    
    //array
    People[] public people;
    //dictionary
    //       value to 
    mapping(string => uint256) public nameToFavoriteNumber;
    
    
    function store(uint256 _favoriteNumber) public returns(uint256) {
        
        favoriteNumber = _favoriteNumber;
        return favoriteNumber;
        
    }
    
    // view, pure
    
    function retrieve() public view returns(uint256) {
        
        return favoriteNumber;
    }
    
    //memory or storage. Memory after ejecution it deleted it self. storage the contract keeps it
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //add people to the array
        people.push(People({favoriteNumber: _favoriteNumber, name: _name}));
        nameToFavoriteNumber[_name] = _favoriteNumber;
        
    }
    
    
}