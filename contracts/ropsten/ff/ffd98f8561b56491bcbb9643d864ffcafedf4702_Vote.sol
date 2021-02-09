/**
 *Submitted for verification at Etherscan.io on 2021-02-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

contract Vote {
    
    struct Candidate {
        uint256 id;
        string name;
        uint256 votesCount;
        bool exists;
    }
    

    mapping(address => bool) voters;
    
    mapping(uint256 => Candidate) public candidates;
    uint256 public candidatesCount;
    
    event NewVote(address voter, string candidateName, uint256 candidateVotesCount);
    
    
    constructor() {
        createCandidate('HosseinNedaee');
        createCandidate('VahidRahimi');
    }
    
    function createCandidate(string memory _name) private {
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0, true);
        candidatesCount++;
    }
    
    function vote(uint256 _candidateId) public candidExists(_candidateId) justOnce {
        // increase candidate votes count
        Candidate storage candidate = candidates[_candidateId];
        candidate.votesCount++;
        
        // add voter to voters
        voters[msg.sender] = true;
        
        emit NewVote(msg.sender, candidate.name, candidate.votesCount);
    }
    
    function result() public view returns(uint256[] memory) {
        uint256[] memory ret = new uint256[](candidatesCount);
        for(uint256 i = 0; i < candidatesCount; i++) {
            ret[i] = candidates[i].votesCount;
        }
        return ret;
    }
    
    // function allVoters() public view returns(address[] memory) {
       
    // }
    
    modifier justOnce() {
        require(!voters[msg.sender],  "Already voted");
        _;
    }

    modifier candidExists(uint256 _candidateId) {
        require(_candidateId >= 0 && _candidateId < candidatesCount, "Not valid candidateId");
        require(candidates[_candidateId].exists, "Candidate not exists");
        _;
    }
}