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
    
    function getWinningProposal() public view returns(Proposal memory proposal) {
        return proposals[winningProposalId];
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
    
    function startProposalRegistration() public onlyOwner {
      status = WorkflowStatus.ProposalsRegistrationStarted;
      emit ProposalsRegistrationStarted();
    }

    function endProposalRegistration() public onlyOwner {
      status = WorkflowStatus.ProposalsRegistrationEnded;
      emit ProposalsRegistrationEnded();
    }

    function startVotingSession() public onlyOwner {
      status = WorkflowStatus.VotingSessionStarted;
      emit VotingSessionStarted();
    }

    function endVotingSession() public onlyOwner {
      status = WorkflowStatus.VotingSessionEnded;
      emit VotingSessionEnded();
    }
   
   

  ///@dev Verification de la presence de l'address dans la whitelist
    modifier whiteListed() {
      require(whiteList[msg.sender].isRegistered == true);
      _;
    }

    ///@param _description est le nom de la proposition
    function addProposal(string memory _description) public whiteListed {
      //obligation d'être dans le workflow correspondant 
      require(status == WorkflowStatus.ProposalsRegistrationStarted);
      Proposal memory newProposal = Proposal(proposalIds, msg.sender, _description, 0);
      proposals[proposalIds] = newProposal;
      emit ProposalRegistered(proposalIds);
      proposalIds++;
    }

    function deleteProposal(uint _id) public whiteListed {
      require(proposals[_id].owner == msg.sender);
      delete proposals[_id];
    }

    function vote(uint _id) public whiteListed {
      require(status == WorkflowStatus.VotingSessionStarted);
      require(whiteList[msg.sender].hasVoted == false);
      whiteList[msg.sender].hasVoted = true;
      proposals[_id].voteCount++;
      emit Voted(msg.sender, _id);
    }

    function count() public onlyOwner {
        require(status == WorkflowStatus.VotingSessionEnded);
        uint8 id;
        uint highestCount;

        for (uint i = 0; i < proposalIds; i++) {
          if (highestCount < proposals[i].voteCount) {
             id = proposals[i].id;
          }
          ///@dev à voir les cas particuliers où plusieurs gagnants
        }
        winningProposalId = id; 
        emit VotesTallied();
        status = WorkflowStatus.VotesTallied;
    }


    ///@return le statut en cours du vote
    function getEnum() public view returns(WorkflowStatus){}
 }