// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favouriteNumber;

    function store(uint256 _num) public {
        favouriteNumber = _num;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }
}