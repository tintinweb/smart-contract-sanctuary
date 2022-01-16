/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract File1 {

    uint public num1;
    uint public num2;


    function store1(uint _num1, uint _num2) external {
        num1 = _num1;
        num2 = _num2;
    }
}