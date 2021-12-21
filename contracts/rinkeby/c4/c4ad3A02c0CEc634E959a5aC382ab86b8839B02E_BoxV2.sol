// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract BoxV2 {

    uint256 public testValue;
    function updateValue(uint256 _index) public {
        testValue = _index;
    }

}