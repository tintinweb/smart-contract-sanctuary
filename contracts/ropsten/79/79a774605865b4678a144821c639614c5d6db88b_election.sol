/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

pragma solidity ^0.6.6;
contract election{
    struct Candidate{
        uint id;
        string name;
        uint votecount;
        
    }
    mapping(uint=>Candidate) public candidates;
    uint public candidatecount;
    mapping(address=>bool) public voter;
    
    event eventVote(
        uint indexed _candidateid);
        
    constructor()public{
        addcandidate("N");
        addcandidate("R");
    }
    function addcandidate(string memory _name)private{
        candidatecount++;
        candidates[candidatecount]=Candidate(candidatecount,_name,0);
        
    }
    function vote(uint _candidateid)public{
        require(!voter[msg.sender]);
        require(_candidateid>0 && _candidateid<=candidatecount);
        
        voter[msg.sender]=true;
        candidates[_candidateid].votecount ++;
        
        emit eventVote(_candidateid);
    }
}