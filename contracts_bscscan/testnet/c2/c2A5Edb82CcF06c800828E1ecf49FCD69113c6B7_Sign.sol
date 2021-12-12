// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Sign{
    constructor(){

    }
    function testRecovery(bytes32 h, uint8 v, bytes32 r, bytes32 s) public returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = sha256(abi.encodePacked(prefix, h));
        address addr = ecrecover(prefixedHash, v, r, s);
        return addr;
    }
}