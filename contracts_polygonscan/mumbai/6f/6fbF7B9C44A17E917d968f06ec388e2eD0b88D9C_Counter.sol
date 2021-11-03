/**
 *Submitted for verification at polygonscan.com on 2021-11-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Counter {
    
    uint public value;
    
    function increment() external {
        value += 1;
    }
    
    function decrement() external {
        value -= 1;
    }
}