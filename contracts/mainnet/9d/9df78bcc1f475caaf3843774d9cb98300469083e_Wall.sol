/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

pragma solidity 0.8.11;

// SPDX-License-Identifier: CC0

contract Wall {
    // __________________________________
    // |_____|____|_____|____|_____|____|
    // |___|____|____|_____|____|_______|
    // |____|_____|___|______|___|___|__|
    // |___|___|___| WALL |___|___|_____|
    // |____|_____not a token_____|_____|
    // |___|_____|______|_____|_____|___|
    // |________________________________|
    // .          an extremely          .
    // .    minimalistic experiment     .
    // .        size: 2¹⁶ pixels        .
    // .        anyone can paint        .
    // ..................................
    
    mapping (uint => mapping (uint8 => uint24)) public wall;
    mapping (uint8 => mapping (uint8 => address)) public artists;

    event Painted(uint8 x, uint8 y, uint24 color);

    function paint(uint8 x, uint8 y, uint24 color) public {
        require(artists[y][x] == address(0), 'cannot paint over');
        wall[y][x] = color;
        artists[y][x] = msg.sender;
        emit Painted(x, y, color);
    }

    function clean(uint8 x, uint8 y) public {
        require(artists[y][x] == msg.sender, 'not the author');
        wall[y][x] = 0;
        artists[y][x] = address(0);
        emit Painted(x, y, 0);
    }

}