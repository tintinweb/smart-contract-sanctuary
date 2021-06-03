/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Maths {
    uint256 public lastAdd;
    uint256 public lastSub;
    uint256 public lastMul;
    uint256 public lastDiv;

    event Add(uint256 value);
    event Sub(uint256 value);
    event Mul(uint256 value);
    event Div(uint256 value);

    constructor() public {
        lastAdd = 0;
        lastSub = 0;
        lastMul = 0;
        lastDiv = 0;
    }

    function addNum(uint256 a, uint256 b) public returns (bool) {
        require(a != 0 && b != 0, "a & b must be different 0");
        lastAdd = a + b;
        emit Add(lastAdd);
        return true;
    }

    function getAddNum() public view returns (uint256) {
        return lastAdd;
    }

    function subNum(uint256 a, uint256 b) public returns (bool) {
        require(a > b, "a must be > b");
        lastSub = a - b;
        emit Sub(lastSub);
        return true;
    }

    function getSubNum() public view returns (uint256) {
        return lastSub;
    }

    function mulNum(uint256 a, uint256 b) public returns (bool) {
        require(a != 0 && b != 0, "a & b must be different 0");
        lastMul = a * b;
        emit Mul(lastMul);
        return true;
    }

    function getMulNum() public view returns (uint256) {
        return lastMul;
    }

    function divNum(uint256 a, uint256 b) public returns (bool) {
        require(a > b, " a must be gerther than b");
        lastDiv = a / b;
        emit Div(lastDiv);
        return true;
    }

    function getDiv() public view returns (uint256) {
        return lastDiv;
    }
}