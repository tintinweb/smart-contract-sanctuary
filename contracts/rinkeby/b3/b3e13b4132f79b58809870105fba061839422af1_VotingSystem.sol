/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract VotingSystem{
    
    
    struct Voter{
        
        bool alreadyVoted ;
        
        uint proposalIndex;
    }
    
    struct Proposal{
        
         string proposalName; 
        uint256 voteCount;
    }
    
    mapping(address => Voter) VoterAddress;
    
    Proposal[] private proposals;
    
        // input name of the proposal 
     function initialize(string memory name) public {
            
            proposals.push(Proposal(name,0));
     }
     
     // msg.sender can vote only once 
     // this function finds the proposal with the passed string in input 
     function voteTo(string memory _name) public {
         
         require(VoterAddress[msg.sender].alreadyVoted== false, "you have already voted");
         VoterAddress[msg.sender].alreadyVoted = true;
         for(uint i = 0;i<proposals.length;i++){
             
             if(keccak256(bytes(proposals[i].proposalName)) == keccak256(bytes(_name))){
                      VoterAddress[msg.sender].proposalIndex = i; 
                       proposals[i].voteCount++;
             }
         }
     }
     // this function returns who the winner is 
     function winner() view  public returns(string memory){
           
           uint max = 0;
           string memory winnerProposal;
           for(uint i = 0;i<proposals.length;i++){
               
               if(proposals[i].voteCount>max){
                   max  = proposals[i].voteCount;
                   winnerProposal = proposals[i].proposalName;
               }
           }
           return winnerProposal;
       }
   
    
    
}