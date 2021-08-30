/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract Calc{
    int private result;
    
    function add(int a, int b) public returns(int c){
        result=a+b;
        c=result;
    }
    
    function mul(int a,int b) public returns(int){
        result=a*b;
        return result;
    }
    
    function getResult() public view returns(int){
        return result;
    }
}