/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

pragma solidity >=0.7.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

contract Calculator {
    
    enum MathOperator { Add, Subtract, Multiply, Divide }
    struct MathOperation {
        int128 digit1;
        int128 digit2;
        string operator;
        int256 result;
    }
    
    MathOperation[] operations;

    
    function getOperations() public view returns(MathOperation[] memory) {
        return operations;
    }

    function add(int128 digit1, int128 digit2) public returns(int256) {
        return createOperation(digit1, digit2, MathOperator.Add);
    }
    
    function subtract(int128 digit1, int128 digit2) public returns(int256) {
        return createOperation(digit1, digit2, MathOperator.Subtract);
    }
    
    function multiply(int128 digit1, int128 digit2) public returns(int256) {
        return createOperation(digit1, digit2, MathOperator.Multiply);
    }
    
    function divide(int128 digit1, int128 digit2) public returns(int256) {
        return createOperation(digit1, digit2, MathOperator.Divide);
    }
    
    function createOperation(int128 digit1, int128 digit2, MathOperator operator) internal returns(int256) {
        int256 result;
        string memory operatorSymbol;
        if (operator == MathOperator.Add) {
            result = digit1 + digit2;
            operatorSymbol = '+';
        } else if (operator == MathOperator.Subtract) {
            result = digit1 - digit2;
            operatorSymbol = '-';
        } else if (operator == MathOperator.Multiply) {
            result = digit1 * digit2;
            operatorSymbol = '*';
        } else if (operator == MathOperator.Divide) {
            result = digit1 / digit2;
            operatorSymbol = '/';
        }
        
        operations.push(MathOperation(digit1, digit2, operatorSymbol, result));
        return result;
    }
}