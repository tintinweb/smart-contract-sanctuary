/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

pragma solidity ^0.6.6;

contract ImmoVotes{
    
    struct Candidate{
        uint id;
        string name;
        uint voteCount;
    }
    
    mapping (uint => Candidate) public candidates;
    uint public candidatecount;
    mapping(address => bool) public voter;
    
    event eventVote(
        uint indexed _candidateid
        );
    
    constructor ()public{
        addCandidate("Haus1");
        addCandidate("Haus2");
    }
    
    function addCandidate(string memory _name)private{
        candidatecount++;
        candidates[candidatecount]= Candidate(candidatecount, _name, 0);
    }
    
    function vore(uint _candidateid)public{
        require(!voter[msg.sender]);
        require(_candidateid > 0 && _candidateid <= candidatecount);
        
        voter[msg.sender] = true;
        candidates[_candidateid].voteCount ++;
        
        emit eventVote(_candidateid);
        
    }
}