/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



// File: Circle.sol

contract Circle {
    uint256 private value;

    event valueChanged(uint256 newValue);

    function store(uint256 _newValue) public {
        value = _newValue;
        emit valueChanged(_newValue);
    }

    function retrieve() public view returns(uint256) {
        return value;
    }
}