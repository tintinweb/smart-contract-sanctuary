/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
contract Calc {
   
    int private result;
    
    function add(int a, int b) public returns(int){
        result = a + b;
        return result;
    }
    
    function min(int a, int b) public returns(int){
        result = a - b;
        return result;
    }
    
    function mul(int a, int b) public returns(int){
        result = a * b;
        return result;
    }
    
    function div(int a, int b) public returns(int){
        result = a / b;
        return result;
    }
    
    function getresult() public view returns(int){
        return result;
    }
}