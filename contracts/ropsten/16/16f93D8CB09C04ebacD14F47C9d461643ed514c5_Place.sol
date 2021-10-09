/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Place {
    
    struct PixelMetadata {
        uint blocknum;
        address author;
        address owner;
    }

    uint8[64] pixels;

    /**
     * @dev Store value in variable
     * @param offset location to store
     * @param color color to store
     */
    function store(uint offset, uint8 color) public {
        pixels[offset] = color;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint8[64] memory){
        return pixels;
    }
}