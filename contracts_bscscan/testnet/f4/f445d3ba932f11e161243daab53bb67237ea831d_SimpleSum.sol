/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleSum {
    uint256 private initialAmount;

    constructor(uint256 _initialAmount) {
        initialAmount = _initialAmount;
    }

    function makeSum(uint256 _additionalValue) public view returns (uint256) {
        return initialAmount + _additionalValue;
    }
}