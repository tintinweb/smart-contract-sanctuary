/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.0;
        
contract threeInputsCalculator {
    int result;

    function sum(int a, int b, int c) public
    returns(int) {
        result = a + b + c;
        return result;
    }
    function subtraction(int a, int b, int c) public
    returns(int) {
        result =  a - b - c;
        return result;    
        } 
        function multiplication(int a, int b, int c) public
        returns(int) {
        result = a * b * c;
        return result;
        }
        function division(int a, int b, int c) public
        returns(int) {
            result = a / b / c;
            return result;
        }
}