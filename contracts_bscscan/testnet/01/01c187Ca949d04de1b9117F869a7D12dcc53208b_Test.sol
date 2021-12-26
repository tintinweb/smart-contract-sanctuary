/**
 *Submitted for verification at BscScan.com on 2021-12-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

error TestError(address user);

contract Test {
    function test() external {
        revert TestError(msg.sender);
    }
}