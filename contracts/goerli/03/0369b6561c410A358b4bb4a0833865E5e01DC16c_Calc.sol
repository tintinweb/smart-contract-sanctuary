/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
contract Calc{    
    int private number;

    function sum(int a, int b) public returns(int) {
        number = a + b;
        return number;
    }

    function sub(int a, int b) public returns (int) {
        number = a - b;
        return number;
    }
    
    function mult(int a, int b) public returns(int) {
        number = a * b;
        return number;
    }

    function div(int a, int b) public returns(int) {
        number = a / b;
        return number;
    }

    function getData() public view returns(int){
           return number;
    }
}