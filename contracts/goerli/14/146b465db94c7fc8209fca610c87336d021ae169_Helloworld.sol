/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity  >=0.7.0 <0.8.0;

contract Helloworld{
    int private result;
    
    function add(int a,int b) public returns(int c) {
        result = a + b;
        c =result;
    }
    
    function sub(int a ,int b) public returns(int ){
        result= a*b;
        return result;
    }
    
    function cheng(int a,int b) public returns(int){
        result = a*b;
        return result;
    }
    
    function chu(int a, int b) public returns(int){
        result = a*b;
        return result;
    }
    
    function getResult() public view returns(int) {
        return result;
    }
}