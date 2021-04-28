/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

pragma solidity 0.7.0;

pragma experimental ABIEncoderV2;

contract Voting {
    
    address public owner;
    
    bool public votingStatus;
    
    event VoterAdded(
        string aadhaarNumber,
        string fullName,
        uint age,
        string partyName,
        bool registered
        );
    
    event CandidateAdded(
        string aadhaarNumber,
        string fullName,
        uint age,
        string partyName,
        bool registered
        );
        
    event ElectionStarted(uint timestamp);
    
    event VoterRegistered(string aadhaar, string fullName, uint age);
    
    event CandidateRegistered(string aadhaar, string fullName, uint age, string partyName);
    
    event VoterNotFound(address voter, string aadhaar);
    
    event ElectionEnded(uint timestamp, string winnerName, string winnerParty, uint winnerAge, uint winnerVoteCount);
    
    Candidate lastWinner;
    
    event VoteProcessed(
        string aadhaarVoter,
        string aadhaarCandidate
        );
    
    struct Voter {
        string aadhaarNumber;
        string fullName;
        uint age;
        bool registered;
        bool voted;
    }
    
    struct Candidate {
        string aadhaarNumber;
        string fullName;
        uint age;
        string partyName;
        bool registered;
        uint voteCount;
    }
    
    mapping (address=>Voter) voterList;
    
    mapping (string=>Candidate) candidateList;
    
    string[] candidateLedger;
    
    mapping (string=>uint) candidateVotes;
    
    constructor(){
        owner = msg.sender;
        votingStatus = true;
    }
    
    modifier onlyOwner(){
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function registerVoter(string memory _aadhaar, string memory _name, uint _age) public {
        require(!voterList[msg.sender].registered, "Voter previously registered");
        require(_age>=18, "Voter age cannot be less than 18 years");
        voterList[msg.sender] = Voter(_aadhaar, _name, _age, true, false);
        emit VoterRegistered(_aadhaar, _name, _age);
    }
    
    function getVoterDetails(string memory _aadhaar) public returns (bool){
        require(voterList[msg.sender].registered, "Voter not registered");
        if(voterList[msg.sender].registered){
            if(keccak256(abi.encodePacked(voterList[msg.sender].aadhaarNumber)) == keccak256(abi.encodePacked(_aadhaar))) {
                emit VoterRegistered(_aadhaar, voterList[msg.sender].fullName, voterList[msg.sender].age);
                return true;
            }
        }
        emit VoterNotFound(msg.sender, _aadhaar);
        return false;
    }
    
    function registerCandidate(string memory _aadhaar, string memory _name, uint _age, string memory _partyName) public onlyOwner {
        require(!candidateList[_aadhaar].registered, "Candidate already in the list");
        require(votingStatus, "No active elections");
        require(_age>=35, "Canidate age should be less than 35 years");
        require(candidateLedger.length < 5, "No more than 4 candidates allowed for election");
        Candidate memory newCandidate = Candidate(_aadhaar, _name, _age, _partyName, true, 0);
        candidateList[_aadhaar] = newCandidate;
        candidateLedger.push(_aadhaar);
        emit CandidateRegistered(_aadhaar, _name, _age, _partyName);
    }
    
    function voteForCandidate(string memory _aadhaarVoter, string memory _aadhaarCandidate) public {
        require(votingStatus, "No active elections");
        require(voterList[msg.sender].registered, "Voter not registered");
        require(!voterList[msg.sender].voted, "Voter already voted");
        require(candidateList[_aadhaarCandidate].registered);
        uint currentVoteCount = candidateList[_aadhaarCandidate].voteCount;
        candidateList[_aadhaarCandidate].voteCount = currentVoteCount + 1;
        voterList[msg.sender].voted = true;
        emit VoteProcessed(_aadhaarVoter, _aadhaarCandidate);
    }
    
    function toggleElectionStatus() onlyOwner public {
        if(!votingStatus){
            votingStatus = true;
            emit ElectionStarted(block.timestamp);
        }
        else{
            votingStatus = false;
            lastWinner = findWinner();
            for(uint i = 0; i<candidateLedger.length; i++ ){
                delete candidateList[candidateLedger[i]];
                delete candidateLedger;
            }
            emit ElectionEnded(block.timestamp, lastWinner.fullName, lastWinner.partyName, lastWinner.age, lastWinner.voteCount);
        }
    }
    
    function findWinner() internal view returns (Candidate memory){
        uint winner = 0;
        for (uint i = 1; i < candidateLedger.length; i++){
            if(candidateVotes[candidateLedger[i]] > candidateVotes[candidateLedger[winner]]){
                winner = i;
            }
        }
        return candidateList[candidateLedger[winner]];
    }
    
    function showLastWinner() public view returns (Candidate memory){
        require(lastWinner.registered, "First election on system still ongoing");
        return lastWinner;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    
    function getCandidateList() public view returns (string[] memory){
        require(votingStatus, "No active election");
        return candidateLedger;
    }
    
    function getElectionStatus() public view returns (bool) {
        return votingStatus;
    }
    
}