/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Test {
    function testInt(int x, int y) public pure returns (int) {
        return (x * y);
    }
    function testInts(int[] memory x, int[] memory y) public pure returns (int[] memory) {
        int[] memory xy = new int[](x.length);
        for (uint i = 0; i < x.length; i++) {
            xy[0] = x[i] * y[i];
        }
        return xy;
    }
}