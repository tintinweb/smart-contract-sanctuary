/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract Foo {
    Bar bar;
    constructor(address _bar) {
        bar = Bar(_bar);
    }
    function callBar() public {
        bar.log();
    }
}
contract Bar {
    event Log(string message);
    function log() public {
        emit Log("Bar was called");
    }
}