/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

/* SPDX-License-Identifier: MIT */

pragma solidity ^0.8.9;

contract Staking {
    event ClaimRewards(address indexed user, string txn, string ev);
    event Unstake(address indexed user, string txn, string ev);

    constructor() {}

    function claimRewards(string memory txn) public {
        emit ClaimRewards(msg.sender, txn, "CLAIM_REWARDS");
    }

    function unstake(string memory txn) public {
        emit Unstake(msg.sender, txn, "UNSTAKE");
    }
}