// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library TestLib {
    function isEqual(uint256 a, uint256 b) public pure returns (bool) {
        return a == b;
    }
}

contract LibTest {
    uint256 v;

    function set(uint256 prev, uint256 next) public returns (bool) {
        if (TestLib.isEqual(v, prev)) {
            v = next;
            return true;
        }

        return false;
    }
}