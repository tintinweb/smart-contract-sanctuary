/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <=0.8.0;

contract Calc {
    int private result;
    
    function add(int a, int b) public returns(int) {
        result = a + b;
        
        return result;
    } 
    
    function sub(int a, int b) public returns(int c) {
        result = a - b;
        c = result;
    }
    
    function getResult() public view returns(int) {
        return result;
    }
}