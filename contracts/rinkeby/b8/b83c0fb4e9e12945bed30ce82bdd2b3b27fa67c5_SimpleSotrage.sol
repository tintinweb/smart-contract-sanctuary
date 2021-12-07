/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/** 
 * @title Simple Storgae 
 * @dev A contract to test out solidty events 
 */

contract SimpleSotrage { 
    uint256 public favoriteNumber;
    event storedNumber( 
        uint256 indexed oldNumber, uint256 indexed newNumber, 
        uint256 bothNumbersCombined, address sender
    );

    function store(uint256 newFavoriteNumber) public{
        uint256 oldNumber = favoriteNumber; // Could also just emit before assignment and remove variable. 
        favoriteNumber = newFavoriteNumber; 
        emit storedNumber(
            oldNumber, newFavoriteNumber, 
            oldNumber + newFavoriteNumber, 
            msg.sender
        );
    }
}