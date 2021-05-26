/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Canvas {
    event Painted(address, uint x, uint y, uint8 r, uint g, uint b);
    struct Color {
        uint8 r;
        uint8 g;
        uint8 b;
    }
    uint constant SIZE = 1000;
    uint timeout = 20;
    
    Color[SIZE][SIZE] canvas;
    mapping (address => uint) lastSubmission;
    
    function getPixel(uint x, uint y) public view returns (uint8, uint8, uint8) {
        require(0 <= x && x < SIZE && 0 <= y && y < SIZE);
        return (canvas[x][y].r, canvas[x][y].g, canvas[x][y].b);
    }
    
    function setPixel(uint x, uint y, uint8 r, uint8 g, uint8 b) public {
        require(block.timestamp >= lastSubmission[msg.sender] + timeout, "Please wait before setting another pixel");
        emit Painted(msg.sender, x, y, r, g, b);
        canvas[x][y] = Color(r,g,b);
        lastSubmission[msg.sender] = block.timestamp;
    }
}