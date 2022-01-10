// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

contract Box {
    uint public val;

    // constructor(uint val) {
    //   val = _val;
    // }
    
    function initialize(uint _val) external {
        val = _val;
    }
}