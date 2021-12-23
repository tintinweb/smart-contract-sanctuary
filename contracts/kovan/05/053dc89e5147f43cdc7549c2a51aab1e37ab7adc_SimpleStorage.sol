/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// SPDX-Liecense-Identifier: MIT

pragma solidity 0.6.0;

contract SimpleStorage {
    
    uint256 public favoriteNumber ;
        // array 
    People[] public listOfPeople;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }
    
    People public person = People({favoriteNumber: 6, name: "william"});

    function addPersonToListOfPeople(string memory _name, uint256 _favoriteNumber) public {
        listOfPeople.push(People({favoriteNumber: _favoriteNumber, name: _name}));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    mapping(string => uint256) public nameToFavoriteNumber;


}