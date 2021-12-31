// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestProxy2 {
    uint public value1;
    uint public value2;

    function setValue1(uint v) public {
        value1 = v;
    }

    function setValue2(uint v) public {
        value2 = v;
    }


}