/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract calc {
    int private result;
    
    function add(int a,int b) public returns(int c) {
        result = a + b;
        c = result ;
    }
    
    function sub(int a, int b) public returns(int) {
        result = a-b;
        return result;
    }
    
    function mut(int a ,int b) public returns(int){
        result = a * b;
        return result;
    }
    
    function div(int a,int b) public returns(int){
        result= a / b;
        return result;
    }
    
    function getresult() public view returns(int) {
        return result;
    }
}