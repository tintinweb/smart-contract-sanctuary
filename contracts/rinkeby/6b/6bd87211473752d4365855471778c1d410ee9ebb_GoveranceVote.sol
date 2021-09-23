/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/** 
 * @dev Implements voting process along with vote delegation
 */
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
        // check if voter is not the owner
        uint _id = lastVoteIndex;
        lastVoteIndex += 1;
        allVotes[_proposalId].push(Vote(_id, _proposalId, _response, _voter));
    }
    

    
    function getVote(uint index) public pure returns (Vote[] memory)  {
      Vote[] memory _votes = new Vote[](index);
      for (uint i = 0; i < index; i++) {
          Vote memory _vote = _votes[i];
          _votes[i] = _vote;
      }
      return _votes;
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