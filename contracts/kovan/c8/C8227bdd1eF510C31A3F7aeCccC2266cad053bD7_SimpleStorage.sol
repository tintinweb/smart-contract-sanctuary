// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;



contract SimpleStorage {

    uint256 favoriteNumber;
    string public name;

    constructor(string memory _name){
        name = _name;
    }


    function store(uint256 _number) public {
        favoriteNumber = _number;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
    
      

}