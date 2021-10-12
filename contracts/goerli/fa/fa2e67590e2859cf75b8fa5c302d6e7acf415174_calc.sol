/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract calc {
    int private result;
    
    function add(int a, int b) public returns (int c){
        result = a + b;
        c = result;
    }
    function min(int a, int b) public returns (int){
        result = a - b;
        return result;
    }
    function mul(int a, int b) public returns (int){
        result = a * b;
        return result;
    }
    function div(int a, int b) public returns (int){
        result = a / b;
        return result;
    }
    function getResult() public view returns (int){
        return result;
    }
}