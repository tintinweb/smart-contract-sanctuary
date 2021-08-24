/**
 *Submitted for verification at BscScan.com on 2021-08-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

contract Election {
    // Model a Candidate
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    // Read/write Candidates
    mapping(uint256 => Candidate) public candidates;

    // Store accounts that have voted
    mapping(address => bool) public voters;

    // Store Candidates Count
    uint256 public candidatesCount;

    constructor() {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
        addCandidate("Candidate 3");
        addCandidate("Candidate 4");
        addCandidate("Candidate 5");
    }

    event votedEvent(uint256 indexed _candidateId);

    function addCandidate(string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote(uint256 _candidateId) public {
        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // record that voter has voted
        voters[msg.sender] = true;

        // update candidate vote Count
        candidates[_candidateId].voteCount++;

        emit votedEvent(_candidateId);
    }
}