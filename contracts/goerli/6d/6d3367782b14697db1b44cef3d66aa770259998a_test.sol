/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract test {
    event print1 (uint);
    event print2 (uint[]);
    
    uint xyz;

    function eventLoop1(uint[] memory nums) external {
        for (uint i = 0; i < nums.length; i++) {
            xyz = i;
            emit print1(i);
        }
    }
    
    function eventLoop2(uint[] memory nums) external {
        for (uint i = 0; i < nums.length; i++) {
            xyz = i;
        }
        emit print2(nums);
    }
}