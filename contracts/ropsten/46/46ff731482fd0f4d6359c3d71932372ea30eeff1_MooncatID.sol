/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

pragma solidity ^0.4.13;
contract MooncatID {
    function findCatID(bytes32 seed) constant returns (bytes5) {
        bytes32 searchSeed = 0x8363e7eaae8e35b1c2db100a7b0fb9db1bc604a35ce1374d882690d0b1d888e2;
        bytes32 catIdHash = keccak256(seed, searchSeed); // generate the prospective catIdHash
        bytes5 catId = bytes5((catIdHash & 0xffffffff) << 216); // one byte to indicate genesis, and the last 4 bytes of the catIdHash
        return catId;
    }
}