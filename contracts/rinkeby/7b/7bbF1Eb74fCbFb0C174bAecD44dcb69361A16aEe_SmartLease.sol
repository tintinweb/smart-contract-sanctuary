/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// File: SmartLease.sol

contract SmartLease {
    uint256 a = 0;

    function set_a(uint256 _a) public {
        a = _a;
    }

    function get_a() public view returns (uint256) {
        return a;
    }

    function double_a() public view returns (uint256) {
        return a * 2;
    }
}