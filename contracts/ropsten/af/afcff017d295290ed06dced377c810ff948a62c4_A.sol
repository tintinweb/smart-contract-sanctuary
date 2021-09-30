/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

contract A {
    uint256 public i;

    constructor() public {
        i = 0;
    }

    function increment() external {
        i = i + 1;
    }
}