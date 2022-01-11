/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

contract Bar {
    event Log(string message);

    function log() public {
        emit Log("Bar was called");
    }

    function MalNotExist() public {
    }
}

contract Foo {
    //  bar is private variable
    Bar bar;

    constructor(address _bar) {
        bar = Bar(_bar);
    }

    function testMalFallback() public {
        bar.MalNotExist();
    }

    function callBar() public {
        bar.log();
    }
}