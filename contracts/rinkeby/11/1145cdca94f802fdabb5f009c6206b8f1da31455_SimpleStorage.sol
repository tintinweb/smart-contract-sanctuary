/**
 *Submitted for verification at Etherscan.io on 2021-12-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    uint256 public favoriteNumber;

    People[] public peoples;
    mapping(string => uint256) public nameToFavoriteNumber;
    
    function store(uint256 _favortieNumber) public {
    favoriteNumber = _favortieNumber;
    }

    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    struct People {
        uint256 favNum;
        string name;
    }

    function addPerson(string memory _name, uint256 _favNum) public {
        peoples.push(People({favNum: _favNum, name: _name}));
        nameToFavoriteNumber[_name] = _favNum;
    }
}