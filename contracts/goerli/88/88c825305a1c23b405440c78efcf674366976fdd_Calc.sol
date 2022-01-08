/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.24;


contract Calc {
    int private result;

    function add(int a, int b) public returns (int c) {
        result = a + b;
        c = result;
        return c;
    }


    function min(int a, int b) public returns (int) {
        result = a - b;
        return result;
    } 


    function mul(int a, int b) public returns (int) {
        result = a * b;
        return result;
    } 

    function div(int a, int b) public returns (int) {
        result = a / b;
        return result;
    }   

    function getResult() public view returns (int) {
        return result;
    }   
}