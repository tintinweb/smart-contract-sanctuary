/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

contract Voting {
    
    event ProposalVoted(uint proposalIndex, string proposalName, uint voteCount);
    
    struct Voter {
        string name;
        bool hasVoted;
    }
    
    struct Proposal {
        string name;
        uint voteCount;
    }
    
    modifier isOwner(string memory errorMessage) {
        require(msg.sender == owner, errorMessage);
        _;
    }
    
    mapping(address => Voter) public voters;
    
    Proposal[] public proposals;
    
    address private owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function giveVoterRights(address voter, string memory voterName) public isOwner("Only the owner can give voter rights") {
        voters[voter] = Voter(voterName, false);
    }
    
    function vote(uint8 proposalIndex) public {
        Voter memory voter = voters[msg.sender];
        require(!voter.hasVoted, "Voter has already voted");
        
        Proposal memory proposal = proposals[proposalIndex];
        proposal.voteCount += 1;
        proposals[proposalIndex] = proposal;
        
        voter.hasVoted = true;
        voters[msg.sender] = voter;
        
        emit ProposalVoted(proposalIndex, proposal.name, proposal.voteCount);
    }
    
    function addProposal(string memory proposalName) public returns (uint) {
        Proposal memory proposal = Proposal(proposalName, 0);
        proposals.push(proposal);
        
        return proposals.length - 1;
    }
}