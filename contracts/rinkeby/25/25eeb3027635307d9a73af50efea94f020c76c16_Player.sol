/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Player {
    uint256 public xCoordinate;
    uint256 public yCoordinate;

    function movePlayer(uint256 x, uint256 y) public {
        require(x <= 50, "Player can only move 50 spaces to the right");
        require(y <= 50, "Player can only move 50 spaces downwards");
        xCoordinate = x;
        yCoordinate = y;
    }
}