/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Test {
    function get() public view  returns (uint256) {
        return block.timestamp;
    }
}