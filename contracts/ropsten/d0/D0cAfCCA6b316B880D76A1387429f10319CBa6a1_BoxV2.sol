// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract BoxV2 {
    uint public val;

    function inc() external {
        val += 1;
        if(val >= 10000) {
            val = 1;
        }
    }
}