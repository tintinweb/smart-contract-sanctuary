/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Calc {
    int256 private result;
    
    function add(int256 a, int256 b) public returns(int256 c) {
        result = a+b;
        c = result;
    }
    
    function sub(int256 a, int256 b) public returns(int256 c) {
        result = a-b;
        c = result;
    }
    
    function mul(int256 a, int256 b) public returns (int256 c) {
        result = a*b;
        c = result;
    }
    
    function div(int256 a, int256 b) public returns (int256 ) {
        result = a/b;
        return result;
    }
    
    function getResult() public view returns(int256) {
        return result;
    }
}