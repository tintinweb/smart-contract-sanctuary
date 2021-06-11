// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./SafeMath.sol";

contract MathContract {
    uint256 currentNumber;
    event Add(uint256 indexed currentNumber);
    event Mul(uint256 indexed currentNumber);
    event Sub(uint256 indexed currentNumber);
    
    constructor() public {
        currentNumber = 1;
    }
    
    function addToCurrentNumber(uint256 _toAdd) public returns(uint256) {
        currentNumber = SafeMath.add(currentNumber, _toAdd);
        emit Add(currentNumber);
        return currentNumber;
    }
    
    function mulToCurrentNumber(uint256 _toMul) public returns(uint256) {
        currentNumber = SafeMath.mul(currentNumber, _toMul);
        emit Mul(currentNumber);
        return currentNumber;
    }
    
    function subtractCurrentNumber(uint256 _toSub ) public returns(uint256) {
        currentNumber = SafeMath.sub(currentNumber, _toSub);
        emit Sub(currentNumber);
        return currentNumber;
    }
    
    function getCurrentNumber() public view returns(uint256) {
        return currentNumber;
    }
}