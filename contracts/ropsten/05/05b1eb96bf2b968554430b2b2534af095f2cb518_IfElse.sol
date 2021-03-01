/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract IfElse {
    function foo(uint x) public pure returns (uint) {
        if (x < 10) {
            return 0;
        } else if (x < 20) {
            return 1;
        } else {
            return 2;
        }
    }
}