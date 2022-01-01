/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10 <0.9.0;

contract IfElse {

    // if-else if-else 演示
    function foo (uint x) public pure returns (uint) {
        if (x < 10)
            return 0;
        else if (x < 20)
            return 1;
        else
            return 2;
    }

    // 三元運算演示
    function ternary(uint x) public pure returns (uint) {
        return x < 10 ? 1 : 2;
    }
}