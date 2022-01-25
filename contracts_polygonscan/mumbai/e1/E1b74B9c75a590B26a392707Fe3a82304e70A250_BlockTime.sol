// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BlockTime {
    uint256 lastBlockNumber;
    uint256 lastBlockTime;

    constructor() {
        lastBlockNumber = block.number;
        lastBlockTime = block.timestamp;
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
        blocks = block.number - lastBlockNumber;
        time = block.timestamp - lastBlockTime;
        timePerBlock = time / blocks;
    }
}