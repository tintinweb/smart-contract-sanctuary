/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract SimpleCalculator {
    int private result;

    function plus(int a, int b) public returns (int) {
        result = a + b;
        return result;
    }

    function subtract(int a, int b) public returns (int) {
        result = a - b;
        return result;
    }

    function multiply(int a, int b) public returns (int) {
        result = a * b;
        return result;
    }

    function getResult() public view returns (int) {
        return result;
    }
}