// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract BoxTestV2 {
    uint public val;

    // function initialize(uint _val) external {
    //     val = _val;
    // }

    uint public testVal;

    function inc() external {
        val += 1;
    }

    function set() external {
        testVal = 3;
    }
}