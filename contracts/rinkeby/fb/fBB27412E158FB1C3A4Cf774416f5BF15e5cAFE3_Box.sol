/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Box {
    uint256 private value;
    address public owner;
 
    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);
 
    // Stores a new value in the contract
    function store(uint256 newValue, address _owner) public {
        value = newValue;
        owner = _owner;
        emit ValueChanged(newValue);
    }
 
    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }
}