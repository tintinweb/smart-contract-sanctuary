/**
 *Submitted for verification at polygonscan.com on 2021-09-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract keccak256test {

    uint256 private randomness = 33460119325770247208570740760376160932469616633150973181175525115068122330156;
    mapping(uint => uint) public cards;

    function randomCards(uint256 testCount) public {
        for (uint256 i = 0; i < 52; i++) {
            cards[i] = 0;
        }

        expand(randomness, testCount);
    }

    function expand(uint256 randomValue, uint256 n) private {
        uint256 i = 0;
        while(i < n) {
            uint256 expandedValue = uint256(keccak256(abi.encode(randomValue, i)));
            uint256 cardVal = (expandedValue % 52);
            i++;

            cards[cardVal] +=1;
        }
    }
}