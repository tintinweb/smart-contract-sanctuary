/**
 *Submitted for verification at BscScan.com on 2022-01-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.9.0;

contract HelloWorld {
    int private result;
    function helloWorld() external pure returns (string memory) {
        return "Hello, World!";
    }
    function add(int a,int b) public returns (int c){
        result =a-b;
        return result;
    }
}