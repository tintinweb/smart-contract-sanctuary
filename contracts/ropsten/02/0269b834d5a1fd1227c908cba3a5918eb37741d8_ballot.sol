/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


 contract ballot {
    struct voter {
        uint weight;
        bool voted;
        uint proposalNumber;
    }
    
    struct proposal {
        string name;
        uint count;
    }
    
    mapping(address => voter) public voters;
    proposal[] public proposals;
    address public chairPerson;
   
    constructor (string[] memory names) {
        chairPerson = msg.sender;
        voters[chairPerson].weight = 1;
        for (uint i = 0; i < names.length; i++) {
            proposals.push(proposal({
                name: names[i],
                count: 0
            }));
        }
    }
    
    function giteRight(address person) public {
        require(msg.sender == chairPerson, 'u r good bad!');
        require(!voters[person].voted, 'voted!');
        require(voters[person].weight == 0);
        voters[person].weight =1;
    }
    
    function vote(uint proposalNumber) public {
        voter storage sender = voters[msg.sender];
        require(!sender.voted,'voted!');
        sender.voted = true;
        sender.proposalNumber = proposalNumber;
        proposals[proposalNumber].count += sender.weight;
    }
    
    function scan() public view returns (proposal[] memory) {
        return proposals;
    }
    
    function winningProposal() public  view returns (string memory winningProposalName){
         uint winningProposalNumber = 0;
         for(uint i = 1;i<proposals.length;i++) {
             if (proposals[i].count > proposals[winningProposalNumber].count) {
                 winningProposalNumber = i;
             }
         }
         winningProposalName = proposals[winningProposalNumber].name;
    }
    
}