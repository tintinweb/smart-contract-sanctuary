/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;
 
contract Calculator
{
    function addition(int x, int y) public pure returns(int) {return x + y;}
    function subtraction(int x, int y) public pure returns(int){return x - y;}
    function multiplication(int x, int y) public pure returns(int){return x * y; }
    function division(int x, int y) public pure returns(int) {return x / y;}
}