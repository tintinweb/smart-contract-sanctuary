/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
contract Test {
    struct A {
        uint a;
        uint b;
        uint c;
    }
    A public a;

    constructor() {
        a.a = 1;
        a.b = 2;
        a.c = 3;
    }

    function test0() external {
        a.a = 4;
        a.b = 5;
    }

    function test1() external {
        A memory b = a;
        b.a = 6;
        b.c = 7;
        a = b;
    }
}