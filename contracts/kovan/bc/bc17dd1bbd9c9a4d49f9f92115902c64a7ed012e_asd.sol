/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract asd {
    function f1() external pure returns(uint256, uint256) {
        return(1, 2);
    }
    
    function f2() external pure returns(uint256 a, uint256 b) {
        a = 1;
        b = 2;
    }
}