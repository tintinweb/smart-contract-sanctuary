/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



// File: SimpleStorage.sol

contract SimpleStorage {
    uint256 favoriteNumber;
    function store(uint256 _number) public {
        favoriteNumber = _number;
    }

    function retrieve() public view returns (uint256) {
    return favoriteNumber;
    }
}