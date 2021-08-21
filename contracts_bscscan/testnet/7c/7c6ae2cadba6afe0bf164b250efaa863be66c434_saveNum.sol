/**
 *Submitted for verification at BscScan.com on 2021-08-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract saveNum {

    uint8 n;

    function save(uint8 num) public {
        n = num;
    }

    function get() public view returns (uint256){
        return n;
    }
}