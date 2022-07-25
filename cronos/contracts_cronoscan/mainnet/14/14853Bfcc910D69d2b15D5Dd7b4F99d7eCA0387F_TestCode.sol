// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestCode {
    uint256 public lockUntil;

    constructor() {
        lockUntil = block.timestamp + 200 days;
    }




    
}