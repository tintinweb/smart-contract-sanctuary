// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Box {
    uint256 private value;
    event ValueChanged(uint256 newValue);

    // we do not have a constructor for this contract on purpose
    // we can have a initializer here
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    function retrieve() public view returns (uint256) {
        return value;
    }
}