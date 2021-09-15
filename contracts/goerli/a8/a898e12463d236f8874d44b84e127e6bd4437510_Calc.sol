/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Calc {
    
    int private result;
    
    /**
     * 加法 
     */
    function add(int a, int b) public returns(int) {
        result = a + b;
        return result;
    }
    
    /**
     * 减法
     */
    function min(int a, int b) public returns(int) {
        result = a - b;
        return result;
    } 
    
    /**
     * 乘法 
     */
    function mul(int a, int b) public returns(int) {
        result = a * b;
        return result;
    }
    
    /**
     * 除法  
     */
    function div(int a, int b) public returns(int) {
        result = a / b;
        return result;
    }
    
    function getResult() public view returns(int) {
        return result;
    }
    
   
    
}