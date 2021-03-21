/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;


contract Test {
    uint public bla1;
    uint public bla2;
    constructor(uint x1, uint x2) public {
        bla1 = x1;
        bla2 = x2;
    }
}


contract Test2 {
    address public base;

    constructor() public {
        setupBases();
    }

    function setupBases() private {
        base = address(new Test(10, 20));
    }
}