// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Storage {
    uint256 public value = 0;

    function setValue(uint256 _value) external {
        value = _value;
    }
}