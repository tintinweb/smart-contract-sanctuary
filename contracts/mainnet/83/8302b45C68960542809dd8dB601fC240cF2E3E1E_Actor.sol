/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Actor {
    uint8 num;

    function store(uint8 n) public {
        num = n;
    }

    function retrieve() public view returns (uint8){
        return num;
    }
}