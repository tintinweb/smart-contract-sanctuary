// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./SafeMath.sol";

contract MathContract {
    uint256 currentNumber;
    
    constructor() public {
        currentNumber = 1;
    }
    
    function addToNumber(uint256 _toAdd) public returns(uint256) {
        currentNumber = SafeMath.add(currentNumber, _toAdd);
        return currentNumber;
    }
    
    function mulToNumber(uint256 _toMul) public returns(uint256) {
        currentNumber = SafeMath.mul(currentNumber, _toMul);
        return currentNumber;
    }
    
    function getCurrentNumber() public view returns(uint256) {
        return currentNumber;
    }
}