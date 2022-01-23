/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.4.22 <0.8.0;

contract Calc {
    int private result;

    function add(int a, int b) public returns (int) {
        result = a + b;
        require( result >= a);
        return result;
    }

    function min(int a, int b) public returns (int) {
        require( a >= b);
        result = a - b;
        return result;
    }

    function mul(int a, int b) public returns (int) {
        result = a * b;
        require(result / a == b);
        return result;
    }

    function div(int a, int b) public returns (int) {
        require(b > 0);
        result = a / b; 
        return result;
    }

    function getResult() public view returns (int) {
        return result;
    }    
}