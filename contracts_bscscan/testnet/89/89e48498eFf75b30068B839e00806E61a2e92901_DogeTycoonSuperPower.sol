// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * makes use of superpowers.
 */

interface IDogeTycoonSuperPower {
    function calculateSuperPowerOutput (
        uint256 nftDetails, 
        bool isSell, 
        uint256 amount, 
        uint256 currentFee) external pure returns (uint256 newFee, bool used);
}

contract DogeTycoonSuperPower is IDogeTycoonSuperPower {

    constructor() {
    
    }

     function calculateSuperPowerOutput (
        uint256 nftDetails, 
        bool isSell, 
        uint256 amount, 
        uint256 currentFee) external override pure returns (uint256 newFee, bool used) {
        // no superpowers yet.
        return (currentFee, false);
    }
}

