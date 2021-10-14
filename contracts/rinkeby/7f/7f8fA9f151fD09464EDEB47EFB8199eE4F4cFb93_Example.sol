// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Example {
    function getBlockDifficulty() public view returns (uint256 difficulty) {
        return block.difficulty;
    }

    function getBlockTimestamp() public view returns (uint256 timestamp) {
        return block.timestamp;
    }

    function getBlockNumber() public view returns (uint256 number) {
        return block.number;
    }
}