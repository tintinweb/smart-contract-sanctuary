/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Calculator{
    int private result;
    
    function add(int a,int b) public returns (int c){
        result = a + b;
        c = result;
    }
    function minus(int a, int b )public returns (int c){
        result = a - b;
        c = result;
    }
    function multiply(int a, int b) public returns (int c){
        result = a * b;
        c = result;
    }
    
    function getResult()public view returns (int){
        //view 只檢視、不更改值
        return result;
    }
}