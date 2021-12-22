// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

library Proposals {
    /**
     * Determines if a proposal published at `proposedAt` is allowed to be
     * executed taking the current share of votes given for the runner up
     * candidate into consideration.
     *
     * A proposal may be executed if one of the following conditions is met:
     * 1) if more than 14 days have passed since the proposal has been published AND
     *    if less than 10% of total votes cast for the runner up candidate
     * 2) if more than 30 days have passed since the proposal has been published AND
     *    if less than 20% of total votes cast for the runner up candidate
     * 3) if more than 90 days have passed since the proposal has been published AND
     *    if less than 30% of total votes cast for the runner up candidate
     * 4) if more than 180 days have passed since the proposal has been published.
     */
    function isExecutionAllowed(
        uint256 proposedAt,
        uint256 runnerUpCandidateVotes,
        uint256 totalVotes
    ) public view returns (bool) {
        // >14 days && <10% runner up share
        if (
            proposedAt < (block.timestamp - 14 days) &&
            runnerUpCandidateVotes < (totalVotes / 10)
        ) return true;

        // >30 days && <20% runner up share
        if (
            proposedAt < (block.timestamp - 30 days) &&
            runnerUpCandidateVotes < (totalVotes / 5)
        ) return true;

        // >90 days && <30% runner up share
        if (
            proposedAt < (block.timestamp - 90 days) &&
            runnerUpCandidateVotes < ((totalVotes * 3) / 10)
        ) return true;

        // >180 days
        if (proposedAt < (block.timestamp - 180 days)) return true;

        // default is false
        return false;
    }
}