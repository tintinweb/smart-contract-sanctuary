/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Pixels {
    
    struct Pixel {
        uint8 r;
        uint8 g;
        uint8 b;
    }
    
    uint constant width = 10;
    uint constant height = 10;
    uint constant bufferSize = width * height;

    Pixel[bufferSize] public canvas;

    address payable public creator;

    // Payable constructor can receive Ether
    constructor() payable {
        creator = payable(msg.sender);
        
        for (uint i = 0; i < bufferSize; i++) {
            canvas[i] = Pixel(0,0,0);
        }
    }


    function setPixel(uint8 index, uint8 r, uint8 g, uint8 b) public {
        canvas[index].r = r;
        canvas[index].g = g;
        canvas[index].b = b;
    }

    function getCanvas() public view returns (Pixel[bufferSize] memory) {
        return canvas;
    }

}