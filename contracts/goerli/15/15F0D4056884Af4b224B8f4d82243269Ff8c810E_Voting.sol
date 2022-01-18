/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

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
        
    }
    struct Vote {
        uint8 proposalId;
        uint256 timestamp;
    }
    struct Proposal {
        string proposal;
        uint256 timestamp;
    }
    
    mapping(address => bool) voted;
    uint8 proposalId;
    mapping(uint8 => Proposal) public proposals;
    uint8[] proposalNos;
    string[] names;
    
    function addProposal (string memory _proposal) external  {
        proposalId++;
        proposals[proposalId] = Proposal(_proposal, block.timestamp);
        proposalNos.push(proposalId);
        names.push(_proposal);
    }
    function viewProposals() external view returns(uint8[] memory, string[] memory) {
        
        return (proposalNos,names);
    }

   // address[] voters;
    uint256 public voterCount;
    mapping(address => bool) isVoter;
    function addVoter(address _voter) external onlyOwner  {
     //   voters.push(_voter);
        isVoter[_voter] = true;
        voterCount++;
    }
    
    modifier checkIfValidVoter (address _voter) {
        require(isVoter[_voter], "Not a valid voter");
        _;
    }

    mapping(uint8 => uint256) public proposalVoteCount;
    //uint256[] public votecount;
    event VoteCast(address Voter, uint256 Time);

    function addVote(uint8 _proposalId) external  checkIfValidVoter(msg.sender) returns (bool) {    
        require(!voted[msg.sender], "This user has already Voted!");
        voted[msg.sender] = true;
        proposalVoteCount[_proposalId] ++;
        //votecount[_proposalId] = proposalVoteCount[_proposalId];
        emit VoteCast(msg.sender, block.timestamp);
        return true;
    }
    
    function getProposalVoteCount() external view returns(uint8[] memory, uint256[] memory ) {
        uint256[] memory votecount = new  uint256[](proposalId);
        for (uint8 i=0; i<proposalId; i++){
            votecount[i] = proposalVoteCount[i+1];
        }
        return (proposalNos, votecount);
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