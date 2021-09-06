/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract DeployingTest {
    uint256 public immutable _CACHED_CHAIN_ID;

    constructor() {
        _CACHED_CHAIN_ID = block.chainid;
    }
}