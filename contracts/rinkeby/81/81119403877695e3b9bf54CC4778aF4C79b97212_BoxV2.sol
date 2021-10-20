/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



// File: BoxV2.sol

contract BoxV2 {
    uint256 private value;
    uint256 private novalue;

    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue, uint256 nonewValue);

    // Stores a new value in the contract
    function store(uint256 newValue, uint256 nonewValue) public {
        value = newValue;
        novalue = nonewValue;
        emit ValueChanged(newValue, nonewValue);
    }

    // Reads the last stored value
    function retrieve() public view returns (uint256, uint256) {
        return (value, novalue);
    }

    // Increments the stored value by 1
    function increment() public {
        value = value + 1;
        novalue = novalue * 2;
        emit ValueChanged(value, novalue);
    }
}