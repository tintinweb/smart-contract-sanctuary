// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

contract HelloWorld {
    constructor() {}

    function helloWorld() external pure returns (string memory) {
        return "hello world";
    }
}

