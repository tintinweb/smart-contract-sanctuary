/**
 *Submitted for verification at polygonscan.com on 2021-08-03
*/

// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.0;

contract DD {

    constructor()  {}
    
    function getNow() public view returns(uint256) {
        return block.timestamp;
    }
    
}