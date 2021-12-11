/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract DrawIndex {

    uint256 public remaining = 50;

    mapping(uint256 => uint256) public cache;

    event showRNG(uint256 i, uint256 index);

    function drawIndex() public returns (uint256 index) {
        //RNG
        uint256 i = uint(blockhash(block.number - 1)) % remaining;
        
        // if there's a cache at cache[i] then use it
        // otherwise use i itself
        index = cache[i] == 0 ? i : cache[i];

        // grab a number from the tail
        cache[i] = cache[remaining - 1] == 0 ? remaining - 1 : cache[remaining - 1];
        remaining = remaining - 1;

        emit showRNG(i, index);        
    }

}