/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Test {

    uint256 public value;

    function read(uint256 arg1, uint256 arg2) external pure returns(uint256 ret1, uint256 ret2) {
        ret1 = arg1 + 1;
        ret2 = arg2 + 1;
    }

    function write(uint256 arg1, uint256 arg2) external returns (uint256 ret1, uint256 ret2)   {
        value = arg1;
        ret1 = arg1 + 1;
        ret2 = arg2 + 1;
    }
}