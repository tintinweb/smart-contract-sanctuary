/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


contract Playground {
    uint id = 34;
    
    function getId() external view returns (uint) {
        return id;
    }
    
    function setId(uint value) external {
        id = value;
    }
}