/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Calc {
    int private result;
    
    function add(int a, int b) public returns (int c) {
        result = a + b;
        c = result;
    }
    
    function minus(int a, int b) public returns (int) {
        result = a - b;
        return result;
    }
    
    function multiply(int a, int b) public returns (int) {
        result = a * b;
        return result;
    }
    
    function divide(int a, int b) public returns (int) {
        result = a / b;
        return result;
    }
    
    function getResult() public view returns (int) {
        return result;
    }
}