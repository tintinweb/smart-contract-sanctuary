/**
 *Submitted for verification at polygonscan.com on 2021-08-22
*/

/**
 *Submitted for verification at polygonscan.com on 2021-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract TestToken {
    string public symbol;
    string public  name;
    uint8 public decimals;
 
    constructor() {
        symbol = "T";
        name = "Test";
        decimals = 18;
    }
}