/**
 *Submitted for verification at BscScan.com on 2022-01-06
*/

// contracts/BoxV3.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
 
contract BoxV4 {
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
        value = value + 2; // v4 increments with 4
        emit ValueChanged(value);
    }
	
    function retrieveDouble() public view returns (uint256) {
        return value * 2;
    }
}