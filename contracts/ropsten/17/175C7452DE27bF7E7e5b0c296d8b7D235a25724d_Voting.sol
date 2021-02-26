// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.11;
pragma experimental ABIEncoderV2;

/* import contrat ownable*/
import "./Ownable.sol";

/**
 * @title Voting
   @author Sandy,Julien,Stéphane
   @notice Contrat de vote, getsion par un superadmin
 */
 
 contract Voting is Ownable{
  
  uint8 public winningProposalId;
  
  uint8 proposalIds;
  
  struct Voter {
    bool isRegistered;
    address _address;
    bool hasVoted;
    uint votedProposalId;
  }

  struct Proposal {
    uint8 id;
    address owner;
    string description;
    uint voteCount;
  }

  mapping(address => Voter) public voters; // liste électorale
  mapping(address => Voter) public whiteList;
  mapping(uint => Proposal) public proposals;
    
  enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    
    WorkflowStatus public status;
    
    
    
    ///@notice Events
    event NewVotingSystem();
    event VoterRegistered(address voterAddress);
    event ProposalsRegistrationStarted();
    event ProposalsRegistrationEnded();
    event ProposalRegistered(uint proposalId);
    event VotingSessionStarted();
    event VotingSessionEnded();
    event Voted (address voter, uint proposalId);
    event VotesTallied();
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus
    newStatus);
    
    constructor() public{
      emit NewVotingSystem();
    }
    
    ///@param _address à ajouter à la whitelist
    function addVoter(address _address) public onlyOwner {
      require(status == WorkflowStatus.RegisteringVoters);
      Voter memory newVoter = Voter(true, _address, false, 0);
      whiteList[_address] = newVoter;
      emit VoterRegistered(_address);
    }

    ///@dev verifier le gas
    function deleteVoter(address _address) public onlyOwner {
      delete whiteList[_address];
    }
    
    function startSession() public onlyOwner {
      status = WorkflowStatus.ProposalsRegistrationStarted;
      emit ProposalsRegistrationStarted();
    }

    ///TODO end ProposalsRegistration Session

    // start Voting Session

    // end Voting Session

  ///@dev Verification de la presence de l'address dans la whitelist
    modifier whiteListed() {
      require(whiteList[msg.sender].isRegistered == true);
      _;
    }

    function addProposal(string memory _description) public whiteListed {
      require(status == WorkflowStatus.ProposalsRegistrationStarted);
      Proposal memory newProposal = Proposal(proposalIds, msg.sender, _description, 0);
      proposals[proposalIds] = newProposal;
      emit ProposalRegistered(proposalIds);
      proposalIds++;
    }


    ///@return le statut en cours du vote
    function getEnum() public view returns(WorkflowStatus){}
 }