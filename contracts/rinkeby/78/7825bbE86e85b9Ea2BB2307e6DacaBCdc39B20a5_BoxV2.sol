// SPDX-License-Identifier: MIT
// # export NODE_OPTIONS=--openssl-legacy-provider

pragma solidity ^0.8.0;

contract BoxV2 {
    uint private value;

    event ValueChanged(uint256 newValue);

    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    function retrieve() public view returns(uint256) {
        return value;
    }
    function increment() public {
        value = value +1;
        emit ValueChanged(value);
    }
}