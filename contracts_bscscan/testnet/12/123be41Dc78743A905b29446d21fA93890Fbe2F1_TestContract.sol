/**
 *Submitted for verification at BscScan.com on 2022-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract TestContract {    
    struct Test {
        uint a;
        uint b;
        address c;
    }

    Test _s;

    function set(Test calldata test) public {
        _s = test;
    }

    function get() public view returns (Test memory) {
        return _s;
    }
}