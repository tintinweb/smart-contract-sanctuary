/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



// File: BoxV2.sol

contract BoxV2 {
    uint256 private value;

    event ValueChanged(uint256 newValue);

    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged((newValue));
    }

    function retrieve() public view returns (uint256) {
        return value;
    }

    function increment() public {
        value = value + 1;
        emit ValueChanged(value);
    }
}