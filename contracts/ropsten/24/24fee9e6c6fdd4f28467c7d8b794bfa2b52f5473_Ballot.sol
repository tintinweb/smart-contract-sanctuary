/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22;

contract Ballot{
    uint256[] proposals;
    mapping(address => bool) voters;
    uint256 public winningProposal;
    uint256 public winningProposalVotes;
    
    constructor(uint256 _proposalsCount) public{
        proposals.length = _proposalsCount;
    }
    
    function vote(uint256 _proposal) public {
        require(!voters[msg.sender], "already voted");
        require(_proposal < proposals.length, "invalid proposal index");
        voters[msg.sender] = true;
        proposals[_proposal]++;
        if (proposals[_proposal] > winningProposalVotes) {
            winningProposal = _proposal;
            winningProposalVotes = proposals[_proposal];
        }
    }
}