//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StorageBox {
    uint256 private storedValue;

    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);

    function store(uint256 value) public {
        storedValue = value;
        emit ValueChanged(storedValue);
    }

    function retrieve() public view returns (uint256) {
        return storedValue;
    }
}