/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0; 

contract VoteTimes {
    address owner;  // Election Commissioner
    bool isVoting;

    uint256 startTime;
    uint256 closeTime;
    uint256 voterRegistrationTime;
    uint256 candidateRegistrationTime;
    
    modifier voterRegistration {
        require ( voterRegistrationTime>block.timestamp, "Voter registration time over");
        _;
    }
    modifier candidateRegistration {
        require ( candidateRegistrationTime>block.timestamp, "Voter registration time over");
        _;
    }
    modifier votingTime {
        require (startTime<block.timestamp && closeTime>block.timestamp, "Not a valid time to vote");
        require(isVoting, "Voting not open");
        _;
    }
    modifier beforeVoteTime {
        require ( startTime>block.timestamp, "Voting time started");
        _;
    }
    modifier afterVoteTime {
        require(closeTime<block.timestamp, "Voting time hasn't finished");
        _;
    }
    modifier onlyOwner {
        require(msg.sender == owner, "Only chairperson can give right to vote.");
        _;
    }
    
    event startVoteEvent(address indexed admin, uint256 timestamp);
    event stopVoteEvent(address indexed admin, uint256 timestamp);

    
}

contract Voting is VoteTimes{
    
    constructor()  {
        isVoting = false;
        owner = msg.sender;
        startTime = block.timestamp;
        closeTime = block.timestamp+604800; // 1 week
        voterRegistrationTime = block.timestamp+604800;
        candidateRegistrationTime = block.timestamp+604800;

    }
    struct Vote {
        address candidate;
        uint256 timestamp;
    }
    
    mapping(address => Vote) votes;
    address[] voters;
    

    uint256 voterCount;
    function addVoter(address _voter) external voterRegistration onlyOwner {
        voters.push(_voter);
        voterCount++;
    }
    
    uint8 candidateId;
    mapping(uint8 => address) public candidatesId;
    
    function addCandidate (address _address) external candidateRegistration onlyOwner {
        candidatesId[candidateId] = _address ;
        candidateId ++;
    }
    mapping(address => uint256) public candidatevotecount;

    bool isVoter;
    modifier checkIfValidVoter (address _voter) {
        for (uint i=0; i<voters.length; i++) {
            if ( voters[i] == _voter) {
                isVoter = true;
            }
        }
        require(isVoter, "Not a valid registered voter");
        _;
    }
    
    function addVote(uint8 _candidateId) external votingTime checkIfValidVoter(msg.sender) returns (bool) {
        require(candidatesId[_candidateId] != address(0));
        require(votes[msg.sender].timestamp == 0, "This user has already Voted!");
        votes[msg.sender].candidate = candidatesId[_candidateId];
        votes[msg.sender].timestamp = block.timestamp;
        candidatevotecount[candidatesId[_candidateId]] ++;
        return true;
    }
    
    function getCandidateVoteCount() external view onlyOwner 
                returns(address[] memory , uint256[] memory ) {
        address[] memory addr;
        uint256[] memory votecount;
        for (uint8 i=0; i<=candidateId; i++){
            addr[addr.length] = candidatesId[i];
            votecount[votecount.length] = candidatevotecount[candidatesId[i]];
        }
        return (addr, votecount);
    }
    
    function startVote() external onlyOwner returns (bool) {
        isVoting = true;
        emit startVoteEvent(msg.sender, block.timestamp);
        return true;
    }
    
    function stopVote() external onlyOwner votingTime returns (bool) {
        isVoting = false;
        emit stopVoteEvent(msg.sender, block.timestamp);
        return true;
    }
    
}