// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library TestLib {
    function isEqual(uint256 a, uint256 b) public pure returns (bool) {
        return a == b;
    }

    function xor(bytes32[] memory _proof) public pure returns (bytes32) {
        bytes32 x = 0;
        for (uint256 i = 0; i < _proof.length; i++) {
            x = x ^ _proof[i];
        }
        return x;
    }
}

contract LibTest {
    uint256 public v;

    function set(uint256 prev, uint256 next) public returns (bool) {
        if (TestLib.isEqual(v, prev)) {
            v = next;
            return true;
        }

        return false;
    }

    function checkXor(bytes32[] memory _proof) public {
        v = uint256(TestLib.xor(_proof));
    }
}