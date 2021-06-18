/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TestContract {
    
    int currentNumber;
    
    constructor() {
        currentNumber = 0;
    }
    
    function test1(bytes calldata a) public returns (int) {
        currentNumber ++;
    }
}