/**
 *Submitted for verification at Etherscan.io on 2021-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
contract Voting {
    // Model a Candidate
     struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }
    mapping(address => bool) public voters;
    mapping(uint256 => Candidate) public candidates;
    // Store Candidates count
    uint256 public candidatesCount;
    // voted event
    event votedEvent(uint256 indexed _candidateId);
    constructor() public {
        addCandidate("trong");
        addCandidate("sang");
        addCandidate("phuc");
    }
    function hasTheVoterVoted() public view returns (uint8){
        bool rt =  voters[msg.sender];
        if (rt == true) {
            return 1;
        }
        else {
            return 0;
        }
    }
    function addCandidate(string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }
    function vote(uint256 _candidateId) public {
        // require that they haven't voted before
        require(!voters[msg.sender]);
        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);
        // record that voter has voted
        voters[msg.sender] = true;
        // update candidate vote Count
        candidates[_candidateId].voteCount++;
        // trigger voted event
        emit votedEvent(_candidateId);
    }
    function getCandidateName(uint8 _id) view  public returns( string memory ){
        // here i need to create thecode of the verify 
        return candidates[_id].name;
}}