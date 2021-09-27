/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract SimpleStorage {

    uint256 favoriteNumber;
    bool favoriteBool;
    
    struct People {
        uint256 favoriteNumber;
        string name;
    }
    
    People[] public people;
    mapping(string => uint256) public nameToFavoriteNumber;
    
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }
    
    function retrieve() public view returns(uint256) {
    return favoriteNumber;    
    }
    
    function addPerson (string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));     
        nameToFavoriteNumber[_name] = _favoriteNumber;
        
    }
}