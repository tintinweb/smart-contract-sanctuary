/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.5;
pragma experimental ABIEncoderV2;
// specifies what version of compiler this code will be compiled with

contract SimpleVote {

    struct Voter {
        bool isRegistered;
        bool hasVoted;
    }
    
    struct Candidate {
        string candidateName;
        uint voteCount;
    }

    address public administrator;
    address[] public voters;
    mapping(address => Voter) public voter;
    Candidate[] public candidateList;

    /* Broadcast event when a user voted
    */
    event VoteReceived(address user, string candidate);

    modifier onlyAdministrator() {
       require(msg.sender == administrator,
          "caller is not the administrator");
       _;
    }

    modifier onlyRegisteredVoter() {
        require(voter[msg.sender].isRegistered,
           "caller is not a registered voter");
       _;
    }

    constructor() public {
        administrator = msg.sender;
    }

    function registerVoter() public {
        require(!voter[msg.sender].isRegistered, "the voter is already registered");

        voters.push(msg.sender);
        voter[msg.sender].isRegistered = true;
        voter[msg.sender].hasVoted = false;
    }

    function registerCandidate(string memory _candidateName) public onlyAdministrator {
        candidateList.push(Candidate({
            candidateName: _candidateName,
            voteCount: 0
        }));
    }

    function vote(uint candidateId) onlyRegisteredVoter public {
        require(!voter[msg.sender].hasVoted, "the caller has already voted");
        
        voter[msg.sender].hasVoted = true;
        
        candidateList[candidateId].voteCount += 1;

        // Broadcast voted event
        emit VoteReceived(msg.sender, candidateList[candidateId].candidateName);
    }

    function totalVotesFor(uint candidateId) public view returns(uint) {
        return candidateList[candidateId].voteCount;
    }

    function getCandidateName(uint candidateId) public view returns(string memory) {
        return candidateList[candidateId].candidateName;
    }

    function getVoters() public view returns(uint) {
        return voters.length;
    }

    function getCandidates() public view returns(uint) {
        return candidateList.length;
    }

    function getAdministrator() public view returns(address) {
        return administrator;
    }

}