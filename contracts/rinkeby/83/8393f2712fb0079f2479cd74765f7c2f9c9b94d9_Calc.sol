/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: MIT // 程式碼授權，不開放寫：UNLICENSED

pragma solidity >=0.7.0 <0.9.0; //  Version Pragma

contract Calc {
    int private result;
    function add(int a, int b) public returns (int c) {
        result = a + b;
        c = result;
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