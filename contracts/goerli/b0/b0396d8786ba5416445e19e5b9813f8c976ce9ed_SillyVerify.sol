/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract SillyVerify {

    uint number = 0;
    
    constructor() {
        number = 1;
    }

    function getOwner() external view returns (uint) {
        return number;
    }
}