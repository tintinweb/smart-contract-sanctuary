/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.0 <0.9.0;

contract Calc {
    int private result;

    function add(int a, int b) public returns(int c) {

        result = a + b;

        c= result;
    }

    function min(int a, int b) public returns(int c) {

        result = a - b;

        c= result;
    }

    function mul(int a, int b) public returns(int c) {

        result = a * b;

        c= result;
    }

    function div(int a, int b) public returns(int c) {

        result = a / b;

        c= result;
    }

    function getResult() public view returns(int) {

        return result;
    }


}