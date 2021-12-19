// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 eternitySum;
    uint256 favoriteNumber;

    event storedNumber(
        uint256 indexed oldNumber,
        uint256 indexed newNumber,
        address sender
    );

    function store(uint256 _favoriteNumber) public {
        emit storedNumber(favoriteNumber, _favoriteNumber, msg.sender);
        eternitySum += _favoriteNumber;
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
}