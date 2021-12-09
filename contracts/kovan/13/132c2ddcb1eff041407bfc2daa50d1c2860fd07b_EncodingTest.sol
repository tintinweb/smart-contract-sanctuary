/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract EncodingTest {
    function encode(uint x) public pure returns (bytes memory) {
        uint a = 0x123;

        uint32[] memory b;
        b[0] = 0x456;
        b[1] = 0x789;

        bytes10 c  = "1234567890";

        bytes memory d = "Hello, world!";

        return abi.encode(a, b, c, d);
    }
}