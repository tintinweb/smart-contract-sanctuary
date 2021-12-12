// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Sign{
    constructor(){

    }
    function testRecovery(string memory message1, string memory message2, string memory message3, string memory message4, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
        bytes32 hmsg = keccak256(abi.encodePacked(message1, message2, message3, message4));
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hmsg));
        address addr = ecrecover(prefixedHash, v, r, s);
        return addr;
    }
}