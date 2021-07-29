/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;
contract  infraDev {
    
    address public elector;
    mapping(address => voter) public voters;
    uint public endReg;
    constructor (){
        elector = msg.sender;
    }
    struct proposal{
        uint proposalID;
        string projectName;
        address proposer;
        uint budget;
        uint voteCount;
    }
    struct voter {
        bool voted;
        uint voteIndex;
        uint weight;
    }
    proposal[] public proposals;
    uint nextProposalID = 1;
    
    modifier onlyElector(){
        elector = msg.sender;
        _;
    }
    event winner(uint proposalID,string  projectName,address proposer,uint budget, uint voteCount);
    function proposalRegistry(string memory _projectName, address _proposer, uint _budget, uint _voteCount) public onlyElector {
        //endReg = block.timestamp + (duration * 1 minutes);
        proposals.push(proposal({proposalID : nextProposalID, projectName : _projectName, proposer : _proposer, budget : _budget, voteCount : _voteCount }));
        nextProposalID++;
    }
    function authorise(address _voter)public  {
        require(elector == msg.sender);
        require(!voters[_voter].voted); 
        voters[_voter].weight = 1; }
    function vote(uint voteIndex) public {
        //require(block.timestamp < endReg);
        require(!voters[msg.sender].voted);
        voters[msg.sender].voted = true;
        voters[msg.sender].voteIndex = voteIndex;
        proposals[voteIndex].voteCount += voters[msg.sender].weight;
    }
     function winningProposal() public view returns (uint winningProposalID)
    {
        uint winningVoteCount = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalID = i;
                return i;
            }
        }
    }
}