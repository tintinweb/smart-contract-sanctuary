/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ContractB {
    uint256 public storedValue;
    
    enum Operator {Addition, Subtraction}
    
    constructor() {}
    
    function calculateValue(uint256 _value, Operator _operator) external returns (uint256 returnedValue) {
        if(_operator == Operator.Addition) {
            return storedValue += _value;
        }
        else if(_operator == Operator.Subtraction) {
            if(storedValue > _value) {
                return storedValue -= _value;
            }
            else 
                return 0;
        }
    }
}