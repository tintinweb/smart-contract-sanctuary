// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BlockTime {
    uint256 public immutable blockNumber;
    uint256 public immutable blockTime;

    constructor() {
        blockNumber = block.number;
        blockTime = block.timestamp;
    }

    function getInfo()
        external
        view
        returns (
            uint256 blocks,
            uint256 time,
            uint256 timePerBlock
        )
    {
        blocks = block.number - blockNumber;
        time = block.timestamp - blockTime;
        timePerBlock = time / blocks;
    }
}