//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Box {
    uint public val;
    // constructor(uint _val) {
    //     val = _val;
    // }
    function initialize(uint _val) external {
        val = _val;
    }
}