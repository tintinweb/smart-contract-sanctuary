/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Calu{
    int private results;

    function add(int a, int b) public returns (int c) {
        results = a + b;
        c = results;
    }
    function min(int a, int b) public returns(int) {
        results = a - b ;
        return results;
    }
    function muti (int a, int b) public returns (int){
        results = a * b ;
        return results ;
    }
    function div (int a, int b) public returns (int) {
        results = a / b ;
        return results;
    }
    function getResult() public view returns (int){
        return results;
    }
}