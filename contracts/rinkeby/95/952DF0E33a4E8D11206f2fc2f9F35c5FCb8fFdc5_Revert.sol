/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Revert {
    bool public called = false;

    function flip(uint256 pass) external {
        require(pass == 1, "RevertTesting: Incorrect Password");
        called = !called;
    }
}