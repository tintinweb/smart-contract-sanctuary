/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

// contracts/BoxV2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
 
contract BoxV2 {
    uint256 private value;
 
    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue, uint256 oldValue);
 
    // Stores a new value in the contract
    function store(uint256 newValue) public {
        uint256 oldValue = value;
        value = newValue;
        emit ValueChanged(newValue, oldValue);
    }
    
    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }
    
    // Increments the stored value by 1
    function increment() public {
        uint256 oldValue = value;
        value = value + 1;
        emit ValueChanged(value, oldValue);
    }
}