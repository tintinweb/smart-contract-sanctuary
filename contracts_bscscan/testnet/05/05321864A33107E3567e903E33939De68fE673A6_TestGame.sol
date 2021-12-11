// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract TestGame {
    uint256 constant DEFAULT_DURATION = 120;
    uint256 public endTime;

    event Played(uint256 indexed gameId, address indexed shiller, uint256 latestEndTime);

    function play(uint256 gameId) external {
        endTime = block.timestamp + DEFAULT_DURATION;
        emit Played(gameId, msg.sender, endTime);
    }
}