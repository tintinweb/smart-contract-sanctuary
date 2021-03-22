/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Mulmod {
    
    uint256 public constant a = 2**254;
    uint256 public constant b = 2**255;
    
    function doMul(uint256 x, uint256 y) external pure returns (uint256) {
        return x * y;
    }
    
    function doMulMod(uint256 x, uint256 y) external pure returns (uint256) {
        return mulmod(x, y, type(uint256).max);
    }
}