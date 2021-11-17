/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

//SPDX-License-Identifier: UNLINCENSED
pragma solidity >=0.4.22 <0.8.0;

contract cal{
    
    int private result ;
    
    function add(int a,int b)public returns(int c){
        result = a + b;
        c = result;
        
    }
    
    function min(int a,int b)public returns(int){
        result=a-b;
        return result;
    }
    
    function cheng(int a,int b)public returns(int) {
        result=a*b;
        return result;
    }
    
    function div(int a,int b) public returns(int){
        result = a / b;
        return result;
    }
    
    function getResult()public view returns(int){
        return result;
    }
}