/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;

contract Calc {
    int private result;
    
    function add(int a, int b) public returns(int c) {
        result =a + b;
        c = result;
    }
    
    function sub(int a, int b) public returns(int) {
        result =a - b;
        return result;
    }
    
    function getResult() public view returns(int) {
        return result;
    }
    
}