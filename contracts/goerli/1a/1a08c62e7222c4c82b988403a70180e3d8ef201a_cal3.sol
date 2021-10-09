/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

//SPDX-License-Identifier:MIT
pragma solidity >=0.4.22 <0.8.0;

contract cal3{
    int private result;
    function add(int a,int b) public returns(int){
        result = a + b;
        return result;
    }
    
    function min(int a,int b)public returns (int c){
        c = a - b;
        result = c;
    }
    
    function mul(int a,int b)public returns(int){
        result = a * b;
        return result;
    }
    
    function div(int a,int b)public returns(int){
        result = a / b;
        return result;
    }
    
    function mod(int a,int b)public returns(int c){
        c = a % b;
        result = c;
    }
    
    function getResult()public view returns(int){
        return result;
    }
}