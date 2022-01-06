/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// contracts/BoxV2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
 
contract BoxV3 {
    uint256 private value;
 
    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);
 
    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }
    
    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }
    
    // Increments the stored value by 1
    function increment() public {
        value = value + 2; // v3 increments with 2
        emit ValueChanged(value);
    }
}