// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Sign{
    constructor(){

    }
    function testRecovery(bytes32 h, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {

        address addr = ecrecover(h, v, r, s);
        return addr;
    }
}