/**
 *Submitted for verification at snowtrace.io on 2021-12-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract C {
    // (2**256 - 1) + 1 = 0
    function overflow() public returns (uint256 _overflow) {
        uint256 max = 2**256 - 1;
        return max + 1;
    }
    
    // 0 - 1 = 2**256 - 1
    function underflow() public returns (uint256 _underflow) {
        uint256 min = 0;
        return min - 1;
    }
}