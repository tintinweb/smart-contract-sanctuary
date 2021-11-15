// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

contract Test {
    function test() view external returns(uint[] memory value) {
        value = new uint[](10);
        value[0] = 1;
        value[1] = 2;
    }
}

