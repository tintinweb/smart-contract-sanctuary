/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleContract {

    function addition(int256 firstValue, int256 secondValue) public pure returns (int256){
        return firstValue + secondValue;
    }
    
    function subtract(int256 firstValue, int256 secondValue) public pure returns (int256){
        return firstValue - secondValue;
    }
    
    function multiply(int256 firstValue, int256 secondValue) public pure returns (int256){
        return firstValue * secondValue;
    }
    
    function division(int256 firstValue, int256 secondValue) public pure returns (int256){
        
        require(secondValue != 0, 'infinity');
        return firstValue / secondValue;
    }
    
    

}