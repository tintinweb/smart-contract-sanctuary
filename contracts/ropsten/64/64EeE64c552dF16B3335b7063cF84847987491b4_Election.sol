/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

pragma solidity ^0.8.7;

contract Election{
    
    struct Candidate{
        uint Id;
        string name;
        uint voteCount;
    }
    
    mapping(uint => Candidate) public candidates;
    uint public candidateCount;
    mapping(address => bool) public voter;
    
    event eventVote(uint indexed _candidateId);
    
    constructor() public{
        addCandidate("Vladimir Putin");
        addCandidate("Donald Trump");
    }
    
    function addCandidate(string memory _candidate) private{
        candidateCount++;
        candidates[candidateCount] = Candidate(candidateCount,_candidate,0);
    }
    function vote(uint _candidateId) public{
        require(!voter[msg.sender]);
        require(_candidateId > 0 && _candidateId <=candidateCount);
        
        voter[msg.sender] = true;
        candidates[_candidateId].voteCount++;
        
        emit eventVote(_candidateId);
        
    }
}