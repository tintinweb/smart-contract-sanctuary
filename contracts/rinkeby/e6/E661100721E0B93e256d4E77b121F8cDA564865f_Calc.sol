/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0;

contract Calc {
    int private result;
    
    function add(int a, int b) public returns (int c) {
        result = a + b;
        c = result;
    }
    
    function sub(int a, int b) public returns (int) {
        result = a - b;
        return result;
    }
    
    function getResult() public view returns (int) {
        return result;
    }
}