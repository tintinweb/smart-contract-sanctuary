/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

contract DrawIndex {

    uint256 public remaining = 1000;

    mapping(uint256 => uint256) public cache;

    function drawIndex() public returns (uint256) {
        uint256 index;
        //RNG
        uint256 i = uint(blockhash(block.number - 1)) % remaining;

        // if there's a cache at cache[i] then use it
        // otherwise use i itself
        index = cache[i] == 0 ? i : cache[i];

        // grab a number from the tail
        cache[i] = cache[remaining - 1] == 0 ? remaining - 1 : cache[remaining - 1];
        remaining = remaining - 1;
        return index;
    }

    function drawNCards(uint256 n) public returns (uint256[] memory) {
        uint256[] memory cards = new uint256[](n);
        for (uint i=0; i<n; i++) {
            cards[i] = uint256(drawIndex());
        }
        return cards;
    }
}