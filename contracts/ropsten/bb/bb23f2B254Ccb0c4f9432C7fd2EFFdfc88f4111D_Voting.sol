///SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

/* import contrat ownable*/
import "./Ownable.sol";

/**
 * @title Voting
   @author Sandy,Julien,Stéphane
   @notice Contrat de vote, getsion par un superadmin
 */

contract Voting is Ownable {
    uint8[] public winningProposalId;

    //increment d'ids
    uint8 public proposalIds;

    struct Voter {
        bool isRegistered;
        address _address;
        bool hasVoted;
        //à voir l'utilité :
        uint256 votedProposalId;
    }

    struct Proposal {
        uint8 id;
        address owner;
        string description;
        uint256 voteCount;
    }

    mapping(address => Voter) public whiteList;

    mapping(uint256 => Proposal) public proposals;

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
    event ProposalRegistered(uint256 proposalId);
    event VotingSessionStarted();
    event VotingSessionEnded();
    event Voted(address voter, uint256 proposalId);
    event VotesTallied(uint8[] _winningProposals);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );

    constructor() {
        emit NewVotingSystem();
    }

    function getWinningProposal() public view returns (Proposal memory proposal){
      //a voir en cas de plusieurs gagnnats boucle ->
        return proposals[winningProposalId[0]];
    }

    ///@param _address à ajouter à la whitelist
    function addVoter(address _address) public onlyOwner {
        require(status == WorkflowStatus.RegisteringVoters);
        Voter memory newVoter = Voter(true, _address, false, 0);
        whiteList[_address] = newVoter;
        emit VoterRegistered(_address);
    }

    function deleteVoter(address _address) public onlyOwner {
        delete whiteList[_address];
    }

    function startProposalRegistration() public onlyOwner   {
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

    ///@dev Verification de la présence de l'address dans la whitelist
    modifier whiteListed() {
        require(whiteList[msg.sender].isRegistered == true);
        _;
    }

    ///@param _description est le nom de la proposition
    function addProposal(string memory _description) public whiteListed {
        //obligation d'être dans le workflow correspondant
        //deux propositions identiques sont possibles à voir...
        require(status == WorkflowStatus.ProposalsRegistrationStarted, "Proposals session has not started");
        Proposal memory newProposal =
        Proposal(proposalIds, msg.sender, _description, 0);
        proposals[proposalIds] = newProposal;
        proposalIds++;
        emit ProposalRegistered(proposalIds);
    }

    function deleteProposal(uint256 _id) public whiteListed {
        require(proposals[_id].owner == msg.sender);
        delete proposals[_id];
    }
    //a voir si on fait function delete proposal aussi pour l'admin
    function deleteProposalAdmin(uint256 _id) public onlyOwner {
        delete proposals[_id];
    }

    function vote(uint256 _id) public whiteListed {
        require(status == WorkflowStatus.VotingSessionStarted);
        require(whiteList[msg.sender].hasVoted == false);
        whiteList[msg.sender].hasVoted = true;
        proposals[_id].voteCount++;
        emit Voted(msg.sender, _id);
    }

    function count() public onlyOwner {
        require(status == WorkflowStatus.VotingSessionEnded);
        uint8 id;
        uint256 highestCount;
        uint8[] storage winners;

        for (uint256 i = 0; i <= proposalIds; i++) {
            if (highestCount < proposals[i].voteCount) {
                highestCount = proposals[i].voteCount;
                id = proposals[i].id;

                // new solution with array
                if (winners.length >= 1) {
                    winners.pop();
                }
                winners.push(proposals[i].id);
                ///@dev à voir les cas particuliers où plusieurs gagnants
            } else if (highestCount == proposals[i].voteCount){
                winners.push(proposals[i].id);
            }
        winningProposalId = winners;

        status = WorkflowStatus.VotesTallied;
        emit VotesTallied(winningProposalId);   
  }
    }
    ///@return le statut en cours du vote
    function getEnum() public view returns(WorkflowStatus) {}
}