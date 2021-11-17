/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface TestInterface {
    function setVariables(uint256 _a, uint256 _b) external;
}

contract Example1 is TestInterface {
    
    uint256 public a;
    uint256 public b;
    
    constructor(uint256 _a, uint256 _b) {
        a = _a;
        b = _b;
    }
    
    function setVariables(uint256 _a, uint256 _b) public override {
        a = _a;
        b = _b;
    }
}