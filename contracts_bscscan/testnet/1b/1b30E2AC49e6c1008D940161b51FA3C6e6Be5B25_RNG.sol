/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

contract RNG{
    uint256 private lastnr=0;
    uint256 private constant MAX = ~uint256(0) / 10;
    function rng() external returns(uint256){
        uint256 rn = (uint256(keccak256(abi.encodePacked(msg.sig, block.difficulty, block.timestamp,lastnr)))) % MAX;
        lastnr = rn;
        return rn;
    }
}