/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.1 <0.9.0;

contract Lab6 {

    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
        bool active;
    }

    Candidate[] candidates;
    uint256 public candidateCount = 0;
    mapping(address => bool) public voted;
    
    event NewVote(uint256 indexed candidateId, address voter);

    constructor() {}

    function addCandidate(string memory _name) public {
        candidates[candidateCount] = Candidate(candidateCount, _name, 0, true);
        candidateCount += 1;
    }
    
    function showCandidates()
        view external
        returns(Candidate[] memory)
    {
        return candidates;
    }
    
    function vote(uint256 _candidateId) public {
        require(voted[msg.sender] == false, "Already Voted!");
        require(candidates[_candidateId].active == true, "Invalid Candidate!");
        voted[msg.sender] = true;
        candidates[_candidateId].voteCount += 1;
        emit NewVote(_candidateId, msg.sender);
    }

}