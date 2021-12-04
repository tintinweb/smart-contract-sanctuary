/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleSum {
    uint256 private lhs;

    constructor(uint256 _lhs) {
        lhs = _lhs;
    }

    function addition(uint256 rhs) public view returns (uint256) {
        return lhs + rhs;
    }

    function setLhs(uint256 _lhs) public {
        lhs = _lhs;
    }
}