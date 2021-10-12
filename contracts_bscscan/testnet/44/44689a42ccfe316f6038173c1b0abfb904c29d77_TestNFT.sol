/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestNFT {
    uint public a;
    uint public b;
    uint public c;
    
    
    constructor() {
        
    }
    
    function setData(uint256[] memory data) public {
        a = data[0];
        b = data[1];
    }
}