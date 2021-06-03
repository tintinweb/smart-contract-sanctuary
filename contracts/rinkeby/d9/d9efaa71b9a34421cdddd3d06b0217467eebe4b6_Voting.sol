/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/// @title Voting contract
contract Voting {
    // This is a type for a single candidate.
    struct Candidate {
        string name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    // A dynamically-sized array
    Candidate[] public candidates;

    // Store a boolean flag for each possible address
    mapping(address => bool) public hasVoted;

    /// Run on contract deployment
    constructor(string[] memory candidateNames) {
        // Every candidate name is provided when the contract is deployed
        // Create a Candidate object and store it in the array
        for (uint i = 0; i < candidateNames.length; i++) {
            candidates.push(Candidate({
                name: candidateNames[i],
                voteCount: 0
            }));
        }
    }

    /// Submit your vote
    function vote(uint candidate) public {
        // Check the voter has not already voted.
        require(
            !hasVoted[msg.sender], 
            "Already voted."
        );

        // Increment the vote count of the candidate
        candidates[candidate].voteCount++;

        // Mark this address as having voted
        hasVoted[msg.sender] = true;
    }

    function winner() public view returns (string memory winner_){
        // Loop through candidates finding the one with the most votes
        uint largestCount = 0;
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > largestCount) {
                largestCount = candidates[i].voteCount;
                winner_ = candidates[i].name;
            }
        }
    }

}