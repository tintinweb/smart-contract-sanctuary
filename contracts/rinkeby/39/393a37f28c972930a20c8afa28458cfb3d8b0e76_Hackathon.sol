/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;


contract Hackathon {
    function getSender() public view returns (address) {
        return msg.sender;
    }

    function getCoinbase() public view returns (address) {
        return block.coinbase;
    }

    function getDifficulty() public view returns (uint256) {
        return block.difficulty;
    }

    function getGaslimit() public view returns (uint256) {
        return block.gaslimit;
    }

    function getTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function testNextToken() public view returns (uint256) {
        uint256 maxIndex = 7000 - 1587;
        uint256 random = uint256(keccak256(
            abi.encodePacked(
                msg.sender,
                block.coinbase,
                block.difficulty,
                block.gaslimit,
                block.timestamp
            )
        )) % maxIndex;

        uint256 value = random;
        return value;
    }
}