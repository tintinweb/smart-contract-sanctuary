//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleStorage2
{
    uint256 public favoriteNumber;
    event StoredNumber(
        uint256 indexed oldNumber,
        uint256 indexed newNumber,
        uint256 addedNumber,
        address sender
    );

    function store(uint256 _favoriteNumber) public {
        emit StoredNumber(favoriteNumber, 
        _favoriteNumber,
        favoriteNumber + _favoriteNumber,
        msg.sender);
        favoriteNumber = _favoriteNumber;
    }

}