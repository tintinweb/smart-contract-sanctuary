// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Sign{
    constructor(){

    }
    function testRecovery(string memory message1, string memory message2, string memory message3, string memory message4, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
        bytes32 h = keccak256(abi.encodePacked(message1, message2, message3, message4));
        address addr = ecrecover(h, v, r, s);
        return addr;
    }
}