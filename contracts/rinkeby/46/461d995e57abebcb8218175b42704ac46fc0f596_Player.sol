/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Player {
    uint256 public xCoordinate = 2;
    uint256 public yCoordinate = 1;
    event Movement(uint256 x, uint256 y);

    function moveRight() public {
        require(xCoordinate < 50, "Player can only move 50 spaces to the right");
        xCoordinate += 1;
        emit Movement(xCoordinate, yCoordinate);
    }
    
    function moveLeft() public {
        require(xCoordinate > 0, "Player can only move 50 spaces to the left");
        xCoordinate -= 1;
        emit Movement(xCoordinate, yCoordinate);
    }
    
    function moveUp() public {
        require(yCoordinate < 50, "Player can only move 50 spaces up");
        yCoordinate += 1;
        emit Movement(xCoordinate, yCoordinate);
    }

    function moveDown() public {
        require(yCoordinate > 0, "Player can only move 50 spaces down");
        yCoordinate -= 1;
        emit Movement(xCoordinate, yCoordinate);
    }
}