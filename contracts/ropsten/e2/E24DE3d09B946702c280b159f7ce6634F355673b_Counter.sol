/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
// Imagine a big integer counter that the whole world could share
contract Counter {
    uint value;
 
    function initialize (uint x) public {
        value = x;
    }
 
    function get() view public returns (uint) {
        return value;
    }
    
    function increment (uint n) public {
        value = value + n;
        return;
    }
    
    function decrement (uint n) public {
        value = value - n;
        return;
    }}