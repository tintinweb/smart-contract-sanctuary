/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Strawpoll{
    
    struct Poll{
        address master;
        string name;
        Proposal[] proposals;
    }
    
    struct Proposal{
        uint proposalID;
        bool enabled;
        string proposalName;
        uint voteCount;
        bool isWinner;
    }
    
    Poll poll;

    modifier onlyMaster(address _master){
        require(
            msg.sender == _master, "Not authorized."
        );
        _;
    }
    
    function CreatePoll(string memory _name) public
        returns (bool success_){
        poll.name = _name;
        poll.master = msg.sender;
        return true;
    }
    
    function AddProposal(string memory _proposalName) public onlyMaster(poll.master)
        returns (bool success_){
        poll.proposals.push(Proposal(
            poll.proposals.length + 1,
            true,
            _proposalName,
            0,
            false
            ));
        return true;
    }
    
    function RemoveProposal(uint _proposalID) public onlyMaster(poll.master)
        returns (bool success_){
        uint proposalIDFound = FindProposalByID(_proposalID);
        if(poll.proposals[proposalIDFound].enabled){
            poll.proposals[proposalIDFound].enabled = false;
            return true;
        }
        return false;
    }
    
    function GetPoll() public view
        returns (
            address pollMaster_,
            string memory pollName_,
            Proposal[] memory proposals_
            ){
        return (poll.master, poll.name, poll.proposals);
    }
    
    function Vote(uint _proposalID) public 
        returns (bool success_){
        if(!poll.proposals[FindProposalByID(_proposalID)].enabled){
            return false;
        }
        poll.proposals[FindProposalByID(_proposalID)].voteCount++;
        return true;
    }
    
    function declareWinner() public view
        returns (
            uint proposalID_,
            uint voteCount_
            ){
        return (FindProposalByHighestVoteCount());
               
    }
    
    function FindProposalByHighestVoteCount() private view
        returns (
            uint proposalID_,
            uint voteCount_
            ){
        uint bestVotecount = 0;
        uint bestProposal = 0;
        for(uint i = 0; i < poll.proposals.length; i++){
            if(poll.proposals[i].voteCount > bestVotecount){
                bestVotecount = poll.proposals[i].voteCount;
                bestProposal = poll.proposals[i].proposalID;
            }
        }
        return (bestProposal, bestVotecount);
    }
    
    function FindProposalByID(uint _proposalID) private view
        returns (uint ID_){
        bool isFound = false;
        uint IDFound = 0;
        for(uint i = 0; i < poll.proposals.length; i++){
            if(poll.proposals[i].proposalID == _proposalID){
                IDFound = i;
                isFound = true;
            }
        }     
        if(isFound == true){
            return IDFound;
        }
        else{
            revert("ID of the proposal not found.");
        }
    }
    
    
}