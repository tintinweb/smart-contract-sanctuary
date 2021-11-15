// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Test {
    constructor() {}
    
    function get() public view  returns (uint256) {
        return block.timestamp;
    }
}

