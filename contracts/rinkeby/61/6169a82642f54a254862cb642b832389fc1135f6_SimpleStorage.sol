/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract SimpleStorage {
    // this will initialize to 0
    uint256 public FavNum;

    function store(uint256 _favnum) public {
        FavNum = _favnum;
    }
    
    function retrieve() public view returns(uint256) {
        return FavNum;
    }

    struct People {
        uint256 FavNum;
        string name;
    } 

    People[] public people;

    mapping(string=>uint256) public fromNameToFavorite;

    function addperson(string memory _name, uint256 _favnum) public {
        people.push(People({name:_name, FavNum:_favnum}));
        fromNameToFavorite[_name] = _favnum;
    }
}