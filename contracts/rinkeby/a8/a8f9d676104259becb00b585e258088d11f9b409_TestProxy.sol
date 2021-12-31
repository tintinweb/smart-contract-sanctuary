// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestProxy {
    uint public value1;

    function setValue1(uint v) public {
        value1 = v;
    }

}