/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// File: SimpleStorage.sol

contract SimpleStorage {
    uint256 public favouriteNumber;
    event storedNumber(
        uint256 indexed newNumber,
        uint256 indexed oldNumber,
        uint256 addedNumber,
        address sender
    );

    function store(uint256 _favouriteNumber) public {
        emit storedNumber(
            _favouriteNumber,
            favouriteNumber,
            favouriteNumber + _favouriteNumber,
            msg.sender
        );
        favouriteNumber = _favouriteNumber;
    }
}