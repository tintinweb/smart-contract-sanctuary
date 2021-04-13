/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

contract Add {

    uint256 public a;
    uint256 public b;
    
    constructor() {
        
    }
    
    function add(uint256 x, uint256 y) public returns(uint256) {
        a = x;
        b = y;
        return a + b;
    }
}