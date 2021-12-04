/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SumContract {
    uint256 private a;

    constructor(uint256 _a) {
        a = _a;
    }

    function makeSum(uint256 b) public view returns (uint256) {
        return a + b;
    }

    function changeA(uint256 _a) public {
        a = _a;
    }
}