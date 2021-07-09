/**
 *Submitted for verification at polygonscan.com on 2021-07-09
*/

// File: contracts/bob.sol

pragma solidity ^0.5.10;


contract sum {
    
    uint8 public first;
    uint8 public second;
    uint8 public result;
    
    constructor(uint8 operand1, uint8 operand2) public{
        first = operand1;
        second = operand2;
        result = first + second;
    }
    
    
    function update(uint8 operand1, uint8 operand2) public{
        first = operand1;
        second = operand2;
        result = first + second;
    }
    
}