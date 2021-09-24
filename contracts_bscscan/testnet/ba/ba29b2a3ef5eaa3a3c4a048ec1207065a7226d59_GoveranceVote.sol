/**
 *Submitted for verification at BscScan.com on 2021-09-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract GoveranceVote {
    
    constructor() {
        contractOwner = msg.sender;
        lastProposalIndex = 0;
    }
    
    address public contractOwner;
    mapping(uint => Vote[]) allVotes;
    Proposal[] allProposals;
    uint lastProposalIndex;
    uint lastVoteIndex;
   
    
    struct Vote {
      uint voteId;
      uint proposalId;
      string response;
      address voter;
    }

    struct Proposal {
        uint id;
        string noteBody;
        address noteOwner;
        string mediaId;
        bool isEdited;
    }
    

    function castVote(uint _proposalId, string memory _response, address _voter) public {
        
        uint _id = lastVoteIndex;
        lastVoteIndex += 1;
        allVotes[_proposalId].push(Vote(_id, _proposalId, _response, _voter));
    }
    

    
    function getVote(uint index) public view returns (Vote[] memory)  {
      Vote[] memory _votes =  allVotes[index];
      return _votes;
    }
    
    function revokeVote(uint proposalId, uint voteId) public {
        delete allVotes[proposalId][voteId];
    }
  

    function createProposal(string memory _noteBody, address _noteOwner, string memory _mediaId) public {
        uint _id = lastProposalIndex;
        lastProposalIndex += 1;
        allProposals.push(Proposal(_id, _noteBody, _noteOwner, _mediaId, false));
    }
    
    function updateProposal(uint _id, string memory _noteBody, address _noteOwner, string memory _mediaId) public {
        allProposals[_id] = Proposal(_id, _noteBody, _noteOwner, _mediaId, true);
    }
    

}