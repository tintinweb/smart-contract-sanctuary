/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0 <0.8.7;

contract SimpleVoting {
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;  
        uint votedProposalId;   
    }
    
    struct Proposal {
        string description;   
        uint voteCount; 
    }
    
    enum WorkflowStatus {
        RegisteringVoters, 
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    
    WorkflowStatus public workflowStatus = WorkflowStatus.RegisteringVoters;
    address public administrator;
    mapping(address => Voter) public voters;
    Proposal[] public proposals;
    uint private winningProposalId;
    
    modifier onlyAdministrator() {
       require(msg.sender == administrator,
          "the caller of this function must be the administrator");
       _;
    }
    
    modifier onlyRegisteredVoter() {
        require(voters[msg.sender].isRegistered, 
           "the caller of this function must be a registered voter");
       _;
    }
    
    modifier onlyDuringVotersRegistration() {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 
           "this function can be called only before proposals registration has started");
       _;
    }
    
    modifier onlyDuringProposalsRegistration() {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 
           "this function can be called only during proposals registration");
       _;
    }
    
    modifier onlyAfterProposalsRegistration() {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded,  
           "this function can be called only after proposals registration has ended");
       _;
    }
    
    modifier onlyDuringVotingSession() {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 
           "this function can be called only during the voting session");
       _;
    }
    
    modifier onlyAfterVotingSession() {
        require(workflowStatus == WorkflowStatus.VotingSessionEnded,  
           "this function can be called only after the voting session has ended");
       _;
    }
    
    modifier onlyAfterVotesTallied() {
        require(workflowStatus == WorkflowStatus.VotesTallied,  
           "this function can be called only after votes have been tallied");
       _;
    }

    constructor() public {
        administrator = msg.sender;
    }
    
    function registerVoter(address _voterAddress) 
        public onlyAdministrator onlyDuringVotersRegistration {
        
        require(!voters[_voterAddress].isRegistered, "the voter is already registered");
        
        voters[_voterAddress].isRegistered = true;
        voters[_voterAddress].hasVoted = false;
        voters[_voterAddress].votedProposalId = 0;
    }
    
    function startProposalsRegistration() 
        public onlyAdministrator onlyDuringVotersRegistration {
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
    }
    
    function endProposalsRegistration() 
        public onlyAdministrator onlyDuringProposalsRegistration {
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
    }
    
    function registerProposal(string memory proposalDescription) 
        public onlyRegisteredVoter onlyDuringProposalsRegistration {
        proposals.push(Proposal({
            description: proposalDescription,
            voteCount: 0
        }));
    }
    
    function startVotingSession() 
        public onlyAdministrator onlyAfterProposalsRegistration {
        workflowStatus = WorkflowStatus.VotingSessionStarted;
    }
    
    function endVotingSession() 
        public onlyAdministrator onlyDuringVotingSession {
        workflowStatus = WorkflowStatus.VotingSessionEnded;
    }
    
    function vote(uint proposalId) onlyRegisteredVoter onlyDuringVotingSession public {
        require(!voters[msg.sender].hasVoted, "the caller has already voted");
        
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = proposalId;
        
        proposals[proposalId].voteCount += 1;
    }
    
    function tallyVotes() onlyAdministrator onlyAfterVotingSession public {
        uint winningVoteCount = 0;
        uint winningProposalIndex = 0;
        
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalIndex = i;
            }
        }
        
        winningProposalId = winningProposalIndex;
        workflowStatus = WorkflowStatus.VotesTallied;
    }
}