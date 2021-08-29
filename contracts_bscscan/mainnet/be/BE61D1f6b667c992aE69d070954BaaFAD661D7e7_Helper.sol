/**
 *Submitted for verification at BscScan.com on 2021-08-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Helper {

    function getNow() public view returns(uint) {
        return block.timestamp;
    }
    
}