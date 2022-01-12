/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

contract Sample {
    uint data;

    function set(uint d) public{
        data = d;
    }

    function get() public view returns (uint retVal) {
        return data;
    }
}