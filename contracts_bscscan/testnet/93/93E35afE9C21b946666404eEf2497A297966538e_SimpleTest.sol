// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract SimpleTest {
    uint public x;
    constructor(uint a) payable {
        x = a;
    }
}

