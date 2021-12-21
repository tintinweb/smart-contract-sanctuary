/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

pragma solidity ^0.6.0;

// SPDX-License-Identifier: UNLICENSED;

contract SimpleStorage {
    // initial value is 0
    uint256 public favoriteNumber;
    // bool favoriteBool = false;
    // string favoriteString = "String";
    // int256 favoriteInt = -10;
    // address favoriteAddress = 0x872D5a80eA95A905276A7D0804a8330A0F0e8CfF;
    // bytes32 favoriteBytes = "cat";

    struct People {
        string name;
        uint256 favoriteNumber;
    }

    People[] public people;
    mapping(string => uint256) public nameToFavoriteNumberMapping;

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_name, _favoriteNumber));
        nameToFavoriteNumberMapping[_name] = _favoriteNumber;
    }

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }
}