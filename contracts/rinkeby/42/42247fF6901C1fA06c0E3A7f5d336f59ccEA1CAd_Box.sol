// SPDX-License-Identifier: MIT
// # export NODE_OPTIONS=--openssl-legacy-provider

pragma solidity ^0.8.0;

contract Box {
    uint private value;

    event ValueChange(uint256 newValue);

    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChange(value);
    }
    function retrieve() public view returns(uint256) {
        return value;
    }

    
}