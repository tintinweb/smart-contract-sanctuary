/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

library Proposals {
    function isExecutionAllowed(
        uint256 proposedAt,
        uint256 runnerUpCandidateVotes,
        uint256 totalVotes
    ) public view returns (bool) {
        if (
            proposedAt < (block.timestamp - 14 days) &&
            runnerUpCandidateVotes < (totalVotes / 10)
        ) return true;

        if (
            proposedAt < (block.timestamp - 30 days) &&
            runnerUpCandidateVotes < (totalVotes / 5)
        ) return true;

        if (
            proposedAt < (block.timestamp - 90 days) &&
            runnerUpCandidateVotes < ((totalVotes * 3) / 10)
        ) return true;

        if (proposedAt < (block.timestamp - 180 days)) return true;

        return false;
    }
}

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode