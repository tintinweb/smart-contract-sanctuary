/**
 *Submitted for verification at Etherscan.io on 2021-10-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Storage {
    function store(uint256 favoriteNumber) external;

    function retrieve() external view returns (uint256);
}

contract SimpleStorage is Storage {
    uint256 private _favoriteNumber;

    function store(uint256 favoriteNumber) public override {
        _favoriteNumber = favoriteNumber;
    }

    function retrieve() public view override returns (uint256) {
        return _favoriteNumber;
    }
}