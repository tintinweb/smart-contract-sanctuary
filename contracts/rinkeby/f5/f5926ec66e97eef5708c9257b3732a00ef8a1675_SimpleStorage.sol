/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

// SPDX-license-Identifier: MIT
pragma solidity ^0.6.0;

contract SimpleStorage{
    uint256 public favoriteNumber;

    struct People  {
        uint256 favoriteNumber;
        string Name;
    }

    People[] public people;
    mapping(string => uint256) public nametoFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber=_favoriteNumber;
    }

    function retreive() public view returns(uint256){
        return favoriteNumber+favoriteNumber;
    }

    function add_preson(uint256 number, string memory name) public{
        people.push(People({favoriteNumber: number, Name: name }));
        nametoFavoriteNumber[name] = number;
    }
}