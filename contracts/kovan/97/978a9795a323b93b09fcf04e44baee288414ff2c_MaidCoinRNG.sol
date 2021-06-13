/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

interface IRNG {
    function generateRandomNumber(uint seed) external returns (uint);
}

contract MaidCoinRNG is IRNG {

    uint private nonce = 0;
    uint public last = 0;
    
    function generateRandomNumber(uint seed) external override returns (uint) {
        nonce += 1;
        last = uint(keccak256(abi.encodePacked(nonce, msg.sender, block.timestamp, seed, block.difficulty, blockhash(block.number - 1))));
        return last;
    }
}