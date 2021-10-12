/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.5;

contract Calu {
    int private lastResult;
    
    function add(int a, int b) public returns (int c){
        c = a + b;
        lastResult = c;
    }
    
    function min(int a, int b) public returns (int){
        lastResult = a - b;
        return lastResult;
    }
    
    function mul(int a, int b) public returns (int){
        lastResult = a - b;
        return lastResult;
    }
    
    function div(int a, int b) public returns (int){
        lastResult = a / b;
        return lastResult;
    }
    
    function getLastResult() public view returns(int){
        return lastResult;
    }
    
}