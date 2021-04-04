/**
 *Submitted for verification at Etherscan.io on 2021-04-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MNFT_test {


    event ChangeColor(uint16 indexed x, uint16 indexed y, uint16 color);

    function changeColor(uint16 x, uint16 y, uint16 color) public {
        emit ChangeColor(x, y, color);
    }
}