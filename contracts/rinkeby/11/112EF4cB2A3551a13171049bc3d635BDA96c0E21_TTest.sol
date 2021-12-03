/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

contract TTest {
    uint256 a = 10;
    uint16 b = 5;

    constructor() {}

    function func1() external {
        a += 1;
    }

    function func2() external {
        b += 1;
    }

    function func3() external {
        a += 10;
    }

    function func4() external {
        for(uint256 i = 0; i < 10; i++) {
            a += 1;
        }
    }

    function func5() external {
        require(a > 1, "no");
        a += 1;
    }
}