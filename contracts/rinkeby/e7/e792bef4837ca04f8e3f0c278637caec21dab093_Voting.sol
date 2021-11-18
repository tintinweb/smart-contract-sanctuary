/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Voting {
    
    //store, fetch candidate's vote count
    mapping(address => uint256) public candidatesVoteCount;

    //list of candidates
    address[] public listOfCandidates;
    
    // list of winners
    address[] internal winners;

    //store, fetch candidate
    mapping(address => bool) public candidateRegistered;
    
    // Store candidates count
    uint public candidatesCount;
    
    // Check if candidate voted and for which candidate
    mapping(address => address) public alreadyVoted;

    //voted event
    event votedEvent (
        address voter,
        address candidate
    );

    event Winners(address[] allWinners, uint256 votes);

    function register() public{
        require(candidateRegistered[msg.sender] != true, "Candidate already registered");
        require(alreadyVoted[msg.sender] == address(0x0), "You are a voter, cannot be a candidate");
        candidateRegistered[msg.sender] = true;
        candidatesVoteCount[msg.sender] = 0;
        listOfCandidates.push(msg.sender);
        candidatesCount += 1;
    }
    
    function castVote(address contestant) public {
        require(candidateRegistered[contestant] == true, "Candidate not available");
        require(candidateRegistered[msg.sender] != true, "Candidate cannot vote other candidate");
        require(alreadyVoted[msg.sender] == address(0x0), "You cannot put multiple votes");
        
        alreadyVoted[msg.sender] = contestant;
        candidatesVoteCount[contestant] += 1;
        
        emit votedEvent(msg.sender, contestant);
    }
    
    function winner() public returns(address[] memory) {
        uint256 winnerCandidateVotecount = 0;
        winners = [address(0x0)];
        for(uint i=0; i<candidatesCount; i++){
            if(candidatesVoteCount[listOfCandidates[i]] > 0) {
                if(candidatesVoteCount[listOfCandidates[i]] >= winnerCandidateVotecount){
                    winnerCandidateVotecount = candidatesVoteCount[listOfCandidates[i]];
                    winners.push(listOfCandidates[i]);
                }
            }
        }
        emit Winners(winners, winnerCandidateVotecount);
        return winners;
    }
    
    function removeVote() public {
        require(alreadyVoted[msg.sender] != address(0x0), "You have not casted any vote");
        
        candidatesVoteCount[alreadyVoted[msg.sender]] -= 1;
        alreadyVoted[msg.sender] = address(0x0);
    }
    
}