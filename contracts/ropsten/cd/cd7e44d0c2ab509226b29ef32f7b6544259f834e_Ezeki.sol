/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Ezeki {
    constructor() {}

    function sayHi() public pure returns (string memory) {
        return "Hello World";
    }

    function sum(int256 a, int256 b) public pure returns (int256) {
        return a + b;
    }
}