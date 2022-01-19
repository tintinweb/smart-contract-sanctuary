// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Test {
    constructor(string memory _test) {
        seed = (uint(keccak256(abi.encodePacked(_test))) % 100);
    }

    uint256 public seed;
}