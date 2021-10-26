/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



// File: SimpleStorage.sol

contract SimpleStorage {

    uint256 favoriteNumber;

    function store(uint256 _number) public {
        favoriteNumber = _number;
    }

    function retrive() public view returns (uint256) {
        return favoriteNumber;
    }
}