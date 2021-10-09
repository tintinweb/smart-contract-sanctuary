/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract Calculator {
    uint256 public calculateResult;
    
    address public user;
    
    event Add(uint256 a, uint256 b);
    
    function add(uint256 a, uint256 b) public returns (uint256) {
        calculateResult = a + b;
        assert(calculateResult >= a);
        
        emit Add(a, b);
        user = msg.sender;
        
        return calculateResult;
    }
}