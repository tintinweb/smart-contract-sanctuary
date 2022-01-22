/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// File: Box.sol

contract Box {
    uint256 private value;

    event ValueChanged(uint256 newValue);

    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    function retrieve() public view returns (uint256) {
        return value;
    }
}