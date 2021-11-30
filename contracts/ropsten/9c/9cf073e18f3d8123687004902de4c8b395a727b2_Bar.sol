/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

// SPDX-License-Identifier: GPL-3.0

/*
    === TxT Test Case for SWC-123 ===

    STATUS: [complete | in progress]
    DEPLOYED AT: 0x...

    VULNERABILITY REPRODUCTION STEPS:
    1. call doubleBaz

    EXPECTED OUTCOME:
    Logically, one should be able to call doubleBaz
    with all integer values
    
    ACTUAL OUTCOME:
    You cannot call doubleBaz with values below 1

    NOTES:
    None
*/

pragma solidity >=0.7.0 <0.9.0;

contract Bar {
    Foo private f = new Foo();
    function doubleBaz() public view returns (int256) {
        return 2 * f.baz(0);
    }
}

contract Foo {
    function baz(int256 x) public pure returns (int256) {
        require(0 < x);
        return 42;
    }
}