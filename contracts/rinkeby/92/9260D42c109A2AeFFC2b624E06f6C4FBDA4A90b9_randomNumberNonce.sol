/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract randomNumberNonce {
    
    uint internal nonce = 9123852;
    
    function increaseNonce() public {
        uint _rand = uint(keccak256(abi.encodePacked(block.timestamp, block.number, block.difficulty, msg.sender, nonce))) % 100;
        nonce += _rand;
    }
    
    
}