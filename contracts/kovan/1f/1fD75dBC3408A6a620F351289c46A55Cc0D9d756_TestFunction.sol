/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.21;

contract TestFunction {
    
    uint16 c2Ans = 0;
    constructor() public {
        c2Ans = uint16(100);
    }
    function hi() view public returns (uint16) {
        return c2Ans;
    }
}