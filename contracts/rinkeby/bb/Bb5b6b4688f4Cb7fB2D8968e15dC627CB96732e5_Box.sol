// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
 
contract Box {
    uint256 private value;
    uint public freeMe;
    uint public freeMeAGain;
 
    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);
 
    // Stores a new value in the contract
    function store(uint256 newValue) public {
        freeMe = 1;
        freeMeAGain = 888;
        value = newValue;
        emit ValueChanged(newValue);
    }
 
    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }
}

