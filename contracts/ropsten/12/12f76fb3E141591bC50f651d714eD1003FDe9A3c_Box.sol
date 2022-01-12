/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/*
proxy --> implementation
  ^
  |
  | 
proxy admin
*/

contract Box {
    uint public val1;

    // constructor(uint _val) {
    //     val = _val;
    // }

    function initialize(uint _val) external {
        val1 = _val;
    }
}