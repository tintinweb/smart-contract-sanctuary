// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favoriteNum;

    function store(uint256 num) public {
        favoriteNum = num;
    }

    function retrieve() public view returns(uint256) {
        return favoriteNum;
    }
}