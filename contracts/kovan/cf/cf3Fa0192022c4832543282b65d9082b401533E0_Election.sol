/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;



// File: SimpleVoting.sol

contract Election {
    mapping(string => uint256) voteCount;

    string[] candidates;

    mapping(string => int256) listCandidates; // Candidate checker

    struct Voters {
        string name;
        bool hasVoted;
    }

    mapping(address => Voters) voters;

    address owner;

    constructor() {
        owner = msg.sender;
    }

    function addCandidates(string memory _candidateName) public {
        // require(msg.sender == owner, "You are not allowed to add a new candidate!");
        candidates.push(_candidateName);
        voteCount[_candidateName] = 0;
        listCandidates[_candidateName] = 0;
    }

    function getCandidates() public view returns (string[] memory) {
        return candidates;
    }

    function getVoteCounts(string memory _candidateName)
        public
        view
        returns (uint256)
    {
        require(listCandidates[_candidateName] >= 0, "Candidate not found!");
        return voteCount[_candidateName];
    }

    function registerVoters(string memory _votersName) public {
        voters[msg.sender] = Voters(_votersName, false);
    }

    function setVote(string memory _candidateName) public {
        require(
            voters[msg.sender].hasVoted == false,
            "You're only allowed to vote once!"
        ); // Check if the voter has voted or not
        require(listCandidates[_candidateName] >= 0, "Candidate not found!"); // Checks if the candidate is in the list

        voteCount[_candidateName] += 1;
        voters[msg.sender].hasVoted = true; // Updates the status of the voter
    }
}