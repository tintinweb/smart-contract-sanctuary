/**
 *Submitted for verification at Etherscan.io on 2021-07-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.8.0;

contract Calc{
    int private resutl;
    
    function add(int a,int b) public returns(int c){
        resutl = a + b;
        c = resutl;
    }
    
    function min(int a,int b) public returns(int){
        resutl = a - b;
        return resutl;
    }
    
    function mul(int a,int b) public returns(int){
        resutl = a * b;
        return resutl;
    }
    
    function div(int a,int b) public returns(int){
        resutl = a / b;
        return resutl;
    }
    
    function getResutl() public view returns(int){
        return resutl;
    }
}