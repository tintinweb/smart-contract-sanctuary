/**
 *Submitted for verification at Etherscan.io on 2021-12-19
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
        voters = [0x4290aFEBb2A5C7B9645966BB659a79c32a663Ab6,0x36D2B93eD89e58Afc329c9010fD2482E31b55aeC,0xa805835611059306F293eF4CA05B41B1f0f61cAb,0xEe49F8E08893582edae8C3c1B1C72df7886fffc4];
        
        candidatesId[0] = 0xc6CD1952F4A14a343667F8BB2B4Eb10e2AA25158;
        candidatesId[1] = 0x0b08EF964994230005B4C8218Fb8125786E26F06;
        candidatesId[2] = 0x8Dbf9158d8B237E3D963B9Ac187Bf782271762Bf;
    }
    struct Vote {
        address candidate;
        uint256 timestamp;
    }
    
    mapping(address => Vote) votes;
    address[] voters;
    
    uint8 candidateId=3;
    mapping(uint8 => address) public candidatesId;
    
    function addCandidate (address _address) external  {
        candidatesId[candidateId] = _address ;
        candidateId ++;
    }

    uint256 voterCount;
    function addVoter(address _voter) external  {
        voters.push(_voter);
        voterCount++;
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
    
    event VoteCast(address Voter, uint256 Time);
    function addVote(uint8 _candidateId) external  checkIfValidVoter(msg.sender) returns (bool) {
        require(candidatesId[_candidateId] != address(0));
        require(votes[msg.sender].timestamp == 0, "This user has already Voted!");
        votes[msg.sender].candidate = candidatesId[_candidateId];
        votes[msg.sender].timestamp = block.timestamp;
        candidatevotecount[candidatesId[_candidateId]] ++;
        emit VoteCast(msg.sender, block.timestamp);
        return true;
    }
    
    function getCandidateVoteCount() external view  
                returns(address[] memory , uint256[] memory ) {
        address[] memory addr;
        uint256[] memory votecount;
        for (uint8 i=0; i<=candidateId; i++){
            addr[addr.length] = candidatesId[i];
            votecount[votecount.length] = candidatevotecount[candidatesId[i]];
        }
        return (addr, votecount);
    }
    
    function startVote() external  returns (bool) {
        isVoting = true;
        emit startVoteEvent(msg.sender, block.timestamp);
        return true;
    }
    
    function stopVote() external  returns (bool) {
        isVoting = false;
        emit stopVoteEvent(msg.sender, block.timestamp);
        return true;
    }
    
}