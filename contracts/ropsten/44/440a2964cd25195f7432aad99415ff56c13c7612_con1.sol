/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract con1 {
    uint256 value;
    constructor(){

    }

    function add(uint256 _value)public {
        value+=_value;
    }
    function sub(uint256 _value)public {
        value -=_value;
    }
}