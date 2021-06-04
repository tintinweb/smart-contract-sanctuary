/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

contract SampleContract {
    uint256 private value;

    constructor(uint256 _initValue) {
        value = _initValue;
    }

    function getValue() public view returns (uint256) {
        return value;
    }

    function increaseValue(uint256 delta) public {
        value *= 4;
        value = value + delta;
    }
}