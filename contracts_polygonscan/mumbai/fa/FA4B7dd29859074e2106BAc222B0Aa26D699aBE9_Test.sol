/**
 *Submitted for verification at polygonscan.com on 2021-11-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Test {
    constructor() public {}

    uint256 testVar = 2;

    function test1(uint256 a, uint256 b) external {
        testVar = a + b;
    }

    function test2() external view returns (uint256) {
        return testVar;
    }
}