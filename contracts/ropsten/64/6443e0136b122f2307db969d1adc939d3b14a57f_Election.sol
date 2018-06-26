pragma solidity ^0.4.18;

contract Election{
    
    struct Vote {
        uint voteNumber; 
        uint candidateNumber;
        uint socialNumber; 
    }
    
    struct Candidate {
        uint candidateNumber; 
        string candidateName;
        string candidatePledge; 
    }
    
    uint[] public voteNumberList;
    uint[] public candidateNumberList;

    mapping (uint => Vote) voteList;
    mapping (uint => Candidate) candidateList;
    
    function Election() public{
        
        setCandidate(0,&quot;Kim&quot;,&quot;Keep The Rule!&quot;);
        setCandidate(1,&quot;Lee&quot;,&quot;Be Free!&quot;);
        
        for (uint i=0; i< 50; i++) {
            uint8 randomNumber = random(i);
            if(randomNumber > 0){
                setVote(1, 1000 + i);
            }else
            {
                setVote(0, 1000 + i);
            }
        }
    }
    
    function setVote(uint _candidateNumber, uint _socialNumber) public {
        
        var vote = voteList[voteNumberList.length];
        
        vote.voteNumber = voteNumberList.length;
        vote.candidateNumber = _candidateNumber;
        vote.socialNumber = _socialNumber;
    
        voteNumberList.push(voteNumberList.length);
        candidateNumberList.push(_candidateNumber);
    }
    
    function getVote(uint _voteNumber) view public returns (uint, uint, uint) {
        return (voteList[_voteNumber].voteNumber, voteList[_voteNumber].candidateNumber, voteList[_voteNumber].socialNumber);
    }
    
    function getVoteNumberList() view public returns (uint[]) {
        return voteNumberList;
    }

    function setCandidate(uint _candidateNumber, string _candidateName, string _candidatePledge) public {
        
        var candidate = candidateList[_candidateNumber];
        
        candidate.candidateNumber = _candidateNumber;
        candidate.candidateName = _candidateName;
        candidate.candidatePledge = _candidatePledge;
    }
    
    function getCandidate(uint _candidateNumber) view public returns (uint, string, string) {
        return (candidateList[_candidateNumber].candidateNumber, candidateList[_candidateNumber].candidateName, candidateList[_candidateNumber].candidatePledge);
    }
    
    function getCandidateNumberList() view public returns (uint[]) {
        return candidateNumberList;
    }
    
    function random(uint salt) view returns (uint8) {
        return uint8(uint256(keccak256(salt)) % 2); // 0 ~ 1 (Only for testing.)
    }
}