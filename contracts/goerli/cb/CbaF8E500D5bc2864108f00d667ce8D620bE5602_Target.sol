// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Target {
    uint public blockNumber;

    function f() external {
        if (block.timestamp % 10 == 0) {
            blockNumber = block.number;
        }
    }
}