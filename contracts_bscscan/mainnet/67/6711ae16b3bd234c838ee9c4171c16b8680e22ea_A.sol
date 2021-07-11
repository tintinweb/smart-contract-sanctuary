/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract A {
    uint x;
    constructor(uint _x) {
        x = _x;
    }
    function get() external view returns (uint) {
        return x;
    }
    function set(uint _x) external {
        x = _x;
    }
}