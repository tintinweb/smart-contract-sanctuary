/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {
    uint256 a = 5;
    uint256 b = 10;
    uint256 public sum;
    
    function add()  public returns (uint256) {
        sum = a + b;
        
        return sum;
    }
}