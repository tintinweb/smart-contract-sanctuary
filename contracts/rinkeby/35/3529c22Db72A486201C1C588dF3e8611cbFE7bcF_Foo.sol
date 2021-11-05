/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;



// File: Foo.sol

// This is a contract to test Cobo Module's access control to different functions.
contract Foo {
    int256 public result;
    uint256 public unsigned_result;

    constructor() {
        result = 0;
        unsigned_result = 0;
    }

    function increment(int256 delta) public returns (int256) {
        result += delta;
        return result;
    }

    function decrement(int256 delta) public returns (int256) {
        result -= delta;
        return result;
    }

    function add(uint256 a, bool double) public returns (uint256) {
        if (double) {
            a = a * 2;
        }
        unsigned_result += a;
        return unsigned_result;
    }

    function substract(uint256 a, bool double) public returns (uint256) {
        if (double) {
            a = a * 2;
        }
        unsigned_result -= a;
        return unsigned_result;
    }
}