/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Storage {
    uint32 number;
    function store(uint32 num) public {
        number = num;
    }
    function retrieve() public view returns (uint32){
        return number;
    }
}