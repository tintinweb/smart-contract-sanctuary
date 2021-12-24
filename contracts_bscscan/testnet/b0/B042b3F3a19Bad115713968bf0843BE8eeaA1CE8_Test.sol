// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract Test{

    uint public value;

    function increaseValue(uint v) external {
        value += v;
    }
}