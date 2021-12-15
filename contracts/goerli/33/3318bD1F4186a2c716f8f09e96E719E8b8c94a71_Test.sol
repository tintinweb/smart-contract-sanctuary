/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Test {
    string str;

    function readTest(string[] memory strs) public pure returns(string[] memory results, uint length) {
        length = strs.length;
        results = new string[](length);

        uint  index = 0;
        for (uint i = length ; i > 0 ; i--) {
            results[index++] = strs[i - 1];
        }
    }

    function writeTest(string memory _str) public returns(bool, string memory) {
        str = _str;
        return (true, str);
    }

    function paramTest(bytes32[] memory _bytes) public pure returns(bytes16, bytes16) {
        bytes16 b1 = bytes16(_bytes[0]);
        bytes16 b2 = bytes16(_bytes[0] >> 128);

        return (b1, b2);
    }

    function f(uint8[] memory u) public pure returns(uint) {
        uint total = 0;
        for (uint i = 0 ; i < u.length ; i++) {
            total += u[i];
        }

        return total;
    }
}