/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract PixelArt {

    uint32[256][256] public Art;
    uint256 public pixelCost = 1000000000000000; // 0.001 ETH / pixel

    function setPixel(uint8 x, uint8 y, uint32 color) public payable {
        require(color != 0, "You cannot set a pixel to RGBA(0,0,0,0).");
        require(msg.value >= pixelCost, "You need to pay at least as much as the current pixel cost.");
        require(Art[x][y] == 0, "This pixel is already set. You can only claim new pixels.");
        Art[x][y] = color;
        pixelCost += 1000000000000000; // Increase by 0.001 ETH every time, max ~65 ETH / pixel
    }

    function payout() public {
        uint256 po = address(this).balance / 3;
        payable(0x4E16f7e909bDf802359d689000C2C6d7A560F33C).transfer(po);
        payable(0x4E16f7e909bDf802359d689000C2C6d7A560F33C).transfer(po);
        payable(0x4E16f7e909bDf802359d689000C2C6d7A560F33C).transfer(po);
    }
}