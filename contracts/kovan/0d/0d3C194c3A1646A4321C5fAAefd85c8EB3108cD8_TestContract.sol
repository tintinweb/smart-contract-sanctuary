/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TestContract {
    
    int currentNumber;
    
    constructor() {
        currentNumber = 0;
    }
    
    function test1(uint256 a, int256 b) public returns (int) {
        int x = int(a);
        currentNumber = x - b;
        
        return currentNumber;
    }
}